#!/usr/bin/env bash
# ============================================================
# AI 老年健康守护系统 - 前端一键部署脚本 (Linux/macOS)
#
# 用法:
#   bash deploy.sh                           # 交互式部署
#   bash deploy.sh --mode docker --port 3000 # Docker 部署
#   bash deploy.sh --mode preview            # 快速预览
#   bash deploy.sh --mode fullstack          # 全栈集成
#   bash deploy.sh --build-only              # 仅构建
#   bash deploy.sh --skip-build              # 跳过构建
#
# 版本: 1.0.0
# 日期: 2026-06-24
# ============================================================

set -euo pipefail

# ---- 脚本配置 ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DIST_DIR="$PROJECT_DIR/dist"
DEPLOY_DIR="${DEPLOY_DIR:-/var/www/elderly-admin}"

# 默认参数
MODE=""
PORT=3000
BACKEND_URL="http://localhost:80"
BUILD_ONLY=false
SKIP_BUILD=false
NO_COLOR=false

# ---- 颜色定义 ----
if [ -t 1 ] && [ "$NO_COLOR" = false ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    GRAY='\033[0;90m'
    NC='\033[0m' # No Color
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; GRAY=''; NC=''
fi

# ---- 辅助函数 ----
print_step() { echo -e "\n${CYAN}[$1]${NC} $2"; }
print_success() { echo -e "  ${GREEN}[OK]${NC} $1"; }
print_warning() { echo -e "  ${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "  ${RED}[X]${NC} $1"; }
print_info() { echo -e "  ${GRAY}[i]${NC} $1"; }

# ---- 参数解析 ----
while [[ $# -gt 0 ]]; do
    case $1 in
        --mode)
            MODE="$2"; shift 2 ;;
        --port)
            PORT="$2"; shift 2 ;;
        --backend)
            BACKEND_URL="$2"; shift 2 ;;
        --build-only)
            BUILD_ONLY=true; shift ;;
        --skip-build)
            SKIP_BUILD=true; shift ;;
        --no-color)
            NO_COLOR=true; shift ;;
        --help|-h)
            echo "用法: bash deploy.sh [选项]"
            echo ""
            echo "选项:"
            echo "  --mode MODE      部署模式: preview|docker|nginx|fullstack"
            echo "  --port PORT      Web 端口 (默认: 3000)"
            echo "  --backend URL    后端 API 地址 (默认: http://localhost:80)"
            echo "  --build-only     仅构建，不部署"
            echo "  --skip-build     跳过构建"
            echo "  --no-color       禁用彩色输出"
            echo "  --help, -h       显示此帮助"
            exit 0
            ;;
        *)
            echo "未知参数: $1"; exit 1 ;;
    esac
done

# ============================================================
# 1. 欢迎信息
# ============================================================
clear 2>/dev/null || true
echo -e "${CYAN}============================================================${NC}"
echo -e "   ${GREEN}AI 老年健康守护系统${NC} - 前端一键部署脚本"
echo -e "   版本: 1.0.0 | Linux/macOS"
echo -e "${CYAN}============================================================${NC}"
print_info "项目目录: $PROJECT_DIR"
print_info "构建输出: $DIST_DIR"

# ============================================================
# 2. 环境检查
# ============================================================
print_step "1/5" "环境检查..."

# 检查 Node.js
if command -v node &>/dev/null; then
    NODE_VERSION=$(node --version)
    print_success "Node.js $NODE_VERSION"
else
    print_error "Node.js 未安装"
    echo "  请安装 Node.js 18+:"
    echo "    Ubuntu/Debian: curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && sudo apt install -y nodejs"
    echo "    CentOS/RHEL:   curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash - && sudo yum install -y nodejs"
    echo "    nvm:           nvm install 22 && nvm use 22"
    exit 1
fi

# 检查 npm
if command -v npm &>/dev/null; then
    NPM_VERSION=$(npm --version)
    print_success "npm $NPM_VERSION"
else
    print_error "npm 不可用"
    exit 1
fi

# 检查项目文件
if [ ! -f "$PROJECT_DIR/package.json" ]; then
    print_error "未找到 package.json，请确认在项目根目录"
    exit 1
