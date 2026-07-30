@echo off
chcp 65001 >nul
title AI老年健康守护系统 - 一键部署

echo.
echo   ╔═══════════════════════════════════════════════════════╗
echo   ║        AI 老年健康守护系统 — 一键部署启动器         ║
echo   ╚═══════════════════════════════════════════════════════╝
echo.
echo   本脚本将自动调用 PowerShell 执行完整部署流程...
echo.

REM 检查是否以管理员权限运行
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [提示] 建议以管理员身份运行以获得最佳体验
    echo.
)

REM 切换到脚本所在目录
cd /d "%~dp0\.."

REM 运行 PowerShell 部署脚本
powershell -ExecutionPolicy Bypass -File "%~dp0setup.ps1"

if %errorlevel% neq 0 (
    echo.
    echo [失败] 部署过程出现错误，请查看上方日志
    pause
    exit /b 1
)

pause
