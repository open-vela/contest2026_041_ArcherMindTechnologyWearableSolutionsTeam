#!/usr/bin/env bash
# ============================================================
# AI老年健康守护系统 — Linux 一键部署脚本
# 版本: 1.0
# 支持: Ubuntu 20.04+ / Debian 11+ / CentOS 7+ / Rocky 8+
# 用法: chmod +x setup.sh && sudo ./setup.sh
# ============================================================

set -euo pipefail

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

success() { echo -e "${GREEN}[√]${NC} $*"; }
error()   { echo -e "${RED}[X]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
info()    { echo -e "${CYAN}[i]${NC} $*"; }
step()    { echo -e "\n${MAGENTA}===== $* =====${NC}"; }

banner() {
    echo -e "${CYAN}"
    echo "  ╔═══════════════════════════════════════════════════════╗"
    echo "  ║        AI 老年健康守护系统 — Linux 一键部署         ║"
    echo "  ║                    v1.0  2026                        ║"
    echo "  ╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ==================== 检测操作系统 ====================
detect_os() {
    step "系统环境检测"

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
        info "操作系统: $PRETTY_NAME"
    else
        error "无法识别操作系统，仅支持 Ubuntu/Debian/CentOS/Rocky Linux"
        exit 1
    fi

    # 内存
    MEM_TOTAL=$(awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo)
    info "内存: ${MEM_TOTAL}GB"
    if [ "$MEM_TOTAL" -lt 4 ]; then
        warn "内存不足 4GB，推荐最低 8GB，继续部署（可能影响性能）"
    fi

    # 磁盘空间
    DISK_FREE=$(df -BG . | awk 'NR==2{print $4}' | tr -d 'G')
    info "磁盘剩余空间: ${DISK_FREE}GB"
    if [ "$DISK_FREE" -lt 10 ]; then
        warn "磁盘空间不足 10GB，可能影响 Docker 镜像存储"
    fi

    # CPU
    CPU_CORES=$(nproc)
    info "CPU 核心: ${CPU_CORES}"
}

# ==================== 安装 Docker ====================
install_docker() {
    step "安装 Docker 环境"

    if command -v docker &>/dev/null; then
        DOCKER_VER=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "unknown")
        success "Docker $DOCKER_VER 已安装"
    else
        warn "Docker 未安装，正在自动安装..."
        case "$OS" in
            ubuntu|debian)
                info "使用官方脚本安装 Docker (Debian/Ubuntu)..."
                curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
                sh /tmp/get-docker.sh
                rm -f /tmp/get-docker.sh
                systemctl enable docker
                systemctl start docker
                ;;
            centos|rocky|rhel|almalinux)
                info "使用官方脚本安装 Docker (RHEL/CentOS)..."
                curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
                sh /tmp/get-docker.sh
                rm -f /tmp/get-docker.sh
                systemctl enable docker
                systemctl start docker
                ;;
            *)
                error "不支持的操作系统: $OS"
                exit 1
                ;;
        esac
        success "Docker 安装完成"
    fi

    # Docker Compose Plugin
    if ! docker compose version &>/dev/null; then
        warn "Docker Compose Plugin 未安装，正在安装..."
        case "$OS" in
            ubuntu|debian)
                apt-get update -qq && apt-get install -y -qq docker-compose-plugin 2>/dev/null || {
                    # Fallback: 手动安装
                    ARCH=$(uname -m)
                    COMPOSE_VERSION="v2.24.0"
                    mkdir -p /usr/local/lib/docker/cli-plugins
                    curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${ARCH}" \
                        -o /usr/local/lib/docker/cli-plugins/docker-compose
                    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
                }
                ;;
            centos|rocky|rhel|almalinux)
                ARCH=$(uname -m)
                COMPOSE_VERSION="v2.24.0"
                mkdir -p /usr/local/lib/docker/cli-plugins
                curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${ARCH}" \
                    -o /usr/local/lib/docker/cli-plugins/docker-compose
                chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
                ;;
        esac
        success "Docker Compose Plugin 安装完成"
    fi

    COMPOSE_VER=$(docker compose version --short 2>/dev/null || echo "ok")
    success "Docker Compose $COMPOSE_VER"
}

