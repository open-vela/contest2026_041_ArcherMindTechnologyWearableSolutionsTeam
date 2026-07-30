# ============================================================
# AI老年健康守护系统 — Windows 一键部署脚本
# 版本: 1.0
# 兼容: Windows 10/11 Pro/Enterprise (需 Docker Desktop)
# 用法: 
#   右键「setup.ps1」→「使用 PowerShell 运行」（推荐）
#   或在 PowerShell 中: cd backend/deploy ; .\setup.ps1
#
#   首次运行如遇执行策略限制:
#     Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#     .\setup.ps1
# ============================================================

$ErrorActionPreference = "Stop"
$Host.UI.RawUI.WindowTitle = "AI老年健康守护系统 - 一键部署"

# UTF-8 支持
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 颜色定义
function Write-Success { Write-Host "[√] $args" -ForegroundColor Green }
function Write-Error { Write-Host "[X] $args" -ForegroundColor Red }
function Write-Warning { Write-Host "[!] $args" -ForegroundColor Yellow }
function Write-Info { Write-Host "[i] $args" -ForegroundColor Cyan }
function Write-Step { Write-Host "`n===== $args =====" -ForegroundColor Magenta }
function Write-Banner {
    Write-Host @"

    ╔═══════════════════════════════════════════════════════╗
    ║        AI 老年健康守护系统 — Windows 一键部署        ║
    ║                    v1.0  2026                         ║
    ╚═══════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan
}

# ==================== 环境检测 ====================
function Test-Environment {
    Write-Step "环境检测"
    
    # 1. 检测操作系统
    $os = Get-CimInstance Win32_OperatingSystem
    Write-Info "操作系统: $($os.Caption) ($([math]::Round($os.TotalVisibleMemorySize/1MB)) GB RAM)"
    
    if ($os.TotalVisibleMemorySize -lt 4GB * 1024) {
        Write-Error "内存不足 4GB，部署可能失败。推荐最低 8GB"
    }
    
    # 2. 检测 Docker
    $dockerVersion = $null
    try { $dockerVersion = docker version --format '{{.Server.Version}}' 2>$null } catch {}
    if ($dockerVersion) {
        Write-Success "Docker $dockerVersion 已安装"
    } else {
        Write-Warning "Docker 未安装或未运行！"
        Write-Host ""
        Write-Host "请先安装 Docker Desktop for Windows:" -ForegroundColor Yellow
        Write-Host "  https://www.docker.com/products/docker-desktop/" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "安装后请确保:" -ForegroundColor Yellow
        Write-Host "  1. WSL2 已启用（Docker Desktop 会自动配置）" -ForegroundColor White
        Write-Host "  2. Docker Desktop 正在运行（右下角托盘鲸鱼图标）" -ForegroundColor White
        Write-Host "  3. 虚拟化已在 BIOS 中开启" -ForegroundColor White
        Write-Host ""
        $install = Read-Host "是否已安装好 Docker？输入 y 继续，其他键退出"
        if ($install -ne 'y') {
            Write-Host "退出部署。请安装 Docker 后重新运行本脚本。"
            Pause
            exit 1
        }
    }
    
    # 3. 检测 Docker Compose
    try { 
        $composeVersion = docker compose version --format '{{.Client.Version}}' 2>$null 
        if ($composeVersion) {
            Write-Success "Docker Compose $composeVersion 已可用"
        }
    } catch {
        Write-Error "Docker Compose 不可用，请升级 Docker Desktop"
        Pause; exit 1
    }
    
    # 4. 检测 Go（仅本地编译需要）
    try {
        $goVersion = go version 2>$null
        if ($goVersion) { Write-Info "Go 已安装（本地编译可选，Docker 部署不需要）" }
    } catch {}
    
    # 5. 检测端口占用
    Write-Info "检查端口占用..."
    $ports = @(80, 443, 3306, 6379, 1883, 8001, 8002, 8004, 8005, 8006, 8008, 8010, 8011)
    $conflicts = @()
    foreach ($port in $ports) {
        $listener = netstat -ano 2>$null | Select-String ":$port " | Select-String "LISTENING"
        if ($listener) { $conflicts += $port }
    }
    if ($conflicts.Count -gt 0) {
        Write-Warning "以下端口已被占用: $($conflicts -join ', ')"
        Write-Info "请停止占用这些端口的程序（如本地 MySQL、Nginx、Redis），或修改 docker-compose.yml 中的端口映射"
        $skip = Read-Host "忽略端口冲突继续？(y/N)"
        if ($skip -ne 'y') { Write-Host "退出部署。"; Pause; exit 1 }
    } else {
        Write-Success "所有端口均可用"
    }
    
    # 6. 磁盘空间
    $disk = Get-PSDrive -Name (Get-Location).Drive.Name
    $freeGB = [math]::Round($disk.Free / 1GB, 1)
    Write-Info "磁盘剩余空间: ${freeGB}GB"
    if ($freeGB -lt 10) {
        Write-Warning "磁盘空间不足 10GB，Docker 镜像构建可能失败"
    }
}

