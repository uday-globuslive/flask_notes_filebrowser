@echo off
REM Flask Notes App Setup Script for Windows (Using Base Python)

echo ============================================
echo Flask Notes App Setup (Base Python)
echo ============================================

REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.7+ from https://python.org
    pause
    exit /b 1
)

echo Python is installed, continuing setup...

REM Upgrade pip
echo Upgrading pip...
python -m pip install --upgrade pip --user

REM Install dependencies
echo Installing Python dependencies...
pip install -r requirements.txt --user
if %errorlevel% neq 0 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)

echo ============================================
echo Database Configuration
echo ============================================

REM Copy environment file if it doesn't exist
if not exist ".env" (
    if exist ".env.example" (
        echo Creating .env file from template...
        copy .env.example .env
        echo IMPORTANT: Check .env file configuration!
    ) else (
        echo Creating default .env file...
        echo SECRET_KEY=your-secret-key-change-this-in-production > .env
        echo # DATABASE_URL=postgresql://username:password@localhost:5432/notesdb >> .env
        echo FLASK_ENV=development >> .env
        echo FLASK_DEBUG=True >> .env
    )
) else (
    echo .env file already exists
)

REM Create upload directory
if not exist "uploads" (
    echo Creating uploads directory...
    mkdir uploads
)

REM Initialize database migration (only if migrations folder doesn't exist)
echo Setting up database...
if not exist "migrations" (
    echo Initializing Flask-Migrate...
    flask db init
    if %errorlevel% neq 0 (
        echo WARNING: Database initialization failed
    )
)

REM Create migration
echo Creating database migration...
flask db migrate -m "Initial migration"
if %errorlevel% neq 0 (
    echo NOTE: Migration creation failed - this is normal for first run
)

REM Apply migration
echo Applying database migration...
flask db upgrade
if %errorlevel% neq 0 (
    echo NOTE: Migration failed - database will be created when app starts
)

echo.
echo ============================================
echo Setup Complete!
echo ============================================
echo.
echo Application configured to use:
echo - SQLite database (for easy development)
echo - All dependencies installed in base Python
echo.
echo To run the application:
echo    python app.py
echo.
echo The application will be available at: http://localhost:5000
echo.
echo For PostgreSQL support:
echo 1. Install PostgreSQL
echo 2. Edit .env file and uncomment DATABASE_URL
echo 3. Install: pip install psycopg2-binary --user
echo.

pause
