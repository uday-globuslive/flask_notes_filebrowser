@echo off
REM Flask Notes App Setup Script for Windows

echo ============================================
echo Flask Notes App Setup
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

REM Create virtual environment if it doesn't exist
if not exist "venv" (
    echo Creating virtual environment...
    python -m venv venv
    if %errorlevel% neq 0 (
        echo ERROR: Failed to create virtual environment
        pause
        exit /b 1
    )
) else (
    echo Virtual environment already exists
)

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo ERROR: Failed to activate virtual environment
    pause
    exit /b 1
)

REM Upgrade pip
echo Upgrading pip...
python -m pip install --upgrade pip

REM Install basic dependencies (without PostgreSQL)
echo Installing basic Python dependencies...
pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo ERROR: Failed to install basic dependencies
    pause
    exit /b 1
)

REM Ask user about PostgreSQL
echo.
echo ============================================
echo Database Configuration
echo ============================================
echo.
set /p USE_POSTGRES="Do you want to use PostgreSQL? (y/n, default=n): "
if /i "%USE_POSTGRES%"=="y" (
    echo Installing PostgreSQL support...
    pip install psycopg2-binary==2.9.9
    if %errorlevel% neq 0 (
        echo WARNING: Failed to install PostgreSQL support
        echo You can use SQLite instead or install PostgreSQL manually later
        echo To install PostgreSQL support later, run: pip install psycopg2-binary
    ) else (
        echo PostgreSQL support installed successfully!
    )
) else (
    echo Skipping PostgreSQL installation - using SQLite database
)

REM Copy environment file if it doesn't exist
if not exist ".env" (
    if exist ".env.example" (
        echo Creating .env file from template...
        copy .env.example .env
        echo IMPORTANT: Please edit .env file with your database credentials!
    ) else (
        echo Creating default .env file...
        echo SECRET_KEY=your-secret-key-change-this-in-production-please-change-this > .env
        echo # DATABASE_URL=postgresql://username:password@localhost:5432/notesdb >> .env
        echo FLASK_ENV=development >> .env
        echo FLASK_DEBUG=True >> .env
        echo. >> .env
        echo # Remove the # from DATABASE_URL line above if using PostgreSQL >> .env
        echo # Leave it commented to use SQLite database >> .env
    )
) else (
    echo .env file already exists
)

REM Create upload directory
if not exist "uploads" (
    echo Creating uploads directory...
    mkdir uploads
)

REM Initialize database migration
echo Setting up database...
if not exist "migrations" (
    echo Initializing Flask-Migrate...
    flask db init
    if %errorlevel% neq 0 (
        echo WARNING: Database initialization failed
        echo This is normal if you haven't set up the database yet
    )
)

REM Create migration
echo Creating database migration...
flask db migrate -m "Initial migration"
if %errorlevel% neq 0 (
    echo WARNING: Migration creation failed
    echo This will be resolved when you run the app for the first time
)

REM Apply migration
echo Applying database migration...
flask db upgrade
if %errorlevel% neq 0 (
    echo WARNING: Migration failed
    echo The database will be created when you run the app for the first time
)

echo.
echo ============================================
echo Setup Complete!
echo ============================================
echo.
echo Next steps:
if /i "%USE_POSTGRES%"=="y" (
    echo 1. Install PostgreSQL from: https://www.postgresql.org/download/
    echo 2. Create database: psql -U postgres -c "CREATE DATABASE notesdb;"
    echo 3. Edit .env file with your PostgreSQL credentials
) else (
    echo 1. SQLite database will be created automatically
    echo 2. You can edit .env file to customize settings
)
echo.
echo To run the application:
echo    1. Double-click run.bat, OR
echo    2. Open Command Prompt and run:
echo       - venv\Scripts\activate
echo       - python app.py
echo.
echo The application will be available at: http://localhost:5000
echo.

pause
