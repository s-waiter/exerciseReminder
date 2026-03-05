@echo off
echo [SERVICE] Restarting DeskCare Backend Service on Remote Server...
"D:\jinzhan\Software\code\anaconda3\python.exe" remote_ops.py restart
echo.
echo [INFO] Service restart command executed.
pause