# ==================== 配置文件 ====================
function Initialize-Config {
    Write-Step "初始化配置"
    
    # 获取脚本所在目录，推算项目根目录
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = Split-Path -Parent $scriptDir
    Set-Location $projectRoot
    
    Write-Info "项目目录: $projectRoot"
    
    # 检查 .env 文件
    if (-not (Test-Path ".env")) {
        if (Test-Path ".env.example") {
            Copy-Item ".env.example" ".env"
            Write-Success "已从 .env.example 创建 .env 配置文件"
        } else {
            Write-Warning ".env.example 不存在，创建默认 .env"
@'
# AI老年健康守护系统 - 环境变量配置
# 生产环境请务必修改以下密码！

# 数据库
MYSQL_ROOT_PASSWORD=root123456
MYSQL_DATABASE=elderly_health

# JWT
JWT_SECRET=your-secret-key-change-in-production

# 管理员默认账号（首次登录后强制改密）
ADMIN_USERNAME=admin
ADMIN_PASSWORD=Admin@2026
'@ | Out-File -FilePath ".env" -Encoding utf8
        }
        
        Write-Warning "请检查并修改 .env 文件中的敏感配置（数据库密码、JWT密钥）"
        Write-Host ""
        $edit = Read-Host "是否现在用记事本打开 .env 编辑？(y/N)"
        if ($edit -eq 'y') { notepad .env }
    } else {
        Write-Info "已存在 .env 配置文件"
    }
    
    # 检查 docker-compose.yml
    if (-not (Test-Path "deploy/docker-compose.yml")) {
        Write-Error "deploy/docker-compose.yml 不存在！请确认项目目录完整。"
        Pause; exit 1
    }
    
    # 检查 migrations
    if (-not (Test-Path "migrations/001_init.sql")) {
        Write-Error "数据库迁移脚本 migrations/001_init.sql 不存在！"
        Pause; exit 1
    }
}

# ==================== 构建镜像 ====================
function Build-Images {
    Write-Step "构建 Docker 镜像（首次约需 5-15 分钟，取决于网络速度）"
    
    $startTime = Get-Date
    
    Write-Info "正在拉取基础镜像..."
    docker pull mysql:8.0.35
    docker pull redis:7.2-alpine
    docker pull nginx:1.25-alpine
    docker pull emqx/emqx:5.3.0
    
    Write-Info "正在编译 Go 微服务镜像..."
    docker compose -f deploy/docker-compose.yml build --parallel 2>&1
    
    $duration = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)
    Write-Success "镜像构建完成，耗时 ${duration} 分钟"
}

