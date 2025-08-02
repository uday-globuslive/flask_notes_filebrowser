#!/bin/bash

# Azure Container Apps Deployment Script
# This script deploys Flask Notes app to Azure Container Apps

set -e

# Configuration
RESOURCE_GROUP="flask-notes-rg"
LOCATION="eastus"
ACR_NAME="flasknotesacr$(date +%s)"  # Add timestamp for uniqueness
APP_NAME="flask-notes-app"
ENV_NAME="flask-notes-env"
DB_NAME="flask-notes-db"
DB_ADMIN="flaskadmin"
DB_PASSWORD="YourSecurePassword123!"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} $1 ${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Check prerequisites
print_header "Checking Prerequisites"

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check Azure CLI
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if logged in
print_status "Checking Azure login status..."
if ! az account show &> /dev/null; then
    print_warning "Not logged in to Azure. Starting login process..."
    az login
fi

# Install Container Apps extension
print_status "Installing Container Apps extension..."
az extension add --name containerapp --upgrade

# Create resource group
print_header "Creating Azure Resources"
print_status "Creating resource group: $RESOURCE_GROUP"
az group create --name $RESOURCE_GROUP --location $LOCATION --output table

# Create PostgreSQL database
print_status "Creating PostgreSQL server: $DB_NAME"
az postgres flexible-server create \
  --resource-group $RESOURCE_GROUP \
  --name $DB_NAME \
  --location $LOCATION \
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
print_status "Configuring database firewall..."
az postgres flexible-server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --name $DB_NAME \
  --rule-name AllowAzure \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0 \
  --output table

# Create Container Registry
print_header "Setting Up Container Registry"
print_status "Creating Azure Container Registry: $ACR_NAME"
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Basic \
  --output table

# Build and push container image
print_header "Building and Pushing Container Image"
print_status "Building container image..."
az acr build \
  --registry $ACR_NAME \
  --image flask-notes:latest \
  --file Dockerfile \
  . \
  --output table

# Create Container Apps environment
print_header "Setting Up Container Apps Environment"
print_status "Creating Container Apps environment: $ENV_NAME"
az containerapp env create \
  --name $ENV_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --output table

# Prepare environment variables
DB_CONNECTION_STRING="postgresql://$DB_ADMIN:$DB_PASSWORD@$DB_NAME.postgres.database.azure.com:5432/notesdb"
SECRET_KEY=$(openssl rand -base64 32)

# Deploy Container App
print_header "Deploying Container App"
print_status "Creating container app: $APP_NAME"
az containerapp create \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $ENV_NAME \
  --image $ACR_NAME.azurecr.io/flask-notes:latest \
  --target-port 8000 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 5 \
  --cpu 0.5 \
  --memory 1Gi \
  --env-vars \
    FLASK_ENV=production \
    DATABASE_URL="$DB_CONNECTION_STRING" \
    SECRET_KEY="$SECRET_KEY" \
    UPLOAD_FOLDER="/app/uploads" \
    MAX_CONTENT_LENGTH="16777216" \
  --output table

# Get application URL
APP_URL=$(az containerapp show \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query properties.configuration.ingress.fqdn \
  --output tsv)

# Create DNS zone (optional)
read -p "Do you want to set up a custom domain? (y/N): " setup_domain
if [[ $setup_domain =~ ^[Yy]$ ]]; then
    read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME
    if [ -n "$DOMAIN_NAME" ]; then
        print_status "Creating DNS zone for: $DOMAIN_NAME"
        az network dns zone create \
          --resource-group $RESOURCE_GROUP \
          --name $DOMAIN_NAME \
          --output table
        
        print_status "Getting name servers..."
        az network dns zone show \
          --resource-group $RESOURCE_GROUP \
          --name $DOMAIN_NAME \
          --query nameServers \
          --output table
        
        print_warning "Please update your domain registrar with the above name servers."
        print_warning "After DNS propagation, run: az containerapp hostname add --hostname $DOMAIN_NAME --name $APP_NAME --resource-group $RESOURCE_GROUP"
    fi
fi

# Display deployment summary
print_header "Deployment Complete! 🎉"
echo ""
echo "📋 Deployment Summary:"
echo "======================="
echo "🌐 App URL: https://$APP_URL"
echo "🗄️  Database: $DB_NAME.postgres.database.azure.com"
echo "🐳 Container Registry: $ACR_NAME.azurecr.io"
echo "📁 Resource Group: $RESOURCE_GROUP"
echo "🚀 Container App: $APP_NAME"
echo ""
echo "💰 Estimated Monthly Cost: ~$43"
echo "   - Container App: ~$25"
echo "   - PostgreSQL B1ms: ~$12"
echo "   - Container Registry: ~$5"
echo "   - DNS: ~$0.50"
echo ""
echo "📌 Next Steps:"
echo "1. 🔍 Test your app: https://$APP_URL"
echo "2. 📊 Monitor logs: az containerapp logs show --name $APP_NAME --resource-group $RESOURCE_GROUP --follow"
echo "3. 🔧 Scale app: az containerapp update --name $APP_NAME --resource-group $RESOURCE_GROUP --min-replicas 2"
echo "4. 🌐 Add custom domain (if needed)"
echo "5. 📈 Set up monitoring and alerts"
echo ""
print_status "Container Apps deployment completed successfully! 🚀"

# Save deployment info
cat > deployment-info.txt << EOF
Flask Notes App - Container Apps Deployment
==========================================
Deployment Date: $(date)
Resource Group: $RESOURCE_GROUP
App Name: $APP_NAME
App URL: https://$APP_URL
Database: $DB_NAME.postgres.database.azure.com
Container Registry: $ACR_NAME.azurecr.io

Useful Commands:
- View logs: az containerapp logs show --name $APP_NAME --resource-group $RESOURCE_GROUP --follow
- Scale app: az containerapp update --name $APP_NAME --resource-group $RESOURCE_GROUP --min-replicas 2 --max-replicas 10
- Update image: az containerapp update --name $APP_NAME --resource-group $RESOURCE_GROUP --image $ACR_NAME.azurecr.io/flask-notes:latest
- Delete deployment: az group delete --name $RESOURCE_GROUP --yes
EOF

print_status "Deployment information saved to deployment-info.txt"
