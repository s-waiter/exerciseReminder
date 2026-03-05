@echo off
echo [SERVICE] Stopping DeskCare Backend Service on Remote Server...
"D:\jinzhan\Software\code\anaconda3\python.exe" remote_ops.py stop
echo.
echo [INFO] Service stop command executed.
pause