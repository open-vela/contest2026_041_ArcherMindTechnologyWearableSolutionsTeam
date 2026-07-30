<#
.SYNOPSIS
    AI 老年健康守护系统 - 前端一键部署脚本 (Windows PowerShell)
.DESCRIPTION
    自动检测环境、构建前端、部署到指定模式。
    支持三种部署模式: preview(预览), docker(Docker容器), nginx(本地Nginx静态)
.PARAMETER Mode
    部署模式: preview, docker, nginx, fullstack
.PARAMETER Port
    Web 服务端口 (默认 3000)
.PARAMETER BackendUrl
    后端 API 地址 (默认 http://localhost:80)
.PARAMETER BuildOnly
    仅构建，不部署
.PARAMETER SkipBuild
    跳过构建步骤 (使用已有的 dist/)
.PARAMETER NoColor
    禁用彩色输出
.EXAMPLE
    .\deploy.ps1                          # 交互式部署
    .\deploy.ps1 -Mode docker -Port 3000  # Docker 部署在 3000 端口
    .\deploy.ps1 -Mode preview            # 快速预览模式
    .\deploy.ps1 -BuildOnly               # 仅构建
.NOTES
    版本: 1.0.0
    日期: 2026-06-24
#>

[CmdletBinding()]
param(
    [ValidateSet("preview", "docker", "nginx", "fullstack")]
    [string]$Mode,

    [int]$Port = 3000,

    [string]$BackendUrl = "http://localhost:80",

    [switch]$BuildOnly,

    [switch]$SkipBuild,

    [switch]$NoColor
)

# ============================================================
# 0. 脚本配置
# ============================================================
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
$DistDir = Join-Path $ProjectDir "dist"

# 彩色输出函数
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    if (-not $NoColor) {
        Write-Host $Message -ForegroundColor $Color
    } else {
        Write-Host $Message
    }
}

function Write-Step {
    param([string]$Step, [string]$Message)
    Write-ColorOutput "`n[$Step] $Message" "Cyan"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "  [OK] $Message" "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "  [!] $Message" "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "  [X] $Message" "Red"
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "  [i] $Message" "Gray"
}

# ============================================================
# 1. 欢迎信息
# ============================================================
Clear-Host
Write-ColorOutput "============================================================" "Cyan"
Write-ColorOutput "   AI 老年健康守护系统 - 前端一键部署脚本" "White"
Write-ColorOutput "   版本: 1.0.0 | Windows PowerShell" "White"
Write-ColorOutput "============================================================" "Cyan"
Write-Info "项目目录: $ProjectDir"
Write-Info "构建输出: $DistDir"

# ============================================================
# 2. 环境检查
# ============================================================
Write-Step "1/5" "环境检查..."

# 检查 Node.js
try {
    $nodeVersion = node --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Node.js $nodeVersion"
    } else {
        throw "Node.js 未安装"
    }
} catch {
    throw "Node.js 未安装或不在 PATH 中，请先安装 Node.js 18+: https://nodejs.org/"
}

# 检查 npm
try {
    $npmVersion = npm --version 2>$null
    Write-Success "npm $npmVersion"
} catch {
    throw "npm 不可用"
}

# 检查项目文件
if (-not (Test-Path (Join-Path $ProjectDir "package.json"))) {
    throw "未找到 package.json，请确认当前在项目根目录"
}
Write-Success "项目文件完整"

# ============================================================
# 3. 选择部署模式（如果未指定）
# ============================================================
if (-not $Mode) {
    Write-Step "2/5" "选择部署模式..."
    Write-Host ""
    Write-Host "  请选择部署模式:"
    Write-Host "    [1] preview   - Vite 预览模式 (快速测试构建产物)"
    Write-Host "    [2] docker    - Docker 容器部署 (推荐)"
    Write-Host "    [3] nginx     - 本地 Nginx 静态部署"
    Write-Host "    [4] fullstack - Docker Compose 全栈集成 (前后端一起)"
    Write-Host ""

    $choice = Read-Host "  请输入序号 (1-4，默认 2)"

    switch ($choice) {
        "1" { $Mode = "preview" }
        "3" { $Mode = "nginx" }
        "4" { $Mode = "fullstack" }
        default { $Mode = "docker" }
    }
}
Write-Success "部署模式: $Mode"

