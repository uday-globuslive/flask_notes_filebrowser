# Azure Linux VM Deployment Guide

## 🚀 Deploy Flask Notes App on Azure Linux VM with Docker

This guide shows you how to deploy your Flask Notes app on an Azure Linux virtual machine using Docker, with custom domain and free SSL certificates.

## 💰 Cost Comparison

| Option | Monthly Cost | Features |
|--------|--------------|----------|
| **Azure VM (B1s)** | **~$7.50/month** | 1 vCPU, 1GB RAM, 4GB SSD |
| **Azure VM (B2s)** | **~$15/month** | 2 vCPU, 4GB RAM, 8GB SSD |
| App Service B1 | $13/month | Managed, but less control |
| Container Apps | $43/month | Serverless, auto-scaling |

**VM Deployment = Much cheaper + Full control!**

## 📋 Prerequisites

1. **Azure Account** - Free tier includes $200 credits
2. **Domain Name** - See free domain options below
3. **SSH Key** - We'll create one if needed
4. **Azure CLI** - Install from [docs.microsoft.com](https://docs.microsoft.com/cli/azure/install-azure-cli)

## 🌐 Free Domain Options

### **Option 1: Free Subdomain Services**
- **DuckDNS** - `yourapp.duckdns.org` (Free)
- **No-IP** - `yourapp.ddns.net` (Free)
- **FreeDNS** - Various free domains available

### **Option 2: Free Top-Level Domains**
- **Freenom** - `.tk`, `.ml`, `.ga`, `.cf` domains (Free for 1 year)
- **InfinityFree** - Sometimes offers free `.com` domains

### **Option 3: Cheap Domains**
- **Namecheap** - `.com` domains ~$10/year
- **Porkbun** - Competitive pricing
- **GoDaddy** - Frequent sales

## 🔧 Step-by-Step Deployment

### Step 1: Create SSH Key (if needed)

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_vm_key

# View public key (copy this for VM creation)
cat ~/.ssh/azure_vm_key.pub
```

### Step 2: Create Azure VM

```bash
# Login to Azure
az login

# Create resource group
az group create --name flask-vm-rg --location "East US"

# Create VM with SSH key
az vm create \
  --resource-group flask-vm-rg \
  --name flask-notes-vm \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username azureuser \
  --ssh-key-values ~/.ssh/azure_vm_key.pub \
  --public-ip-sku Standard \
  --output table

# Get VM public IP
VM_IP=$(az vm show -d -g flask-vm-rg -n flask-notes-vm --query publicIps -o tsv)
echo "VM Public IP: $VM_IP"
```

### Step 3: Configure Network Security

```bash
# Open HTTP port 80
az vm open-port \
  --resource-group flask-vm-rg \
  --name flask-notes-vm \
  --port 80 \
  --priority 1000

# Open HTTPS port 443
az vm open-port \
  --resource-group flask-vm-rg \
  --name flask-notes-vm \
  --port 443 \
  --priority 1001

# Open SSH port 22 (usually already open)
az vm open-port \
  --resource-group flask-vm-rg \
  --name flask-notes-vm \
  --port 22 \
  --priority 1002
```

### Step 4: Connect and Setup VM

```bash
# SSH into the VM
ssh -i ~/.ssh/azure_vm_key azureuser@$VM_IP

# Once connected to VM, run these commands:
```

### Step 5: Install Docker on Azure VM

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker dependencies
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker azureuser

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Install Docker Compose (standalone)
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version

# Log out and back in to apply group changes
exit
```

### Step 6: Deploy Application

```bash
# SSH back into VM
ssh -i ~/.ssh/azure_vm_key azureuser@$VM_IP

# Clone your repository
git clone https://github.com/uday-globuslive/flask_notes_filebrowser.git
cd flask_notes_filebrowser

# Create production environment file
cat > .env << EOF
DATABASE_TYPE=postgresql
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_USER=flaskuser
POSTGRES_PASSWORD=$(openssl rand -base64 32)
POSTGRES_DB=notesdb
SECRET_KEY=$(openssl rand -base64 32)
FLASK_ENV=production
UPLOAD_FOLDER=/app/uploads
MAX_CONTENT_LENGTH=16777216
EOF

# Start the application
docker-compose up -d

# Check if containers are running
docker-compose ps

# View logs
docker-compose logs flask-app
```

## 🌐 Domain and DNS Setup

### Option 1: Free Domain with DuckDNS

1. **Get free subdomain**: Go to [duckdns.org](https://www.duckdns.org)
2. **Sign in** with Google/GitHub
3. **Create subdomain**: `yourapp.duckdns.org`
4. **Set IP address**: Point to your VM's public IP
5. **Get token**: Save your DuckDNS token

```bash
# On your VM, install DuckDNS updater
echo "*/5 * * * * curl 'https://www.duckdns.org/update?domains=yourapp&token=YOUR_TOKEN&ip='" | crontab -
```

### Option 2: Azure DNS with Your Domain

```bash
# Create DNS zone in Azure
az network dns zone create \
  --resource-group flask-vm-rg \
  --name yourdomain.com

# Get name servers
az network dns zone show \
  --resource-group flask-vm-rg \
  --name yourdomain.com \
  --query nameServers

# Add A record pointing to VM
az network dns record-set a add-record \
  --resource-group flask-vm-rg \
  --zone-name yourdomain.com \
  --record-set-name @ \
  --ipv4-address $VM_IP

# Add www CNAME record
az network dns record-set cname set-record \
  --resource-group flask-vm-rg \
  --zone-name yourdomain.com \
  --record-set-name www \
  --cname yourdomain.com
```

## 🔒 SSL Certificate Setup with Let's Encrypt

### Install Nginx and Certbot

```bash
# SSH into your VM
ssh -i ~/.ssh/azure_vm_key azureuser@$VM_IP

# Install Nginx and Certbot
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx

# Create Nginx configuration
sudo tee /etc/nginx/sites-available/flask-notes << EOF
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Handle file uploads
    client_max_body_size 16M;
}
EOF

# Enable the site
sudo ln -s /etc/nginx/sites-available/flask-notes /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Start Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Get SSL certificate from Let's Encrypt
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Set up automatic renewal
sudo crontab -e
# Add this line:
# 0 12 * * * /usr/bin/certbot renew --quiet
```

## 🚀 Automated Deployment Script

<function_calls>
<invoke name="create_file">
<parameter name="content">#!/bin/bash

# Azure VM Deployment Script for Flask Notes App
# This script automates the entire deployment process

set -e

# Configuration
RESOURCE_GROUP="flask-vm-rg"
VM_NAME="flask-notes-vm"
LOCATION="East US"
VM_SIZE="Standard_B1s"  # Change to Standard_B2s for better performance
ADMIN_USER="azureuser"
DOMAIN_NAME=""  # Set your domain here
SSH_KEY_PATH="$HOME/.ssh/azure_vm_key"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} $1 ${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI not found. Please install it first."
        exit 1
    fi
    
    # Check if logged in
    if ! az account show &> /dev/null; then
        print_warning "Not logged in to Azure. Starting login..."
        az login
    fi
    
    print_info "✅ Prerequisites check passed"
}

# Generate SSH key if it doesn't exist
generate_ssh_key() {
    print_header "Setting Up SSH Key"
    
    if [ ! -f "$SSH_KEY_PATH" ]; then
        print_info "Generating SSH key pair..."
        ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N ""
        chmod 600 "$SSH_KEY_PATH"
        chmod 644 "${SSH_KEY_PATH}.pub"
        print_info "✅ SSH key generated at $SSH_KEY_PATH"
    else
        print_info "✅ SSH key already exists at $SSH_KEY_PATH"
    fi
}

# Create Azure VM
create_vm() {
    print_header "Creating Azure Virtual Machine"
    
    # Create resource group
    print_info "Creating resource group: $RESOURCE_GROUP"
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output table
    
    # Create VM
    print_info "Creating virtual machine: $VM_NAME"
    print_info "Size: $VM_SIZE | Location: $LOCATION"
    
    az vm create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$VM_NAME" \
        --image Ubuntu2204 \
        --size "$VM_SIZE" \
        --admin-username "$ADMIN_USER" \
        --ssh-key-values "${SSH_KEY_PATH}.pub" \
        --public-ip-sku Standard \
        --output table
    
    # Get VM public IP
    VM_IP=$(az vm show -d -g "$RESOURCE_GROUP" -n "$VM_NAME" --query publicIps -o tsv)
    print_info "✅ VM created with public IP: $VM_IP"
    
    # Save IP to file
    echo "$VM_IP" > vm_ip.txt
    echo "$VM_IP"
}

# Configure network security
configure_network() {
    print_header "Configuring Network Security"
    
    # Open ports
    print_info "Opening port 80 (HTTP)..."
    az vm open-port --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --port 80 --priority 1000
    
    print_info "Opening port 443 (HTTPS)..."
    az vm open-port --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --port 443 --priority 1001
    
    print_info "Opening port 22 (SSH)..."
    az vm open-port --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --port 22 --priority 1002
    
    print_info "✅ Network security configured"
}

# Install Docker on VM
install_docker() {
    print_header "Installing Docker on VM"
    
    VM_IP=$(cat vm_ip.txt 2>/dev/null || az vm show -d -g "$RESOURCE_GROUP" -n "$VM_NAME" --query publicIps -o tsv)
    
    print_info "Connecting to VM at $VM_IP..."
    
    # Wait for VM to be ready
    print_info "Waiting for VM to be ready..."
    sleep 30
    
    # Install Docker via SSH
    ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$ADMIN_USER@$VM_IP" << 'ENDSSH'
        set -e
        echo "🔧 Installing Docker..."
        
        # Update system
        sudo apt update && sudo apt upgrade -y
        
        # Install Docker dependencies
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
        
        # Add Docker GPG key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        
        # Add Docker repository
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Install Docker
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        
        # Add user to docker group
        sudo usermod -aG docker $USER
        
        # Start Docker
        sudo systemctl start docker
        sudo systemctl enable docker
        
        # Install Docker Compose
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        
        # Install Nginx and Certbot
        sudo apt install -y nginx certbot python3-certbot-nginx
        
        echo "✅ Docker and Nginx installed successfully!"
ENDSSH
    
    print_info "✅ Docker installation completed"
}

# Deploy application
deploy_app() {
    print_header "Deploying Flask Notes Application"
    
    VM_IP=$(cat vm_ip.txt 2>/dev/null || az vm show -d -g "$RESOURCE_GROUP" -n "$VM_NAME" --query publicIps -o tsv)
    
    print_info "Deploying application to $VM_IP..."
    
    # Deploy app via SSH
    ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$ADMIN_USER@$VM_IP" << 'ENDSSH'
        set -e
        echo "📦 Deploying Flask Notes App..."
        
        # Clone repository
        if [ -d "flask_notes_filebrowser" ]; then
            cd flask_notes_filebrowser
            git pull
        else
            git clone https://github.com/uday-globuslive/flask_notes_filebrowser.git
            cd flask_notes_filebrowser
        fi
        
        # Generate secure passwords
        POSTGRES_PASSWORD=$(openssl rand -base64 32)
        SECRET_KEY=$(openssl rand -base64 32)
        
        # Create production environment file
        cat > .env << EOF
DATABASE_TYPE=postgresql
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_USER=flaskuser
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_DB=notesdb
SECRET_KEY=$SECRET_KEY
FLASK_ENV=production
UPLOAD_FOLDER=/app/uploads
MAX_CONTENT_LENGTH=16777216
EOF
        
        # Start application with Docker Compose
        docker-compose down 2>/dev/null || true
        docker-compose up -d
        
        # Wait for containers to start
        sleep 10
        
        # Check if containers are running
        docker-compose ps
        
        echo "✅ Application deployed successfully!"
        echo "🌐 App is running at: http://$(curl -s ifconfig.me):8000"
ENDSSH
    
    print_info "✅ Application deployment completed"
}

# Configure Nginx
configure_nginx() {
    print_header "Configuring Nginx Reverse Proxy"
    
    VM_IP=$(cat vm_ip.txt 2>/dev/null || az vm show -d -g "$RESOURCE_GROUP" -n "$VM_NAME" --query publicIps -o tsv)
    
    if [ -z "$DOMAIN_NAME" ]; then
        read -p "Enter your domain name (leave empty to skip): " DOMAIN_NAME
    fi
    
    if [ -n "$DOMAIN_NAME" ]; then
        print_info "Configuring Nginx for domain: $DOMAIN_NAME"
        
        ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$ADMIN_USER@$VM_IP" << ENDSSH
            set -e
            echo "🔧 Configuring Nginx..."
            
            # Create Nginx configuration
            sudo tee /etc/nginx/sites-available/flask-notes << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \\\$host;
        proxy_set_header X-Real-IP \\\$remote_addr;
        proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\\$scheme;
    }

    client_max_body_size 16M;
}
EOF
            
            # Enable site
            sudo ln -sf /etc/nginx/sites-available/flask-notes /etc/nginx/sites-enabled/
            sudo rm -f /etc/nginx/sites-enabled/default
            
            # Test and restart Nginx
            sudo nginx -t
            sudo systemctl restart nginx
            sudo systemctl enable nginx
            
            echo "✅ Nginx configured for $DOMAIN_NAME"
