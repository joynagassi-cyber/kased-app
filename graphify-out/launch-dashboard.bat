@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

:: Find Python
set PYTHON=python
where %PYTHON% >nul 2>&1
if errorlevel 1 set PYTHON=py

:: Get script directory
set "DIR=%~dp0"
set "DIR=%DIR:~0,-1%"

:: Start HTTP server on a free port
for /l %%p in (8765,1,8800) do (
    %PYTHON% -c "import socket; s=socket.socket(); s.bind(('',%%p)); s.close(); print(%%p)" >nul 2>&1
    if not errorlevel 1 (
        set PORT=%%p
        goto :found
    )
)
set PORT=8765
:found

echo Starting Kased Graph Analytics Dashboard...
echo Open http://localhost:%PORT%/dashboard.html in your browser
echo.
echo Press Ctrl+C to stop the server
echo.

:: Start server in background and open browser
start "" %PYTHON% -m http.server %PORT% --directory "%DIR%"
timeout /t 2 >nul
start "" "http://localhost:%PORT%/dashboard.html"

endlocal
