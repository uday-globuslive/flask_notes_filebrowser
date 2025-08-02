@echo off
REM Quick start script for Flask Notes App (Base Python)

echo Starting Flask Notes App...

REM Check if .env file exists
if not exist ".env" (
    echo ERROR: .env file not found!
    echo Please run setup-base-python.bat first
    pause
    exit /b 1
)

REM Check if uploads directory exists
if not exist "uploads" (
    echo Creating uploads directory...
    mkdir uploads
)

REM Start the application
echo Starting Flask application...
echo Application will be available at: http://localhost:5000
echo Press Ctrl+C to stop the application
echo.

python app.py

pause
