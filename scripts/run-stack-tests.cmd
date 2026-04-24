@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-stack-tests.ps1" %*
exit /b %errorlevel%
