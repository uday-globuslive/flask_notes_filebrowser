#!/bin/bash

# Domain Configuration Script for Azure
# Run this AFTER DNS propagation (24-48 hours after setting up name servers)

set -e

# Configuration
RESOURCE_GROUP="flask-notes-rg"
APP_NAME="flask-notes-app-$(whoami)"
DOMAIN_NAME="$1"  # Pass domain as first argument

if [ -z "$DOMAIN_NAME" ]; then
    echo "Usage: ./configure-domain.sh yourdomain.com"
    exit 1
fi

echo "🌐 Configuring custom domain: $DOMAIN_NAME"

# Get App Service details
APP_IP=$(az webapp show --resource-group $RESOURCE_GROUP --name $APP_NAME --query outboundIpAddresses --output tsv | cut -d',' -f1)
VERIFICATION_ID=$(az webapp show --resource-group $RESOURCE_GROUP --name $APP_NAME --query customDomainVerificationId --output tsv)

echo "📋 Domain Configuration Info:"
echo "App IP: $APP_IP"
echo "Verification ID: $VERIFICATION_ID"

# Check if DNS zone exists
if az network dns zone show --resource-group $RESOURCE_GROUP --name $DOMAIN_NAME &> /dev/null; then
    echo "✅ DNS zone exists for $DOMAIN_NAME"
else
    echo "Creating DNS zone for $DOMAIN_NAME..."
    az network dns zone create --resource-group $RESOURCE_GROUP --name $DOMAIN_NAME
fi

# Add DNS records
echo "Adding DNS records..."

# Add A record for root domain
az network dns record-set a add-record \
  --resource-group $RESOURCE_GROUP \
  --zone-name $DOMAIN_NAME \
  --record-set-name @ \
  --ipv4-address $APP_IP \
  --ttl 300

# Add CNAME for www
az network dns record-set cname set-record \
  --resource-group $RESOURCE_GROUP \
  --zone-name $DOMAIN_NAME \
  --record-set-name www \
  --cname $APP_NAME.azurewebsites.net \
  --ttl 300

# Add domain verification record
az network dns record-set txt add-record \
  --resource-group $RESOURCE_GROUP \
  --zone-name $DOMAIN_NAME \
  --record-set-name asuid \
  --value $VERIFICATION_ID \
  --ttl 300

echo "⏳ Waiting for DNS propagation..."
sleep 30

# Add custom domains to App Service
echo "Adding custom domains to App Service..."

# Add root domain
az webapp config hostname add \
  --webapp-name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --hostname $DOMAIN_NAME

# Add www subdomain
az webapp config hostname add \
  --webapp-name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --hostname www.$DOMAIN_NAME

# Create SSL certificates
echo "🔒 Creating SSL certificates..."

# Create managed certificate for root domain
CERT_THUMBPRINT_ROOT=$(az webapp config ssl create \
  --resource-group $RESOURCE_GROUP \
  --name $APP_NAME \
  --hostname $DOMAIN_NAME \
  --query thumbprint \
  --output tsv)

# Create managed certificate for www
CERT_THUMBPRINT_WWW=$(az webapp config ssl create \
  --resource-group $RESOURCE_GROUP \
  --name $APP_NAME \
  --hostname www.$DOMAIN_NAME \
  --query thumbprint \
  --output tsv)

# Bind certificates
echo "Binding SSL certificates..."

az webapp config ssl bind \
  --resource-group $RESOURCE_GROUP \
  --name $APP_NAME \
  --certificate-thumbprint $CERT_THUMBPRINT_ROOT \
  --ssl-type SNI

az webapp config ssl bind \
  --resource-group $RESOURCE_GROUP \
  --name $APP_NAME \
  --certificate-thumbprint $CERT_THUMBPRINT_WWW \
  --ssl-type SNI

echo "✅ Domain configuration completed!"
echo ""
echo "🎉 Your Flask Notes app is now available at:"
echo "   https://$DOMAIN_NAME"
echo "   https://www.$DOMAIN_NAME"
echo ""
echo "📋 SSL Certificate Thumbprints:"
echo "   Root: $CERT_THUMBPRINT_ROOT"
echo "   WWW:  $CERT_THUMBPRINT_WWW"