ENDSSH
    else
        print_warning "Skipping Nginx configuration (no domain provided)"
    fi
}

# Setup SSL certificate
setup_ssl() {
    print_header "Setting Up SSL Certificate"
    
    VM_IP=$(cat vm_ip.txt 2>/dev/null || az vm show -d -g "$RESOURCE_GROUP" -n "$VM_NAME" --query publicIps -o tsv)
    
    if [ -n "$DOMAIN_NAME" ]; then
        print_info "Setting up Let's Encrypt SSL for: $DOMAIN_NAME"
        
        ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$ADMIN_USER@$VM_IP" << ENDSSH
            set -e
            echo "🔒 Setting up SSL certificate..."
            
            # Get SSL certificate
            sudo certbot --nginx -d $DOMAIN_NAME -d www.$DOMAIN_NAME --non-interactive --agree-tos --email admin@$DOMAIN_NAME
            
            # Set up auto-renewal
            echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -
            
            echo "✅ SSL certificate installed for $DOMAIN_NAME"
ENDSSH
        
        print_info "✅ SSL setup completed"
    else
        print_warning "Skipping SSL setup (no domain configured)"
    fi
}

# Create DNS records
setup_dns() {
    print_header "Setting Up DNS Records"
    
    VM_IP=$(cat vm_ip.txt 2>/dev/null || az vm show -d -g "$RESOURCE_GROUP" -n "$VM_NAME" --query publicIps -o tsv)
    
    if [ -n "$DOMAIN_NAME" ]; then
        read -p "Do you want to create DNS zone in Azure? (y/N): " create_dns
        
        if [[ $create_dns =~ ^[Yy]$ ]]; then
            print_info "Creating DNS zone for: $DOMAIN_NAME"
            
            # Create DNS zone
            az network dns zone create \
                --resource-group "$RESOURCE_GROUP" \
                --name "$DOMAIN_NAME" \
                --output table
            
            # Add A record
            az network dns record-set a add-record \
                --resource-group "$RESOURCE_GROUP" \
                --zone-name "$DOMAIN_NAME" \
                --record-set-name @ \
                --ipv4-address "$VM_IP" \
                --output table
            
            # Add www CNAME
            az network dns record-set cname set-record \
                --resource-group "$RESOURCE_GROUP" \
                --zone-name "$DOMAIN_NAME" \
                --record-set-name www \
                --cname "$DOMAIN_NAME" \
                --output table
            
            # Show name servers
            print_info "DNS zone created. Update your domain registrar with these name servers:"
            az network dns zone show \
                --resource-group "$RESOURCE_GROUP" \
                --name "$DOMAIN_NAME" \
                --query nameServers \
                --output table
        fi
    fi
}

