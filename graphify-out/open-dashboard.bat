@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

:: Script de lancement du dashboard Kased Graph Analytics
:: Démarre un serveur HTTP local et ouvre le navigateur

set "DIR=%~dp0"
set "DIR=%DIR:~0,-1%"

:: Chercher Python
set PYTHON=python
where %PYTHON% >nul 2>&1
if errorlevel 1 set PYTHON=py

:: Trouver un port libre
set PORT=8765
for /l %%p in (8765,1,8800) do (
    %PYTHON% -c "import socket; s=socket.socket(); s.bind(('',%%p)); s.close(); print(%%p)" >nul 2>&1
    if not errorlevel 1 (
        set PORT=%%p
        goto :found
    )
)
:found

echo.
echo  ==========================================
echo     Kased Graph Analytics Dashboard
echo  ==========================================
echo.
echo  Port:  http://localhost:%PORT%
echo  Dashboard: http://localhost:%PORT%/dashboard.html
echo.
echo  Arret: Ctrl+C
echo.

:: Demarrer le serveur et ouvrir le navigateur
%PYTHON% -m http.server %PORT% --directory "%DIR%" >nul 2>&1 &
timeout /t 2 >nul
start "" "http://localhost:%PORT%/dashboard.html"

endlocal