# ============================================================
# 4. 安装依赖 & 构建
# ============================================================
if (-not $SkipBuild) {
    Write-Step "3/5" "安装依赖..."

    $nodeModulesPath = Join-Path $ProjectDir "node_modules"
    if (Test-Path $nodeModulesPath) {
        Write-Info "node_modules 已存在，跳过安装"
        Write-Info "如需重新安装，请手动执行: npm install"
    } else {
        Write-Info "正在安装依赖 (可能需要几分钟)..."
        Push-Location $ProjectDir
        try {
            npm install --legacy-peer-deps
            if ($LASTEXITCODE -ne 0) {
                throw "npm install 失败"
            }
            Write-Success "依赖安装完成"
        } finally {
            Pop-Location
        }
    }

    Write-Step "4/5" "构建生产版本..."
    Write-Info "VITE_API_BASE_URL=$BackendUrl/api/v1"
    Write-Info "VITE_WS_URL=ws://${BackendUrl}/ws"

    Push-Location $ProjectDir
    try {
        $env:VITE_API_BASE_URL = "$BackendUrl/api/v1"
        $env:VITE_WS_URL = "ws://$BackendUrl/ws"

        npm run build
        if ($LASTEXITCODE -ne 0) {
            throw "构建失败，请检查上方错误信息"
        }
        Write-Success "构建成功 → $DistDir"

        # 显示构建统计
        if (Test-Path $DistDir) {
            $totalSize = (Get-ChildItem -Path $DistDir -Recurse -File | Measure-Object -Property Length -Sum).Sum
            $totalSizeMB = [math]::Round($totalSize / 1MB, 2)
            Write-Info "构建产物总大小: $totalSizeMB MB"
        }
    } finally {
        Pop-Location
    }

    if ($BuildOnly) {
        Write-Success "构建完成（--BuildOnly 模式，跳过部署）"
        Write-Host "`n构建产物位于: $DistDir"
        exit 0
    }
} else {
    Write-Info "跳过构建 (--SkipBuild)"
    if (-not (Test-Path $DistDir)) {
        throw "未找到构建产物 $DistDir，请先执行构建"
    }
}

# ============================================================
# 5. 部署
# ============================================================
Write-Step "5/5" "开始部署 (模式: $Mode)..."

