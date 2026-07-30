@echo off
REM ============================================================
REM AI 老年健康守护系统 - 前端一键部署入口 (Windows Batch)
REM 双击此文件可启动交互式部署向导
REM ============================================================

cd /d "%~dp0.."

echo.
echo ============================================================
echo    AI 老年健康守护系统 - 前端一键部署
echo ============================================================
echo.
echo 正在启动部署脚本...
echo.

REM 检查 PowerShell
where powershell >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [X] PowerShell 不可用，请确保系统安装了 PowerShell
    pause
    exit /b 1
)

REM 运行部署脚本
powershell -ExecutionPolicy Bypass -File "deploy\deploy.ps1" %*

if %ERRORLEVEL% neq 0 (
    echo.
    echo [X] 部署过程中出现错误
    pause
    exit /b %ERRORLEVEL%
)

pause
