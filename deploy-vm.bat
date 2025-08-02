@echo off
REM Azure VM Deployment Script for Flask Notes App (Windows)
REM This script automates the VM deployment process

setlocal enabledelayedexpansion

REM Configuration
set RESOURCE_GROUP=flask-vm-rg
set VM_NAME=flask-notes-vm
set LOCATION=East US
set VM_SIZE=Standard_B1s
set ADMIN_USER=azureuser
set SSH_KEY_PATH=%USERPROFILE%\.ssh\azure_vm_key
set DOMAIN_NAME=

echo ================================
echo  Azure VM Deployment for Flask Notes
echo ================================
echo.

REM Check Azure CLI
echo [INFO] Checking Azure CLI installation...
az --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Azure CLI not found. Please install it first.
    exit /b 1
)

REM Check login
echo [INFO] Checking Azure login status...
az account show >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Not logged in to Azure. Starting login...
    az login
)

REM Get domain name from user
set /p DOMAIN_NAME="Enter domain name (optional, press Enter to skip): "

REM Generate SSH key if needed
echo [INFO] Setting up SSH key...
if not exist "%SSH_KEY_PATH%" (
    echo [INFO] Generating SSH key pair...
    ssh-keygen -t rsa -b 4096 -f "%SSH_KEY_PATH%" -N ""
    echo [INFO] SSH key generated at %SSH_KEY_PATH%
) else (
    echo [INFO] SSH key already exists at %SSH_KEY_PATH%
)

REM Create resource group
echo [INFO] Creating resource group: %RESOURCE_GROUP%
az group create --name %RESOURCE_GROUP% --location "%LOCATION%" --output table

REM Create VM
echo [INFO] Creating virtual machine: %VM_NAME%
az vm create ^
    --resource-group %RESOURCE_GROUP% ^
    --name %VM_NAME% ^
    --image Ubuntu2204 ^
    --size %VM_SIZE% ^
    --admin-username %ADMIN_USER% ^
    --ssh-key-values "%SSH_KEY_PATH%.pub" ^
    --public-ip-sku Standard ^
    --output table

REM Get VM IP
for /f %%i in ('az vm show -d -g %RESOURCE_GROUP% -n %VM_NAME% --query publicIps -o tsv') do set VM_IP=%%i
echo [INFO] VM created with public IP: %VM_IP%
echo %VM_IP% > vm_ip.txt

REM Configure network security
echo [INFO] Configuring network security...
az vm open-port --resource-group %RESOURCE_GROUP% --name %VM_NAME% --port 80 --priority 1000
az vm open-port --resource-group %RESOURCE_GROUP% --name %VM_NAME% --port 443 --priority 1001
az vm open-port --resource-group %RESOURCE_GROUP% --name %VM_NAME% --port 22 --priority 1002

echo [INFO] Waiting for VM to be ready...
timeout /t 30 /nobreak >nul

REM Create setup script for VM
echo [INFO] Creating VM setup script...
(
echo #!/bin/bash
echo set -e
echo echo "🔧 Installing Docker and dependencies..."
echo.
echo # Update system
echo sudo apt update ^&^& sudo apt upgrade -y
echo.
echo # Install Docker dependencies
echo sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
echo.
echo # Add Docker GPG key
echo curl -fsSL https://download.docker.com/linux/ubuntu/gpg ^| sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo.
echo # Add Docker repository
echo echo "deb [arch=$(dpkg --print-architecture^) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs^) stable" ^| sudo tee /etc/apt/sources.list.d/docker.list ^> /dev/null
echo.
echo # Install Docker
echo sudo apt update
echo sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
echo.
echo # Add user to docker group
echo sudo usermod -aG docker $USER
echo.
echo # Start Docker
echo sudo systemctl start docker
echo sudo systemctl enable docker
echo.
echo # Install Docker Compose
echo sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s^)-$(uname -m^)" -o /usr/local/bin/docker-compose
echo sudo chmod +x /usr/local/bin/docker-compose
echo.
echo # Install Nginx and Certbot
echo sudo apt install -y nginx certbot python3-certbot-nginx
echo.
echo echo "✅ Docker and Nginx installed successfully!"
) > setup-vm.sh

