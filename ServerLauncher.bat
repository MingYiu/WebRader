@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo.
echo  ============================================================
echo           CS2 Web Radar Server v2.0 (Node.js)
echo  ============================================================
echo.
echo  WebSocket Real-time Mode (~30 FPS)
echo.
echo  ============================================================

REM Check Node.js
where node >nul 2>&1
if errorlevel 1 (
    echo  [ERROR] Node.js not found!
    echo  Please install Node.js: https://nodejs.org/
    pause
    exit /b 1
)

REM Check npm
where npm >nul 2>&1
if errorlevel 1 (
    echo  [ERROR] npm not found!
    pause
    exit /b 1
)

echo  [1/3] Checking dependencies...
if not exist "node_modules" (
    echo         First run, installing dependencies...
    npm install
)

echo.
echo  [2/3] Starting server...
echo.
echo  Open browser and visit:
echo    - Radar page:     http://localhost:8080
echo    - Debug tool:     http://localhost:8080/coordinate_tool.html
echo.
echo  WebSocket port: ws://localhost:8765
echo  UDP port:       127.0.0.1:12345
echo.
echo  Press Ctrl+C to stop server
echo.

node server.js

pause
