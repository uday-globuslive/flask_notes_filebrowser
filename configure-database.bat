@echo off
REM Database Configuration Script for Windows
REM This script helps users easily switch between SQLite and PostgreSQL

setlocal enabledelayedexpansion

echo ================================
echo  Flask Notes Database Config
echo ================================
echo.

REM Function to setup SQLite
:setup_sqlite
echo [INFO] Setting up SQLite Database...
echo.

REM Copy SQLite environment file
if exist ".env.sqlite" (
    copy ".env.sqlite" ".env" >nul
    echo [INFO] ✅ Copied SQLite configuration to .env
) else (
    echo [ERROR] ❌ .env.sqlite file not found!
    goto :error_exit
)

REM Create instance directory
if not exist "instance" mkdir instance
echo [INFO] 📁 Created instance directory for SQLite database

REM Initialize database
echo [INFO] 🔧 Initializing SQLite database...
python -c "from app import app, db; app.app_context().push(); db.create_all(); print('✅ SQLite database initialized successfully!')"

if %ERRORLEVEL% EQU 0 (
    echo [INFO] 🎉 SQLite setup complete!
    echo Your app is now configured to use SQLite database at: instance/notes_app.db
) else (
    echo [ERROR] ❌ Failed to initialize SQLite database
    goto :error_exit
)
goto :menu

REM Function to setup PostgreSQL
:setup_postgresql
echo [INFO] Setting up PostgreSQL Database...
echo.

REM Check if psql is available
psql --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] PostgreSQL client not found. Please install PostgreSQL first.
    echo Install from: https://www.postgresql.org/download/
    echo.
)

REM Copy PostgreSQL environment file
if exist ".env.postgresql" (
    copy ".env.postgresql" ".env" >nul
    echo [INFO] ✅ Copied PostgreSQL configuration to .env
) else (
    echo [ERROR] ❌ .env.postgresql file not found!
    goto :error_exit
)

REM Get database details from user
echo Please provide PostgreSQL connection details:
set /p PG_HOST="Host (default: localhost): "
set /p PG_PORT="Port (default: 5432): "
set /p PG_USER="Username (default: postgres): "
set /p PG_PASS="Password: "
set /p PG_DB="Database name (default: notesdb): "

REM Use defaults if empty
if "%PG_HOST%"=="" set PG_HOST=localhost
if "%PG_PORT%"=="" set PG_PORT=5432
if "%PG_USER%"=="" set PG_USER=postgres
if "%PG_DB%"=="" set PG_DB=notesdb

REM Update .env file (simplified version for Windows)
echo # PostgreSQL Configuration > .env.temp
echo DATABASE_TYPE=postgresql >> .env.temp
echo POSTGRES_HOST=%PG_HOST% >> .env.temp
echo POSTGRES_PORT=%PG_PORT% >> .env.temp
echo POSTGRES_USER=%PG_USER% >> .env.temp
echo POSTGRES_PASSWORD=%PG_PASS% >> .env.temp
echo POSTGRES_DB=%PG_DB% >> .env.temp
echo SECRET_KEY=dev-secret-key-change-in-production >> .env.temp
echo FLASK_ENV=development >> .env.temp
echo UPLOAD_FOLDER=uploads >> .env.temp
echo MAX_CONTENT_LENGTH=16777216 >> .env.temp

move .env.temp .env >nul
echo [INFO] ✅ Updated PostgreSQL configuration

REM Test connection and initialize database
echo [INFO] 🔧 Testing PostgreSQL connection and initializing database...
set PGPASSWORD=%PG_PASS%
createdb -h %PG_HOST% -p %PG_PORT% -U %PG_USER% %PG_DB% 2>nul

python -c "from app import app, db; app.app_context().push(); db.create_all(); print('✅ PostgreSQL database initialized successfully!')"

if %ERRORLEVEL% EQU 0 (
    echo [INFO] 🎉 PostgreSQL setup complete!
    echo Your app is now configured to use PostgreSQL database at: %PG_USER%@%PG_HOST%:%PG_PORT%/%PG_DB%
) else (
    echo [ERROR] ❌ Failed to initialize PostgreSQL database
    goto :error_exit
)
goto :menu

REM Function to show current configuration
:show_config
echo ================================
echo  Current Database Configuration
echo ================================
echo.

if exist ".env" (
    echo Current .env file contents:
    echo ==========================
    findstr /R "DATABASE_TYPE DATABASE_URL POSTGRES_ SQLITE_" .env 2>nul
    echo.
    
    findstr /C:"DATABASE_TYPE=sqlite" .env >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo ✅ Currently configured for: SQLite
    ) else (
        findstr /C:"DATABASE_TYPE=postgresql" .env >nul 2>&1
        if %ERRORLEVEL% EQU 0 (
            echo ✅ Currently configured for: PostgreSQL
        ) else (
            echo ⚠️  Database type not explicitly set
        )
    )
) else (
    echo ⚠️  No .env file found. Database will use defaults.
)
echo.
goto :menu

REM Function to test database connection
:test_connection
echo ================================
echo  Testing Database Connection
echo ================================
echo.

echo [INFO] 🔧 Testing database connection...
python -c "from app import app, db; from sqlalchemy import inspect; app.app_context().push(); db.engine.execute('SELECT 1'); print('✅ Database connection successful!'); inspector = inspect(db.engine); tables = inspector.get_table_names(); print(f'📊 Found {len(tables)} tables: {tables}')"

if %ERRORLEVEL% EQU 0 (
    echo [INFO] Database connection test passed!
) else (
    echo [ERROR] Database connection test failed!
)
echo.
goto :menu

REM Main menu
:menu
echo.
echo Choose an option:
echo 1. Setup SQLite database (recommended for development)
echo 2. Setup PostgreSQL database (recommended for production)
echo 3. Show current configuration
echo 4. Test database connection
echo 5. Exit
echo.

set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" goto :setup_sqlite
if "%choice%"=="2" goto :setup_postgresql
if "%choice%"=="3" goto :show_config
if "%choice%"=="4" goto :test_connection
if "%choice%"=="5" goto :exit

echo [ERROR] Invalid choice. Please try again.
goto :menu

:error_exit
echo.
echo [ERROR] Configuration failed. Please check the errors above.
pause
exit /b 1

:exit
echo Goodbye!
pause
exit /b 0