REM Create deployment script for VM
(
echo #!/bin/bash
echo set -e
echo echo "📦 Deploying Flask Notes App..."
echo.
echo # Clone repository
echo if [ -d "flask_notes_filebrowser" ]; then
echo     cd flask_notes_filebrowser
echo     git pull
echo else
echo     git clone https://github.com/uday-globuslive/flask_notes_filebrowser.git
echo     cd flask_notes_filebrowser
echo fi
echo.
echo # Generate secure passwords
echo POSTGRES_PASSWORD=$(openssl rand -base64 32^)
echo SECRET_KEY=$(openssl rand -base64 32^)
echo.
echo # Create production environment file
echo cat ^> .env ^<^< EOF
echo DATABASE_TYPE=postgresql
echo POSTGRES_HOST=postgres
echo POSTGRES_PORT=5432
echo POSTGRES_USER=flaskuser
echo POSTGRES_PASSWORD=$POSTGRES_PASSWORD
echo POSTGRES_DB=notesdb
echo SECRET_KEY=$SECRET_KEY
echo FLASK_ENV=production
echo UPLOAD_FOLDER=/app/uploads
echo MAX_CONTENT_LENGTH=16777216
echo EOF
echo.
echo # Start application
echo docker-compose down 2^>/dev/null ^|^| true
echo docker-compose up -d
echo.
echo # Wait and check status
echo sleep 10
echo docker-compose ps
echo.
echo echo "✅ Application deployed successfully!"
echo echo "🌐 App is running at: http://$(curl -s ifconfig.me^):8000"
) > deploy-app.sh

REM Copy scripts to VM and execute
echo [INFO] Installing Docker on VM...
scp -i "%SSH_KEY_PATH%" -o StrictHostKeyChecking=no setup-vm.sh %ADMIN_USER%@%VM_IP%:~/
ssh -i "%SSH_KEY_PATH%" -o StrictHostKeyChecking=no %ADMIN_USER%@%VM_IP% "chmod +x setup-vm.sh && ./setup-vm.sh"

echo [INFO] Deploying application...
scp -i "%SSH_KEY_PATH%" -o StrictHostKeyChecking=no deploy-app.sh %ADMIN_USER%@%VM_IP%:~/
ssh -i "%SSH_KEY_PATH%" -o StrictHostKeyChecking=no %ADMIN_USER%@%VM_IP% "chmod +x deploy-app.sh && ./deploy-app.sh"

