@echo off
REM Azure Deployment Script for Flask Notes App (Windows)
REM Run this from PowerShell or Command Prompt

echo 🚀 Starting Azure deployment for Flask Notes App...

REM Configuration (Update these values)
set RESOURCE_GROUP=flask-notes-rg
set APP_NAME=flask-notes-app-%USERNAME%
set DB_NAME=flask-notes-db
set LOCATION=East US
set DB_ADMIN=flaskadmin
set DB_PASSWORD=YourSecurePassword123!
set DOMAIN_NAME=

echo [INFO] Checking Azure CLI installation...
az --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Azure CLI is not installed. Please install it first.
    exit /b 1
)

echo [INFO] Checking Azure login status...
az account show >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Not logged in to Azure. Starting login process...
    az login
)

echo [INFO] Creating resource group: %RESOURCE_GROUP%
az group create --name %RESOURCE_GROUP% --location "%LOCATION%" --output table

echo [INFO] Creating PostgreSQL server: %DB_NAME%
az postgres flexible-server create ^
  --resource-group %RESOURCE_GROUP% ^
  --name %DB_NAME% ^
  --location "%LOCATION%" ^
  --admin-user %DB_ADMIN% ^
  --admin-password "%DB_PASSWORD%" ^
  --sku-name Standard_B1ms ^
  --tier Burstable ^
  --storage-size 32 ^
  --version 13 ^
  --output table

echo [INFO] Creating database: notesdb
az postgres flexible-server db create ^
  --resource-group %RESOURCE_GROUP% ^
  --server-name %DB_NAME% ^
  --database-name notesdb ^
  --output table

echo [INFO] Configuring firewall rules...
az postgres flexible-server firewall-rule create ^
  --resource-group %RESOURCE_GROUP% ^
  --name %DB_NAME% ^
  --rule-name AllowAzure ^
  --start-ip-address 0.0.0.0 ^
  --end-ip-address 0.0.0.0 ^
  --output table

echo [INFO] Creating App Service Plan...
az appservice plan create ^
  --name flask-notes-plan ^
  --resource-group %RESOURCE_GROUP% ^
  --sku B1 ^
  --is-linux ^
  --output table

echo [INFO] Creating Web App: %APP_NAME%
az webapp create ^
  --resource-group %RESOURCE_GROUP% ^
  --plan flask-notes-plan ^
  --name %APP_NAME% ^
  --runtime "PYTHON|3.9" ^
  --deployment-source-url https://github.com/uday-globuslive/flask_notes_filebrowser ^
  --output table

echo [INFO] Configuring application settings...
set DB_CONNECTION_STRING=postgresql://%DB_ADMIN%:%DB_PASSWORD%@%DB_NAME%.postgres.database.azure.com:5432/notesdb

REM Generate a random secret key (simplified for Windows)
set SECRET_KEY=your-super-secret-key-change-this-in-production

az webapp config appsettings set ^
  --resource-group %RESOURCE_GROUP% ^
  --name %APP_NAME% ^
  --settings ^
    DATABASE_URL="%DB_CONNECTION_STRING%" ^
    SECRET_KEY="%SECRET_KEY%" ^
    FLASK_ENV="production" ^
    UPLOAD_FOLDER="/tmp/uploads" ^
    MAX_CONTENT_LENGTH="16777216" ^
  --output table

echo [INFO] Setting startup command...
az webapp config set ^
  --resource-group %RESOURCE_GROUP% ^
  --name %APP_NAME% ^
  --startup-file "gunicorn --bind=0.0.0.0 --timeout 600 startup:app" ^
  --output table

echo [INFO] Enabling HTTPS only...
az webapp update ^
  --resource-group %RESOURCE_GROUP% ^
  --name %APP_NAME% ^
  --https-only true ^
  --output table

echo [INFO] Getting app URL...
for /f %%i in ('az webapp show --resource-group %RESOURCE_GROUP% --name %APP_NAME% --query defaultHostName --output tsv') do set APP_URL=%%i

echo.
echo ========================================
echo   🎉 Deployment completed successfully!
echo ========================================
echo.
echo 📋 Deployment Summary:
echo =======================
echo 🌐 App URL: https://%APP_URL%
echo 🗄️  Database: %DB_NAME%.postgres.database.azure.com
echo 📁 Resource Group: %RESOURCE_GROUP%
echo 🔧 App Service: %APP_NAME%
echo.
echo 📌 Next steps:
echo 1. 🔍 Check your app at: https://%APP_URL%
echo 2. 📊 Monitor logs: az webapp log tail --resource-group %RESOURCE_GROUP% --name %APP_NAME%
echo 3. 🔧 Configure custom domain (see AZURE_DEPLOYMENT.md)
echo 4. 📈 Set up monitoring and alerts
echo.
echo [INFO] Deployment script completed! 🚀
pause
