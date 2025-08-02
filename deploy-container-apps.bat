@echo off
REM Azure Container Apps Deployment Script for Windows
REM This script deploys Flask Notes app to Azure Container Apps

echo 🚀 Starting Azure Container Apps deployment...

REM Configuration
set RESOURCE_GROUP=flask-notes-rg
set LOCATION=eastus
set ACR_NAME=flasknotesacr%RANDOM%
set APP_NAME=flask-notes-app
set ENV_NAME=flask-notes-env
set DB_NAME=flask-notes-db
set DB_ADMIN=flaskadmin
set DB_PASSWORD=YourSecurePassword123!

echo [INFO] Checking prerequisites...

REM Check Docker
docker --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker is not installed. Please install Docker first.
    exit /b 1
)

REM Check Azure CLI
az --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Azure CLI is not installed. Please install it first.
    exit /b 1
)

REM Check Azure login
echo [INFO] Checking Azure login status...
az account show >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Not logged in to Azure. Starting login process...
    az login
)

REM Install Container Apps extension
echo [INFO] Installing Container Apps extension...
az extension add --name containerapp --upgrade

REM Create resource group
echo [INFO] Creating resource group: %RESOURCE_GROUP%
az group create --name %RESOURCE_GROUP% --location %LOCATION% --output table

REM Create PostgreSQL database
echo [INFO] Creating PostgreSQL server: %DB_NAME%
az postgres flexible-server create ^
  --resource-group %RESOURCE_GROUP% ^
  --name %DB_NAME% ^
  --location %LOCATION% ^
  --admin-user %DB_ADMIN% ^
  --admin-password "%DB_PASSWORD%" ^
  --sku-name Standard_B1ms ^
  --tier Burstable ^
  --storage-size 32 ^
  --version 13 ^
  --output table

REM Create database
echo [INFO] Creating database: notesdb
az postgres flexible-server db create ^
  --resource-group %RESOURCE_GROUP% ^
  --server-name %DB_NAME% ^
  --database-name notesdb ^
  --output table

REM Configure firewall
echo [INFO] Configuring database firewall...
az postgres flexible-server firewall-rule create ^
  --resource-group %RESOURCE_GROUP% ^
  --name %DB_NAME% ^
  --rule-name AllowAzure ^
  --start-ip-address 0.0.0.0 ^
  --end-ip-address 0.0.0.0 ^
  --output table

REM Create Container Registry
echo [INFO] Creating Azure Container Registry: %ACR_NAME%
az acr create ^
  --resource-group %RESOURCE_GROUP% ^
  --name %ACR_NAME% ^
  --sku Basic ^
  --output table

REM Build and push container image
echo [INFO] Building container image...
az acr build ^
  --registry %ACR_NAME% ^
  --image flask-notes:latest ^
  --file Dockerfile ^
  . ^
  --output table

REM Create Container Apps environment
echo [INFO] Creating Container Apps environment: %ENV_NAME%
az containerapp env create ^
  --name %ENV_NAME% ^
  --resource-group %RESOURCE_GROUP% ^
  --location %LOCATION% ^
  --output table

REM Prepare environment variables
set DB_CONNECTION_STRING=postgresql://%DB_ADMIN%:%DB_PASSWORD%@%DB_NAME%.postgres.database.azure.com:5432/notesdb
set SECRET_KEY=your-super-secret-key-change-this-in-production

REM Deploy Container App
echo [INFO] Creating container app: %APP_NAME%
az containerapp create ^
  --name %APP_NAME% ^
  --resource-group %RESOURCE_GROUP% ^
  --environment %ENV_NAME% ^
  --image %ACR_NAME%.azurecr.io/flask-notes:latest ^
  --target-port 8000 ^
  --ingress external ^
  --min-replicas 1 ^
  --max-replicas 5 ^
  --cpu 0.5 ^
  --memory 1Gi ^
  --env-vars ^
    FLASK_ENV=production ^
    DATABASE_URL="%DB_CONNECTION_STRING%" ^
    SECRET_KEY="%SECRET_KEY%" ^
    UPLOAD_FOLDER="/app/uploads" ^
    MAX_CONTENT_LENGTH="16777216" ^
  --output table

REM Get application URL
for /f %%i in ('az containerapp show --name %APP_NAME% --resource-group %RESOURCE_GROUP% --query properties.configuration.ingress.fqdn --output tsv') do set APP_URL=%%i

echo.
echo ========================================
echo   🎉 Deployment completed successfully!
echo ========================================
echo.
echo 📋 Deployment Summary:
echo =======================
echo 🌐 App URL: https://%APP_URL%
echo 🗄️  Database: %DB_NAME%.postgres.database.azure.com
echo 🐳 Container Registry: %ACR_NAME%.azurecr.io
echo 📁 Resource Group: %RESOURCE_GROUP%
echo 🚀 Container App: %APP_NAME%
echo.
echo 💰 Estimated Monthly Cost: ~$43
echo    - Container App: ~$25
echo    - PostgreSQL B1ms: ~$12
echo    - Container Registry: ~$5
echo    - DNS: ~$0.50
echo.
echo 📌 Next Steps:
echo 1. 🔍 Test your app: https://%APP_URL%
echo 2. 📊 Monitor logs: az containerapp logs show --name %APP_NAME% --resource-group %RESOURCE_GROUP% --follow
echo 3. 🔧 Scale app: az containerapp update --name %APP_NAME% --resource-group %RESOURCE_GROUP% --min-replicas 2
echo 4. 🌐 Add custom domain ^(if needed^)
echo 5. 📈 Set up monitoring and alerts
echo.

REM Save deployment info
echo Flask Notes App - Container Apps Deployment > deployment-info.txt
echo ========================================== >> deployment-info.txt
echo Deployment Date: %DATE% %TIME% >> deployment-info.txt
echo Resource Group: %RESOURCE_GROUP% >> deployment-info.txt
echo App Name: %APP_NAME% >> deployment-info.txt
echo App URL: https://%APP_URL% >> deployment-info.txt
echo Database: %DB_NAME%.postgres.database.azure.com >> deployment-info.txt
echo Container Registry: %ACR_NAME%.azurecr.io >> deployment-info.txt
echo. >> deployment-info.txt
echo Useful Commands: >> deployment-info.txt
echo - View logs: az containerapp logs show --name %APP_NAME% --resource-group %RESOURCE_GROUP% --follow >> deployment-info.txt
echo - Scale app: az containerapp update --name %APP_NAME% --resource-group %RESOURCE_GROUP% --min-replicas 2 --max-replicas 10 >> deployment-info.txt
echo - Update image: az containerapp update --name %APP_NAME% --resource-group %RESOURCE_GROUP% --image %ACR_NAME%.azurecr.io/flask-notes:latest >> deployment-info.txt
echo - Delete deployment: az group delete --name %RESOURCE_GROUP% --yes >> deployment-info.txt

echo [INFO] Deployment information saved to deployment-info.txt
echo [INFO] Container Apps deployment completed successfully! 🚀
pause