fi
print_success "项目文件完整"

# ============================================================
# 3. 选择部署模式
# ============================================================
if [ -z "$MODE" ]; then
    print_step "2/5" "选择部署模式..."
    echo ""
    echo "  请选择部署模式:"
    echo "    [1] preview   - Vite 预览模式 (快速测试)"
    echo "    [2] docker    - Docker 容器部署 (推荐)"
    echo "    [3] nginx     - 本地 Nginx 静态部署"
    echo "    [4] fullstack - Docker Compose 全栈集成"
    echo ""

    read -r -p "  请输入序号 (1-4，默认 2): " CHOICE
    CHOICE=${CHOICE:-2}

    case $CHOICE in
        1) MODE="preview" ;;
        3) MODE="nginx" ;;
        4) MODE="fullstack" ;;
        *) MODE="docker" ;;
    esac
fi
print_success "部署模式: $MODE"

# ============================================================
# 4. 安装依赖 & 构建
# ============================================================
if [ "$SKIP_BUILD" = false ]; then
    print_step "3/5" "安装依赖..."

    if [ -d "$PROJECT_DIR/node_modules" ]; then
        print_info "node_modules 已存在，跳过安装"
        print_info "如需重新安装: rm -rf node_modules && npm install"
    else
        print_info "正在安装依赖 (可能需要几分钟)..."
        cd "$PROJECT_DIR"
        npm install --legacy-peer-deps || {
            print_error "npm install 失败"
            exit 1
        }
        print_success "依赖安装完成"
    fi

    print_step "4/5" "构建生产版本..."
    print_info "VITE_API_BASE_URL=$BACKEND_URL/api/v1"
    print_info "VITE_WS_URL=ws://${BACKEND_URL#http://}/ws"

    cd "$PROJECT_DIR"
    VITE_API_BASE_URL="$BACKEND_URL/api/v1" \
    VITE_WS_URL="ws://${BACKEND_URL#http://}/ws" \
    npm run build || {
        print_error "构建失败"
        exit 1
    }
    print_success "构建成功 → $DIST_DIR"

    # 构建统计
    if [ -d "$DIST_DIR" ]; then
        TOTAL_SIZE=$(du -sh "$DIST_DIR" 2>/dev/null | cut -f1)
        print_info "构建产物大小: $TOTAL_SIZE"
    fi

    if [ "$BUILD_ONLY" = true ]; then
        print_success "构建完成（--build-only 模式）"
        echo ""
        echo "构建产物位于: $DIST_DIR"
        exit 0
    fi
else
    print_info "跳过构建 (--skip-build)"
    if [ ! -d "$DIST_DIR" ]; then
        print_error "未找到构建产物: $DIST_DIR"
        exit 1
    fi
fi

# ============================================================
# 5. 部署
# ============================================================
print_step "5/5" "开始部署 (模式: $MODE)..."