# Display deployment summary
show_summary() {
    print_header "Deployment Summary"
    
    VM_IP=$(cat vm_ip.txt 2>/dev/null || az vm show -d -g "$RESOURCE_GROUP" -n "$VM_NAME" --query publicIps -o tsv)
    
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo "=================================="
    echo "📋 Deployment Details:"
    echo "   🖥️  VM Name: $VM_NAME"
    echo "   🌐 Public IP: $VM_IP"
    echo "   👤 SSH User: $ADMIN_USER"
    echo "   🔑 SSH Key: $SSH_KEY_PATH"
    
    if [ -n "$DOMAIN_NAME" ]; then
        echo "   🌍 Domain: https://$DOMAIN_NAME"
        echo "   🌍 Alt URL: https://www.$DOMAIN_NAME"
    else
        echo "   🌍 App URL: http://$VM_IP"
    fi
    
    echo ""
    echo "📊 Estimated Monthly Cost: ~$7.50 (B1s) or ~$15 (B2s)"
    echo ""
    echo "🔧 Management Commands:"
    echo "   SSH into VM: ssh -i $SSH_KEY_PATH $ADMIN_USER@$VM_IP"
    echo "   View logs: docker-compose logs -f flask-app"
    echo "   Restart app: docker-compose restart"
    echo "   Stop app: docker-compose down"
    echo "   Update app: git pull && docker-compose up -d --build"
    echo ""
    echo "🗑️  Cleanup Command:"
    echo "   az group delete --name $RESOURCE_GROUP --yes"
    
    # Save deployment info
    cat > deployment-info.txt << EOF
Flask Notes App - Azure VM Deployment
====================================
Deployment Date: $(date)
Resource Group: $RESOURCE_GROUP
VM Name: $VM_NAME
Public IP: $VM_IP
SSH User: $ADMIN_USER
SSH Key: $SSH_KEY_PATH
Domain: $DOMAIN_NAME
App URL: ${DOMAIN_NAME:+https://$DOMAIN_NAME}${DOMAIN_NAME:-http://$VM_IP}

Management Commands:
- SSH: ssh -i $SSH_KEY_PATH $ADMIN_USER@$VM_IP
- Logs: docker-compose logs -f flask-app
- Restart: docker-compose restart
- Update: git pull && docker-compose up -d --build
- Cleanup: az group delete --name $RESOURCE_GROUP --yes
EOF
    
    print_info "Deployment information saved to deployment-info.txt"
}

# Main deployment function
main() {
    print_header "Azure VM Deployment for Flask Notes App"
    
    # Get domain name from user
    if [ -z "$DOMAIN_NAME" ]; then
        echo "🌐 Domain Configuration:"
        echo "   1. Enter your domain name for SSL setup"
        echo "   2. Leave empty to deploy without domain (HTTP only)"
        echo "   3. You can configure domain later"
        echo ""
        read -p "Enter domain name (optional): " DOMAIN_NAME
    fi
    
    # Run deployment steps
    check_prerequisites
    generate_ssh_key
    create_vm
    configure_network
    install_docker
    deploy_app
    configure_nginx
    
    if [ -n "$DOMAIN_NAME" ]; then
        setup_dns
        echo ""
        print_warning "⏳ Please update your domain's name servers before continuing with SSL setup"
        read -p "Press Enter after updating DNS (or Ctrl+C to skip SSL setup)..."
        setup_ssl
    fi
    
    show_summary
}

# Run main function
main "$@"