# ==================== 启动服务 ====================
function Start-Services {
    Write-Step "启动所有服务"
    
    docker compose -f deploy/docker-compose.yml up -d
    
    Write-Info "等待服务就绪..."
    
    # 健康检查 (最多等 120 秒)
    $maxWait = 120
    $elapsed = 0
    $allHealthy = $false
    
    while ($elapsed -lt $maxWait) {
        Start-Sleep -Seconds 5
        $elapsed += 5
        
        # 检查各服务健康状态
        $statuses = @{}
        try {
            $mysqlOK = (docker inspect --format='{{.State.Health.Status}}' ehc-mysql 2>$null) -eq "healthy"
            $redisOK = (docker inspect --format='{{.State.Health.Status}}' ehc-redis 2>$null) -eq "healthy"
            $emqxOK  = (docker inspect --format='{{.State.Health.Status}}' ehc-emqx 2>$null) -eq "healthy"
            
            $statuses.MySQL = $mysqlOK
            $statuses.Redis = $redisOK
            $statuses.EMQX  = $emqxOK
            
            Write-Info "[${elapsed}s] MySQL=$mysqlOK  Redis=$redisOK  EMQX=$emqxOK"
            
            if ($mysqlOK -and $redisOK -and $emqxOK) {
                $allHealthy = $true
                break
            }
        } catch {
            # 容器可能还没创建
        }
    }
    
    if ($allHealthy) {
        Write-Success "所有基础服务就绪！"
        
        # 再等 10 秒让微服务启动
        Start-Sleep -Seconds 10
    } else {
        Write-Warning "部分服务可能未完全就绪，查看日志: docker compose -f deploy/docker-compose.yml logs"
    }
}