switch ($Mode) {
    "preview" {
        # ---- Vite 预览模式 ----
        Write-Info "启动 Vite 预览服务器..."
        Write-Info "访问地址: http://localhost:$Port"
        Write-Info "按 Ctrl+C 停止"

        Push-Location $ProjectDir
        try {
            npx vite preview --port $Port --host
        } finally {
            Pop-Location
        }
    }

    "docker" {
        # ---- Docker 容器部署 ----
        Write-Info "检查 Docker 环境..."

        $dockerAvailable = Get-Command docker -ErrorAction SilentlyContinue
        if (-not $dockerAvailable) {
            throw "Docker 未安装或不在 PATH 中，请先安装 Docker Desktop: https://www.docker.com/"
        }
        Write-Success "Docker 可用"

        # 停止并删除旧容器（如果存在）
        $existingContainer = docker ps -a --filter "name=ehc-web-admin" --format "{{.Names}}" 2>$null
        if ($existingContainer) {
            Write-Info "停止并删除旧容器..."
            docker stop ehc-web-admin 2>$null | Out-Null
            docker rm ehc-web-admin 2>$null | Out-Null
        }

        # 构建镜像
        Write-Info "构建 Docker 镜像..."
        Push-Location $ProjectDir
        try {
            docker build `
                --build-arg "VITE_API_BASE_URL=$BackendUrl/api/v1" `
                --build-arg "VITE_WS_URL=ws://$BackendUrl/ws" `
                -t elderly-admin-web:latest `
                -f deploy/Dockerfile .
            if ($LASTEXITCODE -ne 0) {
                throw "Docker 镜像构建失败"
            }
            Write-Success "镜像构建完成"
        } finally {
            Pop-Location
        }

        # 启动容器
        Write-Info "启动容器 (端口: $Port)..."
        docker run -d `
            --name ehc-web-admin `
            -p "${Port}:80" `
            --restart always `
            elderly-admin-web:latest

        if ($LASTEXITCODE -eq 0) {
            Write-Success "容器启动成功!"
        } else {
            throw "容器启动失败"
        }

        # 等待健康检查
        Write-Info "等待服务就绪..."
        Start-Sleep -Seconds 5

        # 验证
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:$Port" -UseBasicParsing -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                Write-Success "服务验证通过 (HTTP 200)"
            }
        } catch {
            Write-Warning "服务可能尚未就绪，请稍后手动验证"
        }
    }

    "nginx" {
        # ---- 本地 Nginx 静态部署 ----
        Write-Info "检查 Nginx 环境..."

        $nginxAvailable = Get-Command nginx -ErrorAction SilentlyContinue
        if (-not $nginxAvailable) {
            throw "Nginx 未安装或不在 PATH 中，请先安装 Nginx: https://nginx.org/"
        }

        $nginxPath = (Get-Command nginx).Source
        $nginxDir = Split-Path -Parent $nginxPath
        Write-Success "Nginx 路径: $nginxPath"

        # 询问部署目录
        $defaultDeployDir = "C:\nginx\html\elderly-admin"
        $deployDir = Read-Host "  请输入部署目录 (默认: $defaultDeployDir)"
        if ([string]::IsNullOrWhiteSpace($deployDir)) {
            $deployDir = $defaultDeployDir
        }

        # 创建目录
        if (-not (Test-Path $deployDir)) {
            New-Item -ItemType Directory -Path $deployDir -Force | Out-Null
        }

        # 复制文件
        Write-Info "复制构建产物到 $deployDir ..."
        Copy-Item -Path "$DistDir\*" -Destination $deployDir -Recurse -Force
        Write-Success "文件复制完成"

        # 复制 Nginx 配置
        $nginxConfDir = Join-Path $nginxDir "conf\conf.d"
        if (-not (Test-Path $nginxConfDir)) {
            New-Item -ItemType Directory -Path $nginxConfDir -Force | Out-Null
        }
        $nginxConfTarget = Join-Path $nginxConfDir "elderly-admin.conf"
        Copy-Item -Path (Join-Path $ScriptDir "nginx.conf") -Destination $nginxConfTarget -Force
        Write-Success "Nginx 配置已复制到 $nginxConfTarget"

        # 测试并重载 Nginx
        Write-Info "测试 Nginx 配置..."
        nginx -t
        if ($LASTEXITCODE -eq 0) {
            nginx -s reload
            Write-Success "Nginx 已重载"
        } else {
            Write-Warning "Nginx 配置测试未通过，请手动检查"
        }

        Write-Info "请确认 Nginx 配置中 root 路径指向: $deployDir"
    }

    "fullstack" {
        # ---- Docker Compose 全栈集成 ----
        Write-Info "检查 Docker Compose 环境..."

        $dockerComposeAvailable = Get-Command docker-compose -ErrorAction SilentlyContinue
        if (-not $dockerComposeAvailable) {
            # 尝试 docker compose (v2)
            docker compose version 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) {
                $dockerComposeCmd = "docker compose"
                Write-Success "Docker Compose (v2) 可用"
            } else {
                throw "Docker Compose 未安装"
            }
        } else {
            $dockerComposeCmd = "docker-compose"
            Write-Success "Docker Compose 可用"
        }

        # 检查后端 docker-compose.yml
        $backendCompose = Join-Path $ProjectDir "..\backend\deploy\docker-compose.yml"
        if (-not (Test-Path $backendCompose)) {
            throw "未找到后端 docker-compose.yml: $backendCompose"
        }

        $frontendCompose = Join-Path $ScriptDir "docker-compose.fullstack.yml"
        if (-not (Test-Path $frontendCompose)) {
            throw "未找到前端 compose 文件: $frontendCompose"
        }

        Write-Info "启动全栈服务 (后端 + 前端)..."
        Write-Info "这可能需要几分钟，首次启动需要拉取镜像和初始化数据库..."

        $outputsDir = Join-Path $ProjectDir ".."
        Push-Location $outputsDir

        try {
            $env:WEB_PORT = $Port.ToString()

            # 使用 & 调用，因为 docker compose 包含空格
            $cmdArgs = @(
                "-f", "backend/deploy/docker-compose.yml",
                "-f", "web-admin-react/deploy/docker-compose.fullstack.yml",
                "up", "-d"
            )

            if ($dockerComposeCmd -eq "docker compose") {
                & docker compose $cmdArgs
            } else {
                & docker-compose $cmdArgs
            }

            if ($LASTEXITCODE -eq 0) {
                Write-Success "全栈服务启动成功!"
            } else {
                throw "Docker Compose 启动失败"
            }
        } finally {
            Pop-Location
        }

        Write-Info "等待服务就绪 (30秒)..."
        Start-Sleep -Seconds 30

        # 验证
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:$Port" -UseBasicParsing -TimeoutSec 10
            if ($response.StatusCode -eq 200) {
                Write-Success "前端验证通过 (HTTP 200)"
            }
        } catch {
            Write-Warning "前端服务可能尚未就绪，请稍后手动验证"
        }
    }
}

# ============================================================
# 6. 完成信息
# ============================================================
Write-Host ""
Write-ColorOutput "============================================================" "Green"
Write-ColorOutput "   部署完成!" "Green"
Write-ColorOutput "============================================================" "Green"

switch ($Mode) {
    "preview" {
        Write-Host "  前端预览: http://localhost:$Port"
    }
    "docker" {
        Write-Host "  前端地址: http://localhost:$Port"
        Write-Host "  查看日志: docker logs -f ehc-web-admin"
        Write-Host "  停止服务: docker stop ehc-web-admin"
        Write-Host "  重新启动: docker start ehc-web-admin"
    }
    "nginx" {
        Write-Host "  前端地址: http://localhost"
        Write-Host "  静态目录: $deployDir"
    }
    "fullstack" {
        Write-Host "  前端地址: http://localhost:$Port"
        Write-Host "  API 网关: http://localhost:80"
        Write-Host "  EMQX 面板: http://localhost:18083"
        Write-Host ""
        Write-Host "  查看所有服务: docker compose ps"
        Write-Host "  停止所有服务: docker compose down"
    }
}

Write-Host ""
Write-Host "  演示账号: admin / Admin@2026"
Write-Host ""
