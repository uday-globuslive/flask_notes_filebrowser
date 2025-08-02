# Azure Linux VM Deployment Guide

## 🚀 Deploy Flask Notes App on Azure Linux VM with Docker

Deploy your Flask Notes app on an Azure Linux virtual machine using Docker for the most cost-effective cloud solution with full control.

## 💰 Cost Comparison

| Deployment Option | Monthly Cost | Features | Control Level |
|-------------------|--------------|----------|---------------|
| **Azure VM B1s** | **$7.50** | 1 vCPU, 1GB RAM, 4GB SSD | Full Control ⭐⭐⭐⭐⭐ |
| **Azure VM B2s** | **$15.00** | 2 vCPU, 4GB RAM, 8GB SSD | Full Control ⭐⭐⭐⭐⭐ |
| Azure App Service B1 | $13.14 | Managed platform | Limited ⭐⭐⭐ |
| Azure Container Apps | $43.11 | Serverless containers | Moderate ⭐⭐⭐⭐ |
| Azure AKS | $185+ | Kubernetes cluster | High ⭐⭐⭐⭐⭐ |

**✅ Best Value: Azure VM B1s = $7.50/month with full control!**

## 🌐 Free Domain Options

### **Option 1: Free Subdomain Services (Recommended for Testing)**
- **[DuckDNS](https://www.duckdns.org)** - `yourapp.duckdns.org` (**FREE**)
- **[No-IP](https://www.noip.com)** - `yourapp.ddns.net` (**FREE**)
- **[FreeDNS](https://freedns.afraid.org)** - Various domains (**FREE**)

### **Option 2: Free Top-Level Domains**
- **[Freenom](https://www.freenom.com)** - `.tk`, `.ml`, `.ga`, `.cf` domains (**FREE** for 1 year)
- **[InfinityFree](https://infinityfree.net)** - Sometimes offers free `.com` domains

### **Option 3: Cheap Domains (Recommended for Production)**
- **[Namecheap](https://www.namecheap.com)** - `.com` domains ~$10/year
- **[Porkbun](https://porkbun.com)** - Competitive pricing
- **[Cloudflare](https://www.cloudflare.com/products/registrar/)** - At-cost pricing

## 🚀 One-Click Deployment

### **Windows Users:**
```cmd
# Download and run the automated deployment script
deploy-vm.bat
```

### **Linux/Mac Users:**
```bash
# Make script executable and run
chmod +x deploy-vm.sh
./deploy-vm.sh
```

### **What the Script Does:**
1. ✅ Creates Azure VM with Ubuntu 22.04
2. ✅ Installs Docker and Docker Compose
3. ✅ Deploys Flask Notes app with PostgreSQL
4. ✅ Configures Nginx reverse proxy
5. ✅ Sets up SSL certificates with Let's Encrypt
6. ✅ Configures Azure DNS (optional)
7. ✅ Provides management commands

## 📋 Manual Deployment Steps

If you prefer to understand each step or customize the deployment:

### Step 1: Prerequisites

1. **Azure Account** - Get $200 free credits at [azure.com](https://azure.microsoft.com/free/)
2. **Azure CLI** - Install from [docs.microsoft.com](https://docs.microsoft.com/cli/azure/install-azure-cli)
3. **SSH Client** - Built into Windows 10+, Linux, and Mac
4. **Domain Name** - Optional, see free options above

### Step 2: Create Azure VM

```bash
# Login to Azure
az login

# Create resource group
az group create --name flask-vm-rg --location "East US"

# Generate SSH key (if needed)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_vm_key

# Create VM
az vm create \
  --resource-group flask-vm-rg \
  --name flask-notes-vm \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username azureuser \
  --ssh-key-values ~/.ssh/azure_vm_key.pub \
  --public-ip-sku Standard

# Get VM public IP
VM_IP=$(az vm show -d -g flask-vm-rg -n flask-notes-vm --query publicIps -o tsv)
echo "VM IP: $VM_IP"

# Open ports
az vm open-port --resource-group flask-vm-rg --name flask-notes-vm --port 80 --priority 1000
az vm open-port --resource-group flask-vm-rg --name flask-notes-vm --port 443 --priority 1001
az vm open-port --resource-group flask-vm-rg --name flask-notes-vm --port 22 --priority 1002
```

### Step 3: Connect and Setup VM

```bash
# SSH into VM
ssh -i ~/.ssh/azure_vm_key azureuser@$VM_IP

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Nginx and Certbot
sudo apt install -y nginx certbot python3-certbot-nginx

# Logout and login again for docker group to take effect
exit
ssh -i ~/.ssh/azure_vm_key azureuser@$VM_IP
```

### Step 4: Deploy Application

```bash
# Clone repository
git clone https://github.com/uday-globuslive/flask_notes_filebrowser.git
cd flask_notes_filebrowser

# Create production environment
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

# Start application
docker-compose up -d

# Check status
docker-compose ps
docker-compose logs flask-app
```

### Step 5: Configure Nginx (Optional - for Custom Domain)

```bash
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

    client_max_body_size 16M;
}
EOF

# Enable site
sudo ln -s /etc/nginx/sites-available/flask-notes /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx
```

### Step 6: Setup SSL Certificate

```bash
# Get Let's Encrypt certificate
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Setup auto-renewal
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -
```

## 🌐 Domain Configuration Examples

### **Option 1: DuckDNS (Free)**

1. Go to [duckdns.org](https://www.duckdns.org)
2. Sign in with Google/GitHub
3. Create subdomain: `yourapp.duckdns.org`
4. Set IP to your VM's public IP
5. Copy your token

```bash
# On your VM, setup auto-update
echo "*/5 * * * * curl 'https://www.duckdns.org/update?domains=yourapp&token=YOUR_TOKEN&ip='" | crontab -
```

### **Option 2: Azure DNS**

```bash
# Create DNS zone
az network dns zone create \
  --resource-group flask-vm-rg \
  --name yourdomain.com

# Add A record
az network dns record-set a add-record \
  --resource-group flask-vm-rg \
  --zone-name yourdomain.com \
  --record-set-name @ \
  --ipv4-address $VM_IP

# Get name servers
az network dns zone show \
  --resource-group flask-vm-rg \
  --name yourdomain.com \
  --query nameServers
```

Then update your domain registrar with the Azure name servers.

## 🔧 Management Commands

### **Application Management**
```bash
# SSH into VM
ssh -i ~/.ssh/azure_vm_key azureuser@$VM_IP

# View application logs
docker-compose logs -f flask-app

# Restart application
docker-compose restart

# Update application
git pull
docker-compose up -d --build

# Stop application
docker-compose down

# View database logs
docker-compose logs postgres

# Backup database
docker-compose exec postgres pg_dump -U flaskuser notesdb > backup.sql
```

### **System Management**
```bash
# Check system resources
htop
df -h
free -h

# Check Nginx status
sudo systemctl status nginx

# View Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Renew SSL certificate manually
sudo certbot renew

# Check SSL certificate status
sudo certbot certificates
```

## 📊 Performance Optimization

### **For B1s VM (1 vCPU, 1GB RAM):**
```yaml
# Optimize docker-compose.yml for small VM
services:
  flask-app:
    # ... existing config ...
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M

  postgres:
    # ... existing config ...
    deploy:
      resources:
        limits:
          memory: 256M
        reservations:
          memory: 128M
```

### **For B2s VM (2 vCPU, 4GB RAM):**
```bash
# Update docker-compose for better performance
# Increase worker processes in gunicorn
# Add Redis for caching
```

## 🛡️ Security Best Practices

### **1. SSH Security**
```bash
# Disable password authentication
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Change SSH port (optional)
sudo sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Don't forget to update Azure NSG rules if you change SSH port
```

### **2. Firewall Configuration**
```bash
# Enable UFW firewall
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw status
```

### **3. Automatic Updates**
```bash
# Enable automatic security updates
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

## 📈 Monitoring and Alerts

### **Basic Monitoring**
```bash
# Install monitoring tools
sudo apt install htop iotop nethogs

# Create simple monitoring script
cat > monitor.sh << 'EOF'
#!/bin/bash
echo "=== System Status $(date) ==="
echo "CPU Usage:"
top -bn1 | grep "Cpu(s)" | awk '{print $2 $3}'
echo "Memory Usage:"
free -h | awk 'NR==2{printf "Memory Usage: %s/%s (%.2f%%)\n", $3,$2,$3*100/$2 }'
echo "Disk Usage:"
df -h | awk '$NF=="/"{printf "Disk Usage: %d/%dGB (%s)\n", $3,$2,$5}'
echo "Application Status:"
docker-compose ps
echo "============================="
EOF

chmod +x monitor.sh

# Run monitoring every 5 minutes
echo "*/5 * * * * /home/azureuser/monitor.sh >> /home/azureuser/system.log" | crontab -
```

## 🔄 Backup Strategy

### **Application Backup**
```bash
# Create backup script
cat > backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/azureuser/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup database
docker-compose exec -T postgres pg_dump -U flaskuser notesdb > $BACKUP_DIR/db_backup_$DATE.sql

# Backup uploads
tar -czf $BACKUP_DIR/uploads_backup_$DATE.tar.gz uploads/

# Backup application configuration
cp .env $BACKUP_DIR/env_backup_$DATE
cp docker-compose.yml $BACKUP_DIR/compose_backup_$DATE.yml

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*backup*" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x backup.sh

# Run backup daily at 2 AM
echo "0 2 * * * /home/azureuser/flask_notes_filebrowser/backup.sh" | crontab -
```

## 🚨 Troubleshooting

### **Common Issues**

1. **Application not starting**
   ```bash
   # Check logs
   docker-compose logs
   
   # Check if ports are in use
   sudo netstat -tulpn | grep :8000
   
   # Restart services
   docker-compose down && docker-compose up -d
   ```

2. **Database connection issues**
   ```bash
   # Check PostgreSQL logs
   docker-compose logs postgres
   
   # Connect to database manually
   docker-compose exec postgres psql -U flaskuser -d notesdb
   ```

3. **SSL certificate issues**
   ```bash
   # Check certificate status
   sudo certbot certificates
   
   # Test certificate renewal
   sudo certbot renew --dry-run
   
   # Check Nginx configuration
   sudo nginx -t
   ```

4. **Domain not resolving**
   ```bash
   # Check DNS propagation
   nslookup yourdomain.com
   dig yourdomain.com
   
   # Check domain configuration
   cat /etc/nginx/sites-enabled/flask-notes
   ```

## 🗑️ Cleanup

### **Delete Everything**
```bash
# Delete Azure resource group (removes VM, IP, disks, etc.)
az group delete --name flask-vm-rg --yes
```

### **Partial Cleanup**
```bash
# Stop and remove containers only
docker-compose down

# Remove just the VM
az vm delete --resource-group flask-vm-rg --name flask-notes-vm --yes
```

## 💡 Pro Tips

1. **Use Azure Spot VMs** for even cheaper costs (up to 90% discount)
2. **Snapshot your VM** after successful deployment for quick recovery
3. **Use Azure Load Balancer** if you need to scale to multiple VMs
4. **Set up Azure Monitor** for advanced monitoring and alerts
5. **Use Azure Backup** for automated VM backups

## 🎉 Summary

With this deployment, you get:

✅ **Ultra-low cost**: $7.50/month for B1s VM  
✅ **Full control**: Root access to Ubuntu VM  
✅ **Professional setup**: Nginx + SSL + Docker  
✅ **Automatic SSL**: Let's Encrypt certificates  
✅ **Easy management**: Docker Compose for services  
✅ **Scalable**: Can upgrade VM size anytime  
✅ **Portable**: Same Docker setup works anywhere  

Your Flask Notes app will be running at `https://yourdomain.com` with enterprise-grade security for less than the price of a coffee! ☕

---

**Ready to deploy? Run the automated script and you'll be live in 10 minutes! 🚀**