REM Configure Nginx if domain provided
if not "%DOMAIN_NAME%"=="" (
    echo [INFO] Configuring Nginx for domain: %DOMAIN_NAME%
    
    (
    echo #!/bin/bash
    echo sudo tee /etc/nginx/sites-available/flask-notes ^<^< EOF
    echo server {
    echo     listen 80;
    echo     server_name %DOMAIN_NAME% www.%DOMAIN_NAME%;
    echo.
    echo     location / {
    echo         proxy_pass http://localhost:8000;
    echo         proxy_set_header Host \$host;
    echo         proxy_set_header X-Real-IP \$remote_addr;
    echo         proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    echo         proxy_set_header X-Forwarded-Proto \$scheme;
    echo     }
    echo.
    echo     client_max_body_size 16M;
    echo }
    echo EOF
    echo.
    echo sudo ln -sf /etc/nginx/sites-available/flask-notes /etc/nginx/sites-enabled/
    echo sudo rm -f /etc/nginx/sites-enabled/default
    echo sudo nginx -t
    echo sudo systemctl restart nginx
    echo sudo systemctl enable nginx
    echo echo "✅ Nginx configured for %DOMAIN_NAME%"
    ) > configure-nginx.sh
    
    scp -i "%SSH_KEY_PATH%" -o StrictHostKeyChecking=no configure-nginx.sh %ADMIN_USER%@%VM_IP%:~/
    ssh -i "%SSH_KEY_PATH%" -o StrictHostKeyChecking=no %ADMIN_USER%@%VM_IP% "chmod +x configure-nginx.sh && ./configure-nginx.sh"
    
    REM Setup DNS zone
    set /p create_dns="Create DNS zone in Azure? (y/N): "
    if /i "!create_dns!"=="y" (
        echo [INFO] Creating DNS zone for: %DOMAIN_NAME%
        az network dns zone create --resource-group %RESOURCE_GROUP% --name %DOMAIN_NAME% --output table
        az network dns record-set a add-record --resource-group %RESOURCE_GROUP% --zone-name %DOMAIN_NAME% --record-set-name @ --ipv4-address %VM_IP% --output table
        az network dns record-set cname set-record --resource-group %RESOURCE_GROUP% --zone-name %DOMAIN_NAME% --record-set-name www --cname %DOMAIN_NAME% --output table
        
        echo [INFO] DNS zone created. Update your domain registrar with these name servers:
        az network dns zone show --resource-group %RESOURCE_GROUP% --name %DOMAIN_NAME% --query nameServers --output table
        
        echo.
        echo [WARNING] Please update your domain's name servers before continuing with SSL setup
        pause
        
        REM Setup SSL
        echo [INFO] Setting up SSL certificate...
        (
        echo #!/bin/bash
        echo sudo certbot --nginx -d %DOMAIN_NAME% -d www.%DOMAIN_NAME% --non-interactive --agree-tos --email admin@%DOMAIN_NAME%
        echo echo "0 12 * * *" /usr/bin/certbot renew --quiet ^| sudo crontab -
        echo echo "✅ SSL certificate installed for %DOMAIN_NAME%"
        ) > setup-ssl.sh
        
        scp -i "%SSH_KEY_PATH%" -o StrictHostKeyChecking=no setup-ssl.sh %ADMIN_USER%@%VM_IP%:~/
        ssh -i "%SSH_KEY_PATH%" -o StrictHostKeyChecking=no %ADMIN_USER%@%VM_IP% "chmod +x setup-ssl.sh && ./setup-ssl.sh"
    )
)

REM Cleanup temporary files
del setup-vm.sh deploy-app.sh configure-nginx.sh setup-ssl.sh 2>nul

REM Display summary
echo.
echo ========================================
echo   🎉 Deployment completed successfully!
echo ========================================
echo.
echo 📋 Deployment Details:
echo    🖥️  VM Name: %VM_NAME%
echo    🌐 Public IP: %VM_IP%
echo    👤 SSH User: %ADMIN_USER%
echo    🔑 SSH Key: %SSH_KEY_PATH%

if not "%DOMAIN_NAME%"=="" (
    echo    🌍 Domain: https://%DOMAIN_NAME%
    echo    🌍 Alt URL: https://www.%DOMAIN_NAME%
) else (
    echo    🌍 App URL: http://%VM_IP%
)

echo.
echo 📊 Estimated Monthly Cost: ~$7.50 (B1s^) or ~$15 (B2s^)
echo.
echo 🔧 Management Commands:
echo    SSH into VM: ssh -i "%SSH_KEY_PATH%" %ADMIN_USER%@%VM_IP%
echo    View logs: docker-compose logs -f flask-app
echo    Restart app: docker-compose restart
echo    Update app: git pull ^&^& docker-compose up -d --build
echo.
echo 🗑️  Cleanup Command:
echo    az group delete --name %RESOURCE_GROUP% --yes

REM Save deployment info
(
echo Flask Notes App - Azure VM Deployment
echo ====================================
echo Deployment Date: %DATE% %TIME%
echo Resource Group: %RESOURCE_GROUP%
echo VM Name: %VM_NAME%
echo Public IP: %VM_IP%
echo SSH User: %ADMIN_USER%
echo SSH Key: %SSH_KEY_PATH%
echo Domain: %DOMAIN_NAME%
echo.
echo Management Commands:
echo - SSH: ssh -i "%SSH_KEY_PATH%" %ADMIN_USER%@%VM_IP%
echo - Logs: docker-compose logs -f flask-app
echo - Restart: docker-compose restart
echo - Update: git pull ^&^& docker-compose up -d --build
echo - Cleanup: az group delete --name %RESOURCE_GROUP% --yes
) > deployment-info.txt

echo [INFO] Deployment information saved to deployment-info.txt
echo [INFO] Azure VM deployment completed successfully! 🚀
pause