# ==================== 安装 Go（可选） ====================
install_golang() {
    if command -v go &>/dev/null; then
        info "Go $(go version | awk '{print $3}') 已安装"
        return
    fi

    info "Go 未安装（Docker 部署不需要，仅本地编译需要，跳过）"
}

# ==================== 检测端口 ====================
check_ports() {
    step "端口可用性检查"

    PORTS=(80 443 3306 6379 1883 8001 8002 8003 8004 8005 8006 8007 8008 8009 8010 8011)
    CONFLICTS=()

    for port in "${PORTS[@]}"; do
        if ss -tlnp 2>/dev/null | grep -q ":$port "; then
            CONFLICTS+=("$port")
        fi
    done

    if [ ${#CONFLICTS[@]} -gt 0 ]; then
        warn "以下端口已被占用: ${CONFLICTS[*]}"
        read -r -p "是否忽略端口冲突继续？(y/N): " skip
        if [ "$skip" != "y" ]; then
            echo "退出部署。请停止占用端口的程序后重试。"
            exit 1
        fi
    else
        success "所有端口均可用"
    fi
}

# ==================== 配置初始化 ====================
init_config() {
    step "初始化配置"

    # 定位项目根目录
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    cd "$PROJECT_ROOT"

    info "项目目录: $PROJECT_ROOT"

    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            cp .env.example .env
            success "已从 .env.example 创建 .env 配置文件"
        else
            warn ".env.example 不存在，使用默认配置"
            cat > .env << 'EOF'
# AI老年健康守护系统 - 环境变量配置
MYSQL_ROOT_PASSWORD=root123456
MYSQL_DATABASE=elderly_health
JWT_SECRET=your-secret-key-change-in-production
ADMIN_USERNAME=admin
ADMIN_PASSWORD=Admin@2026
EOF
        fi

        # 生成随机 JWT Secret
        JWT_RANDOM=$(openssl rand -hex 32 2>/dev/null || head -c32 /dev/urandom | xxd -p)
        if [ -n "$JWT_RANDOM" ]; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s/your-secret-key-change-in-production/$JWT_RANDOM/" .env
            else
                sed -i "s/your-secret-key-change-in-production/$JWT_RANDOM/" .env
            fi
            success "已自动生成 JWT 密钥"
        fi

        warn "请检查 .env 文件中的数据库密码等敏感配置"
        read -r -p "是否现在编辑 .env？(y/N): " edit
        if [ "$edit" = "y" ]; then
            ${EDITOR:-nano} .env
        fi
    else
        info "已存在 .env 配置文件"
    fi
}

# ==================== 构建镜像 ====================
build_images() {
    step "构建 Docker 镜像"

    START_TIME=$(date +%s)

    info "拉取基础镜像..."
    docker pull mysql:8.0.35 &
    docker pull redis:7.2-alpine &
    docker pull nginx:1.25-alpine &
    docker pull emqx/emqx:5.3.0 &
    docker pull node:22-alpine &
    wait
    success "基础镜像拉取完成"

    # 检查前端源码是否存在
    FRONTEND_DIR="$PROJECT_ROOT/../web-admin-react"
    if [ -d "$FRONTEND_DIR" ]; then
        info "发现前端源码目录: $FRONTEND_DIR"
        info "将在 Docker 多阶段构建中自动编译前端（Node → Nginx）"
    else
        warn "未找到前端目录 $FRONTEND_DIR，跳过前端构建"
        warn "如需部署前端，请确认 web-admin-react 与 backend 在同级目录"
    fi

    info "编译 Go 微服务镜像 + 前端镜像（首次约需 10-20 分钟）..."
    docker compose -f deploy/docker-compose.yml build --parallel

    END_TIME=$(date +%s)
    DURATION=$(( (END_TIME - START_TIME) / 60 ))
    success "镜像构建完成，耗时约 ${DURATION} 分钟"
}

# ==================== 启动服务 ====================
start_services() {
    step "启动所有服务"

    docker compose -f deploy/docker-compose.yml up -d

    info "等待服务就绪（最多 120 秒）..."

    local max_wait=120
    local elapsed=0

    while [ $elapsed -lt $max_wait ]; do
        sleep 5
        elapsed=$((elapsed + 5))

        local mysql_ok=false redis_ok=false emqx_ok=false

        [ "$(docker inspect --format='{{.State.Health.Status}}' ehc-mysql 2>/dev/null)" = "healthy" ] && mysql_ok=true
        [ "$(docker inspect --format='{{.State.Health.Status}}' ehc-redis 2>/dev/null)" = "healthy" ] && redis_ok=true
        [ "$(docker inspect --format='{{.State.Health.Status}}' ehc-emqx 2>/dev/null)"   = "healthy" ] && emqx_ok=true

        echo -e "  [${elapsed}s] MySQL=$mysql_ok  Redis=$redis_ok  EMQX=$emqx_ok"

        if $mysql_ok && $redis_ok && $emqx_ok; then
            success "所有基础服务就绪！"
            sleep 10  # 等微服务启动
            return 0
        fi
    done

    warn "部分服务可能未就绪，查看具体状态: docker compose -f deploy/docker-compose.yml ps"
}

# ==================== 验证部署 ====================
test_deployment() {
    step "验证部署"

    info "服务运行状态:"
    docker compose -f deploy/docker-compose.yml ps

    echo ""
    info "健康检查:"
    if HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80/health 2>/dev/null); then
        if [ "$HEALTH" = "200" ]; then
            success "API Gateway 响应正常 (HTTP $HEALTH)"
        else
            warn "API Gateway 返回 HTTP $HEALTH"
        fi
    else
        warn "API Gateway 无法连接，服务可能仍在启动"
    fi

    echo ""
    info "测试管理员登录..."
    LOGIN_RESP=$(curl -s -X POST http://localhost:80/v1/admin/login \
        -H "Content-Type: application/json" \
        -d '{"username":"admin","password":"Admin@2026"}' 2>/dev/null || echo '{"code":-1}')

    if echo "$LOGIN_RESP" | grep -q '"code":0'; then
        TOKEN=$(echo "$LOGIN_RESP" | grep -o '"access_token":"[^"]*"' | head -1 | cut -d'"' -f4)
        success "管理员登录成功！Token: ${TOKEN:0:30}..."
    else
        warn "登录测试失败: $LOGIN_RESP"
        info "数据库初始化可能需要几分钟，请稍后重试"
    fi
}

# ==================== 注册 systemd 服务 ====================
register_systemd() {
    step "注册开机自启动"

    read -r -p "是否注册为 systemd 服务，实现开机自启动？(y/N): " register
    if [ "$register" != "y" ]; then
        info "跳过 systemd 注册"
        return
    fi

    cat > /etc/systemd/system/ehc-elderly-health.service << SERVICE_EOF
[Unit]
Description=AI老年健康守护系统
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$PROJECT_ROOT
ExecStart=/usr/bin/docker compose -f $PROJECT_ROOT/deploy/docker-compose.yml up -d
ExecStop=/usr/bin/docker compose -f $PROJECT_ROOT/deploy/docker-compose.yml down
ExecReload=/usr/bin/docker compose -f $PROJECT_ROOT/deploy/docker-compose.yml restart
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE_EOF

    systemctl daemon-reload
    systemctl enable ehc-elderly-health.service
    success "systemd 服务已注册: systemctl {start|stop|restart|status} ehc-elderly-health"
}

# ==================== 显示部署摘要 ====================
show_summary() {
    step "部署完成！"

    SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")

    echo -e "${CYAN}"
    echo "  ╔═══════════════════════════════════════════════════════╗"
    echo "  ║              系统部署成功！                           ║"
    echo "  ╠═══════════════════════════════════════════════════════╣"
    echo "  ║                                                       ║"
    echo "  ║  前端管理台:   http://${SERVER_IP}                    "
    echo "  ║  API 接口:     http://${SERVER_IP}/api/v1             "
    echo "  ║  EMQX 面板:    http://${SERVER_IP}:18083              "
    echo "  ║                                                       ║"
    echo "  ║  管理员账号:   admin / Admin@2026                    ║"
    echo "  ║     (首次登录后请立即修改密码！)                       ║"
    echo "  ║                                                       ║"
    echo "  ║  常用命令:                                            ║"
    echo "  ║    查看状态: ./deploy/setup.sh status                ║"
    echo "  ║    查看日志: ./deploy/setup.sh logs                  ║"
    echo "  ║    重启服务: ./deploy/setup.sh restart               ║"
    echo "  ║    停止服务: ./deploy/setup.sh stop                  ║"
    echo "  ║                                                       ║"
    echo "  ╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # 防火墙提示
    if command -v ufw &>/dev/null && ufw status | grep -q "active"; then
        warn "检测到 ufw 防火墙已开启，如需外网访问请放行端口:"
        echo "  sudo ufw allow 80/tcp"
        echo "  sudo ufw allow 443/tcp"
        echo "  sudo ufw allow 1883/tcp   # MQTT（手表端需要）"
    fi

    if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
        warn "检测到 firewalld 已开启，如需外网访问请放行端口:"
        echo "  sudo firewall-cmd --add-port=80/tcp --permanent"
        echo "  sudo firewall-cmd --add-port=443/tcp --permanent"
        echo "  sudo firewall-cmd --add-port=1883/tcp --permanent"
        echo "  sudo firewall-cmd --reload"
    fi
}

# ==================== 卸载 ====================
do_uninstall() {
    step "卸载系统"
    warn "此操作将停止所有服务并删除所有数据！"
    read -r -p "输入 DELETE 确认卸载（其他任意键取消）: " confirm
    if [ "$confirm" != "DELETE" ]; then
        echo "已取消"
        return
    fi

    # 停止 systemd 服务
    systemctl stop ehc-elderly-health.service 2>/dev/null || true
    systemctl disable ehc-elderly-health.service 2>/dev/null || true
    rm -f /etc/systemd/system/ehc-elderly-health.service
    systemctl daemon-reload 2>/dev/null || true

    # 停止并删除容器+数据卷
    docker compose -f deploy/docker-compose.yml down -v
    success "已完全卸载"
}

# ==================== 主入口 ====================
main() {
    banner

    # 检查 root 权限
    if [ "$EUID" -ne 0 ] && [ "$1" != "help" ] && [ "$1" != "status" ] && [ "$1" != "logs" ]; then
        warn "建议使用 sudo 运行以获得完整功能（Docker 权限、systemd 注册）"
        echo ""
    fi

    # 导航到项目目录
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    cd "$PROJECT_ROOT"

    # 命令分发
    case "${1:-deploy}" in
        deploy|install)
            detect_os
            install_docker
            install_golang
            check_ports
            init_config
            build_images
            start_services
            test_deployment
            register_systemd
            show_summary
            ;;
        status)
            docker compose -f deploy/docker-compose.yml ps
            ;;
        logs)
            docker compose -f deploy/docker-compose.yml logs -f --tail=100
            ;;
        stop)
            docker compose -f deploy/docker-compose.yml down
            success "已停止所有服务"
            ;;
        restart)
            docker compose -f deploy/docker-compose.yml restart
            success "已重启所有服务"
            ;;
        uninstall)
            do_uninstall
            ;;
        update)
            info "拉取最新代码..."
            git pull 2>/dev/null || warn "Git 仓库未配置，跳过拉取"
            info "重新构建镜像..."
            docker compose -f deploy/docker-compose.yml build --parallel
            info "重启服务..."
            docker compose -f deploy/docker-compose.yml up -d
            success "更新完成"
            ;;
        help|--help|-h)
            echo ""
            echo "AI老年健康守护系统 - Linux 部署脚本"
            echo ""
            echo "用法: sudo ./setup.sh [命令]"
            echo ""
            echo "命令:"
            echo "  deploy     执行完整部署流程（默认）"
            echo "  status     查看服务运行状态"
            echo "  logs       实时查看服务日志"
            echo "  stop       停止所有服务"
            echo "  restart    重启所有服务"
            echo "  update     更新代码并重新部署"
            echo "  uninstall  卸载系统（删除所有服务+数据卷）"
            echo "  help       显示此帮助"
            echo ""
            ;;
        *)
            error "未知命令: $1"
            echo "运行 ./setup.sh help 查看帮助"
            exit 1
            ;;
    esac
}

main "$@"