# ==================== 验证部署 ====================
function Test-Deployment {
    Write-Step "验证部署"
    
    Write-Info "服务运行状态:"
    docker compose -f deploy/docker-compose.yml ps
    
    Write-Info "`n健康检查:"
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:80/health" -UseBasicParsing -TimeoutSec 10
        Write-Success "API Gateway 响应: $($response.Content)"
    } catch {
        Write-Warning "API Gateway 健康检查失败: $_"
        Write-Info "服务可能仍在启动中，请等待 1-2 分钟后重试"
    }
    
    # 测试管理员登录
    Write-Info "`n测试管理员登录..."
    try {
        $loginBody = @{username="admin";password="Admin@2026"} | ConvertTo-Json
        $loginResp = Invoke-WebRequest -Uri "http://localhost:80/v1/admin/login" `
            -Method POST `
            -Body $loginBody `
            -ContentType "application/json" `
            -UseBasicParsing `
            -TimeoutSec 10
        $loginData = $loginResp.Content | ConvertFrom-Json
        if ($loginData.code -eq 0) {
            Write-Success "管理员登录成功！Token: $($loginData.data.access_token.Substring(0,20))..."
        } else {
            Write-Warning "登录返回: $($loginResp.Content)"
        }
    } catch {
        Write-Warning "登录测试失败: $_"
        Write-Info "如果 MySQL 刚初始化，可能需要等待几秒让数据表创建完成"
    }
}

# ==================== 输出信息 ====================
function Show-Summary {
    Write-Step "部署完成！"
    
    Write-Host @"

    ╔═══════════════════════════════════════════════════════╗
    ║              🎉 系统部署成功！                       ║
    ╠═══════════════════════════════════════════════════════╣
    ║                                                       ║
    ║  🌐 Web 管理端:    http://localhost:80               ║
    ║  📊 EMQX 面板:     http://localhost:18083            ║
    ║                                                       ║
    ║  🔑 管理员账号:    admin / Admin@2026                ║
    ║     (首次登录后请立即修改密码！)                       ║
    ║                                                       ║
    ║  📋 常用命令:                                         ║
    ║     查看日志:  docker compose -f deploy/docker-compose.yml logs -f  ║
    ║     停止服务:  docker compose -f deploy/docker-compose.yml down     ║
    ║     启动服务:  docker compose -f deploy/docker-compose.yml up -d    ║
    ║     重启服务:  docker compose -f deploy/docker-compose.yml restart  ║
    ║                                                       ║
    ║  💾 数据目录 (Docker Volume):                         ║
    ║     MySQL: ehc_mysql_data                            ║
    ║     Redis: ehc_redis_data                            ║
    ║     EMQX:  ehc_emqx_data / ehc_emqx_log              ║
    ║                                                       ║
    ╚═══════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan
}

# ==================== 快捷方式 ====================
function Create-Shortcut {
    $create = Read-Host "是否在桌面创建快捷方式？(y/N)"
    if ($create -ne 'y') { return }
    
    $desktop = [Environment]::GetFolderPath("Desktop")
    $scriptDir = (Get-Location).Path
    
    # 创建管理端快捷方式
    $wsh = New-Object -ComObject WScript.Shell
    
    # 1) 启动脚本
    $startScript = Join-Path $scriptDir "deploy\start.bat"
@'
@echo off
cd /d "%~dp0\.."
echo 启动 AI老年健康守护系统...
docker compose -f deploy/docker-compose.yml up -d
echo 启动完成！访问 http://localhost:80
pause
'@ | Out-File -FilePath $startScript -Encoding ASCII
    
    $lnk = $wsh.CreateShortcut("$desktop\AI健康守护-启动.lnk")
    $lnk.TargetPath = $startScript
    $lnk.WorkingDirectory = $scriptDir
    $lnk.IconLocation = "shell32.dll,21"
    $lnk.Save()
    
    # 2) 停止脚本
    $stopScript = Join-Path $scriptDir "deploy\stop.bat"
@'
@echo off
cd /d "%~dp0\.."
echo 停止 AI老年健康守护系统...
docker compose -f deploy/docker-compose.yml down
echo 已停止。
pause
'@ | Out-File -FilePath $stopScript -Encoding ASCII
    
    $lnk2 = $wsh.CreateShortcut("$desktop\AI健康守护-停止.lnk")
    $lnk2.TargetPath = $stopScript
    $lnk2.WorkingDirectory = $scriptDir
    $lnk2.IconLocation = "shell32.dll,27"
    $lnk2.Save()
    
    # 3) 管理端 URL 快捷方式
    $lnk3 = $wsh.CreateShortcut("$desktop\AI健康守护-管理端.url")
    $lnk3.TargetPath = "http://localhost:80"
    $lnk3.Save()
    
    Write-Success "桌面快捷方式已创建"
}

# ==================== 清理（卸载） ====================
function Invoke-Uninstall {
    Write-Step "卸载系统"
    Write-Warning "此操作将停止所有服务并删除所有数据！"
    $confirm = Read-Host "输入 DELETE 确认卸载（其他任意键取消）"
    if ($confirm -ne "DELETE") {
        Write-Host "已取消"
        return
    }
    
    docker compose -f deploy/docker-compose.yml down -v
    Write-Success "已停止所有服务并清理数据卷"
}

# ==================== 主流程 ====================
function Main {
    Write-Banner
    
    # 解析参数
    param($args)
    switch ($args[0]) {
        "status" {
            docker compose -f deploy/docker-compose.yml ps
            return
        }
        "logs" {
            docker compose -f deploy/docker-compose.yml logs -f --tail=100
            return
        }
        "stop" {
            docker compose -f deploy/docker-compose.yml down
            Write-Success "已停止所有服务"
            return
        }
        "restart" {
            docker compose -f deploy/docker-compose.yml restart
            Write-Success "已重启所有服务"
            return
        }
        "uninstall" {
            Invoke-Uninstall
            return
        }
        "help" {
            Write-Host @"
AI老年健康守护系统 - Windows 部署脚本

用法: .\setup.ps1 [命令]

命令:
  (无参数)    执行完整部署流程
  status      查看服务运行状态
  logs        实时查看服务日志
  stop        停止所有服务
  restart     重启所有服务
  uninstall   卸载系统（删除所有服务+数据卷）
  help        显示此帮助
"@
            return
        }
    }
    
    # 完整部署流程
    try {
        Test-Environment
        Initialize-Config
        Build-Images
        Start-Services
        Test-Deployment
        Show-Summary
        Create-Shortcut
    } catch {
        Write-Error "部署失败: $_"
        Write-Host $_.ScriptStackTrace
        
        $viewLog = Read-Host "`n是否查看 Docker 日志排查？(y/N)"
        if ($viewLog -eq 'y') {
            docker compose -f deploy/docker-compose.yml logs --tail=50
        }
        
        Pause
        exit 1
    }
    
    Write-Host ""
    Pause
}

# 以管理员权限运行时切换到项目目录
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
Set-Location $projectRoot

# 运行主流程
Main @args
