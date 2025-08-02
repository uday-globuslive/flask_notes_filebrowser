#!/bin/bash

# Azure Deployment Script for Flask Notes App
# Make this file executable: chmod +x deploy-azure.sh

set -e  # Exit on any error

echo "🚀 Starting Azure deployment for Flask Notes App..."

# Configuration (Update these values)
RESOURCE_GROUP="flask-notes-rg"
APP_NAME="flask-notes-app-$(whoami)"
DB_NAME="flask-notes-db"
LOCATION="East US"
DB_ADMIN="flaskadmin"
DB_PASSWORD="YourSecurePassword123!"
DOMAIN_NAME=""  # Set your domain here, e.g., "example.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    exit 1
fi

# Login check
print_status "Checking Azure login status..."
if ! az account show &> /dev/null; then
    print_warning "Not logged in to Azure. Starting login process..."
    az login
fi

# Create resource group
print_status "Creating resource group: $RESOURCE_GROUP"
az group create --name $RESOURCE_GROUP --location "$LOCATION" --output table

# Create PostgreSQL server
print_status "Creating PostgreSQL server: $DB_NAME"
az postgres flexible-server create \
  --resource-group $RESOURCE_GROUP \
  --name $DB_NAME \
  --location "$LOCATION" \
  --admin-user $DB_ADMIN \
  --admin-password "$DB_PASSWORD" \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --storage-size 32 \
  --version 13 \
  --output table

# Create database
print_status "Creating database: notesdb"
az postgres flexible-server db create \
  --resource-group $RESOURCE_GROUP \
  --server-name $DB_NAME \
  --database-name notesdb \
  --output table

# Configure firewall
print_status "Configuring firewall rules..."
az postgres flexible-server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --name $DB_NAME \
  --rule-name AllowAzure \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0 \
  --output table

# Create App Service Plan
print_status "Creating App Service Plan..."
az appservice plan create \
  --name flask-notes-plan \
  --resource-group $RESOURCE_GROUP \
  --sku B1 \
  --is-linux \
  --output table

# Create Web App
print_status "Creating Web App: $APP_NAME"
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan flask-notes-plan \
  --name $APP_NAME \
  --runtime "PYTHON|3.9" \
  --deployment-source-url https://github.com/uday-globuslive/flask_notes_filebrowser \
  --output table

# Configure app settings
print_status "Configuring application settings..."
DB_CONNECTION_STRING="postgresql://$DB_ADMIN:$DB_PASSWORD@$DB_NAME.postgres.database.azure.com:5432/notesdb"
SECRET_KEY=$(openssl rand -base64 32)

az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $APP_NAME \
  --settings \
    DATABASE_URL="$DB_CONNECTION_STRING" \
    SECRET_KEY="$SECRET_KEY" \
    FLASK_ENV="production" \
    UPLOAD_FOLDER="/tmp/uploads" \
    MAX_CONTENT_LENGTH="16777216" \
  --output table

# Set startup command
print_status "Setting startup command..."
az webapp config set \
  --resource-group $RESOURCE_GROUP \
  --name $APP_NAME \
  --startup-file "gunicorn --bind=0.0.0.0 --timeout 600 startup:app" \
  --output table

# Enable HTTPS only
print_status "Enabling HTTPS only..."
az webapp update \
  --resource-group $RESOURCE_GROUP \
  --name $APP_NAME \
  --https-only true \
  --output table

# Get the app URL
APP_URL=$(az webapp show --resource-group $RESOURCE_GROUP --name $APP_NAME --query defaultHostName --output tsv)

print_status "Deployment completed successfully! 🎉"
echo ""
echo "📋 Deployment Summary:"
echo "======================="
echo "🌐 App URL: https://$APP_URL"
echo "🗄️  Database: $DB_NAME.postgres.database.azure.com"
echo "📁 Resource Group: $RESOURCE_GROUP"
echo "🔧 App Service: $APP_NAME"
echo ""

if [ -n "$DOMAIN_NAME" ]; then
    print_status "Setting up custom domain: $DOMAIN_NAME"
    
    # Create DNS zone (if domain is specified)
    az network dns zone create \
      --resource-group $RESOURCE_GROUP \
      --name $DOMAIN_NAME \
      --output table
    
    # Get name servers
    print_status "DNS Name Servers (update these at your domain registrar):"
    az network dns zone show \
      --resource-group $RESOURCE_GROUP \
      --name $DOMAIN_NAME \
      --query nameServers \
      --output table
    
    print_warning "Please update your domain registrar with the above name servers."
    print_warning "Then run the domain configuration script after DNS propagation (24-48 hours)."
else
    print_warning "No domain specified. To set up a custom domain:"
    print_warning "1. Update DOMAIN_NAME variable in this script"
    print_warning "2. Run the script again"
fi

echo ""
print_status "Next steps:"
echo "1. 🔍 Check your app at: https://$APP_URL"
echo "2. 📊 Monitor logs: az webapp log tail --resource-group $RESOURCE_GROUP --name $APP_NAME"
echo "3. 🔧 Configure custom domain (if needed)"
echo "4. 📈 Set up monitoring and alerts"

print_status "Deployment script completed! 🚀"