case $MODE in
    preview)
        # ---- Vite 预览 ----
        print_info "启动 Vite 预览服务器..."
        print_info "访问地址: http://localhost:$PORT"
        print_info "按 Ctrl+C 停止"
        cd "$PROJECT_DIR"
        npx vite preview --port "$PORT" --host
        ;;

    docker)
        # ---- Docker 部署 ----
        print_info "检查 Docker 环境..."

        if ! command -v docker &>/dev/null; then
            print_error "Docker 未安装"
            echo "  请安装 Docker:"
            echo "    curl -fsSL https://get.docker.com | sudo bash"
            echo "    sudo usermod -aG docker \$USER  # 免 sudo 运行"
            exit 1
        fi
        print_success "Docker 可用"

        # 检查 Docker 守护进程
        if ! docker info &>/dev/null; then
            print_error "Docker 守护进程未运行"
            echo "  请启动 Docker: sudo systemctl start docker"
            exit 1
        fi

        # 清理旧容器
        if docker ps -a --format '{{.Names}}' | grep -q '^ehc-web-admin$'; then
            print_info "停止并删除旧容器..."
            docker stop ehc-web-admin 2>/dev/null || true
            docker rm ehc-web-admin 2>/dev/null || true
        fi

        # 构建镜像
        print_info "构建 Docker 镜像..."
        cd "$PROJECT_DIR"
        docker build \
            --build-arg "VITE_API_BASE_URL=$BACKEND_URL/api/v1" \
            --build-arg "VITE_WS_URL=ws://${BACKEND_URL#http://}/ws" \
            -t elderly-admin-web:latest \
            -f deploy/Dockerfile . || {
            print_error "镜像构建失败"
            exit 1
        }
        print_success "镜像构建完成"

        # 启动容器
        print_info "启动容器 (端口: $PORT)..."
        docker run -d \
            --name ehc-web-admin \
            -p "${PORT}:80" \
            --restart always \
            elderly-admin-web:latest || {
            print_error "容器启动失败"
            exit 1
        }
        print_success "容器启动成功!"

        # 等待就绪
        print_info "等待服务就绪..."
        sleep 5

        # 验证
        if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PORT" | grep -q 200; then
            print_success "服务验证通过 (HTTP 200)"
        else
            print_warning "服务可能尚未就绪，请稍后手动验证"
        fi
        ;;

    nginx)
        # ---- Nginx 静态部署 ----
        print_info "检查 Nginx 环境..."

        if ! command -v nginx &>/dev/null; then
            print_error "Nginx 未安装"
            echo "  请安装 Nginx:"
            echo "    Ubuntu/Debian: sudo apt install -y nginx"
            echo "    CentOS/RHEL:   sudo yum install -y nginx"
            exit 1
        fi
        print_success "Nginx 可用"

        # 询问部署路径
        read -r -p "  请输入部署目录 (默认: $DEPLOY_DIR): " USER_DIR
        DEPLOY_DIR="${USER_DIR:-$DEPLOY_DIR}"

        # 创建并复制文件
        print_info "复制构建产物到 $DEPLOY_DIR ..."
        sudo mkdir -p "$DEPLOY_DIR"
        sudo cp -r "$DIST_DIR"/* "$DEPLOY_DIR/"
        sudo chown -R www-data:www-data "$DEPLOY_DIR" 2>/dev/null || \
            sudo chown -R nginx:nginx "$DEPLOY_DIR" 2>/dev/null || true
        print_success "文件复制完成"

        # 复制 Nginx 配置
        NGINX_CONF_SRC="$SCRIPT_DIR/nginx.conf"

        # 检测 Nginx 配置目录
        if [ -d /etc/nginx/sites-available ]; then
            # Debian/Ubuntu 风格
            NGINX_CONF_DST="/etc/nginx/sites-available/elderly-admin"
            sudo cp "$NGINX_CONF_SRC" "$NGINX_CONF_DST"

            # 创建软链接
            if [ ! -L "/etc/nginx/sites-enabled/elderly-admin" ]; then
                sudo ln -sf "$NGINX_CONF_DST" "/etc/nginx/sites-enabled/elderly-admin"
            fi

            # 替换 root 路径
            sudo sed -i "s|root   /usr/share/nginx/html;|root   $DEPLOY_DIR;|g" "$NGINX_CONF_DST"
        elif [ -d /etc/nginx/conf.d ]; then
            # CentOS/RHEL 风格
            NGINX_CONF_DST="/etc/nginx/conf.d/elderly-admin.conf"
            sudo cp "$NGINX_CONF_SRC" "$NGINX_CONF_DST"
            sudo sed -i "s|root   /usr/share/nginx/html;|root   $DEPLOY_DIR;|g" "$NGINX_CONF_DST"
        else
            print_warning "未找到标准 Nginx 配置目录"
            print_info "请手动将 $NGINX_CONF_SRC 复制到 Nginx 配置目录"
        fi
        print_success "Nginx 配置已复制"

        # 测试并重载
        print_info "测试 Nginx 配置..."
        if sudo nginx -t 2>&1; then
            sudo nginx -s reload 2>/dev/null || sudo systemctl reload nginx
            print_success "Nginx 已重载"
        else
            print_error "Nginx 配置测试失败，请手动检查"
        fi
        ;;

    fullstack)
        # ---- Docker Compose 全栈集成 ----
        print_info "检查 Docker Compose 环境..."

        # 检测 compose 命令
        if docker compose version &>/dev/null 2>&1; then
            COMPOSE_CMD="docker compose"
            print_success "Docker Compose (v2) 可用"
        elif command -v docker-compose &>/dev/null; then
            COMPOSE_CMD="docker-compose"
            print_success "Docker Compose (v1) 可用"
        else
            print_error "Docker Compose 未安装"
            echo "  请安装 Docker Compose:"
            echo "    sudo apt install -y docker-compose-plugin  (推荐 v2)"
            echo "    或: sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose"
            exit 1
        fi

        # 检查 compose 文件
        BACKEND_COMPOSE="$PROJECT_DIR/../backend/deploy/docker-compose.yml"
        FRONTEND_COMPOSE="$SCRIPT_DIR/docker-compose.fullstack.yml"

        if [ ! -f "$BACKEND_COMPOSE" ]; then
            print_error "未找到后端 compose: $BACKEND_COMPOSE"
            exit 1
        fi
        if [ ! -f "$FRONTEND_COMPOSE" ]; then
            print_error "未找到前端 compose: $FRONTEND_COMPOSE"
            exit 1
        fi
        print_success "Compose 文件完整"

        # 启动
        print_info "启动全栈服务 (后端 + 前端)..."
        print_info "首次启动需要拉取镜像和初始化数据库，可能需要几分钟..."

        OUTPUTS_DIR="$PROJECT_DIR/.."
        cd "$OUTPUTS_DIR"

        WEB_PORT="$PORT" $COMPOSE_CMD \
            -f backend/deploy/docker-compose.yml \
            -f web-admin-react/deploy/docker-compose.fullstack.yml \
            up -d || {
            print_error "Docker Compose 启动失败"
            exit 1
        }
        print_success "全栈服务启动成功!"

        print_info "等待服务就绪 (最多 60 秒)..."
        for i in $(seq 1 12); do
            if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PORT" 2>/dev/null | grep -q 200; then
                print_success "前端验证通过 (HTTP 200)"
                break
            fi
            sleep 5
        done
        ;;
esac

# ============================================================
# 6. 完成信息
# ============================================================
echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}   部署完成!${NC}"
echo -e "${GREEN}============================================================${NC}"

case $MODE in
    preview)
        echo -e "  前端预览: ${BLUE}http://localhost:$PORT${NC}"
        ;;
    docker)
        echo -e "  前端地址: ${BLUE}http://localhost:$PORT${NC}"
        echo "  查看日志: docker logs -f ehc-web-admin"
        echo "  停止服务: docker stop ehc-web-admin"
        echo "  重新启动: docker start ehc-web-admin"
        echo "  删除容器: docker rm -f ehc-web-admin"
        ;;
    nginx)
        echo -e "  前端地址: ${BLUE}http://localhost${NC}"
        echo "  静态目录: $DEPLOY_DIR"
        echo "  重载配置: sudo nginx -s reload"
        ;;
    fullstack)
        echo -e "  前端地址: ${BLUE}http://localhost:$PORT${NC}"
        echo -e "  API 网关: ${BLUE}http://localhost:80${NC}"
        echo -e "  EMQX 面板: ${BLUE}http://localhost:18083${NC}"
        echo ""
        echo "  查看所有服务: $COMPOSE_CMD ps"
        echo "  查看日志:     $COMPOSE_CMD logs -f"
        echo "  停止所有:     $COMPOSE_CMD down"
        echo "  重启单个:     $COMPOSE_CMD restart web-admin"
        ;;
esac

echo ""
echo -e "  演示账号: ${YELLOW}admin / Admin@2026${NC}"
echo ""

# 如果是 Linux，提示防火墙
if [ "$(uname -s)" = "Linux" ] && [ "$MODE" != "preview" ]; then
    echo -e "${YELLOW}  提示:${NC} 如有防火墙，请开放端口 $PORT:"
    if command -v ufw &>/dev/null; then
        echo "    sudo ufw allow $PORT"
    elif command -v firewall-cmd &>/dev/null; then
        echo "    sudo firewall-cmd --add-port=$PORT/tcp --permanent"
        echo "    sudo firewall-cmd --reload"
    fi
fi
