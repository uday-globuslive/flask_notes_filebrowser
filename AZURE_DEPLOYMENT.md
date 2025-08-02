# Azure Deployment Guide for Flask Notes App

## 🚀 Complete Azure Deployment with Custom Domain & SSL

This guide will help you deploy your Flask Notes app to Azure with PostgreSQL database, custom domain, and SSL certificates in the most cost-effective way.

## 📋 Prerequisites

1. **Azure Account** - Free tier available at [azure.microsoft.com](https://azure.microsoft.com/free/)
2. **Domain Name** - You'll need to own a domain for custom DNS
3. **Your Flask Notes App** - Already pushed to GitHub
4. **Azure CLI** - Install from [docs.microsoft.com](https://docs.microsoft.com/cli/azure/install-azure-cli)

## 💰 Cost-Effective Azure Architecture

### **Recommended Setup (Budget-Friendly)**
- **App Service**: B1 Basic Plan (~$13/month)
- **PostgreSQL**: Flexible Server Burstable B1ms (~$12/month)
- **Azure DNS**: $0.50 per hosted zone + $0.40 per million queries
- **SSL Certificate**: FREE (Azure App Service Managed Certificate)
- **Total**: ~$26/month

### **Ultra-Budget Setup (Development)**
- **App Service**: F1 Free Plan (FREE - limited features)
- **PostgreSQL**: Use SQLite or external free PostgreSQL
- **Azure DNS**: Same pricing
- **Total**: ~$1/month (just DNS)

## 🔧 Step-by-Step Deployment

### Step 1: Create Azure Resources

#### 1.1 Login to Azure CLI
```bash
az login
```

#### 1.2 Create Resource Group
```bash
az group create --name flask-notes-rg --location "East US"
```

#### 1.3 Create PostgreSQL Database
```bash
# For cost-effective Flexible Server
az postgres flexible-server create \
  --resource-group flask-notes-rg \
  --name flask-notes-db \
  --location "East US" \
  --admin-user flaskadmin \
  --admin-password "YourSecurePassword123!" \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --storage-size 32 \
  --version 13
```

#### 1.4 Create Database
```bash
az postgres flexible-server db create \
  --resource-group flask-notes-rg \
  --server-name flask-notes-db \
  --database-name notesdb
```

#### 1.5 Configure Firewall (Allow Azure Services)
```bash
az postgres flexible-server firewall-rule create \
  --resource-group flask-notes-rg \
  --name flask-notes-db \
  --rule-name AllowAzure \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

### Step 2: Prepare Your Application

#### 2.1 Update requirements.txt
Add production dependencies:
```txt
Flask==2.3.3
Flask-SQLAlchemy==3.0.5
Flask-Login==0.6.3
Flask-Migrate==4.0.5
Flask-WTF==1.1.1
WTForms==3.0.1
Werkzeug==2.3.7
python-dotenv==1.0.0
psycopg2-binary==2.9.9
gunicorn==21.2.0
whitenoise==6.5.0
```

#### 2.2 Create startup.py for Azure
```python
import os
from app import app

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8000)))
```

#### 2.3 Update app.py for Production
Add these configurations:
```python
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = Flask(__name__)

# Production configuration
if os.environ.get('FLASK_ENV') == 'production':
    app.config['DEBUG'] = False
    app.config['TESTING'] = False
else:
    app.config['DEBUG'] = True

# Database configuration
DATABASE_URL = os.environ.get('DATABASE_URL')
if DATABASE_URL:
    # Azure PostgreSQL connection string format
    app.config['SQLALCHEMY_DATABASE_URI'] = DATABASE_URL
else:
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///notes_app.db'

# Security
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'fallback-secret-key')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
```

### Step 3: Create App Service

#### 3.1 Create App Service Plan
```bash
# For production (B1 Basic)
az appservice plan create \
  --name flask-notes-plan \
  --resource-group flask-notes-rg \
  --sku B1 \
  --is-linux

# For development (F1 Free) - Alternative
az appservice plan create \
  --name flask-notes-plan-free \
  --resource-group flask-notes-rg \
  --sku F1 \
  --is-linux
```

#### 3.2 Create Web App
```bash
az webapp create \
  --resource-group flask-notes-rg \
  --plan flask-notes-plan \
  --name flask-notes-app-yourname \
  --runtime "PYTHON|3.9" \
  --deployment-source-url https://github.com/uday-globuslive/flask_notes_filebrowser
```

### Step 4: Configure Environment Variables

```bash
# Database connection
az webapp config appsettings set \
  --resource-group flask-notes-rg \
  --name flask-notes-app-yourname \
  --settings DATABASE_URL="postgresql://flaskadmin:YourSecurePassword123!@flask-notes-db.postgres.database.azure.com:5432/notesdb"

# Security
az webapp config appsettings set \
  --resource-group flask-notes-rg \
  --name flask-notes-app-yourname \
  --settings SECRET_KEY="your-production-secret-key-make-it-very-long-and-random"

# Flask environment
az webapp config appsettings set \
  --resource-group flask-notes-rg \
  --name flask-notes-app-yourname \
  --settings FLASK_ENV="production"

# Upload settings
az webapp config appsettings set \
  --resource-group flask-notes-rg \
  --name flask-notes-app-yourname \
  --settings UPLOAD_FOLDER="/tmp/uploads" MAX_CONTENT_LENGTH="16777216"
```

### Step 5: Configure Startup Command

```bash
az webapp config set \
  --resource-group flask-notes-rg \
  --name flask-notes-app-yourname \
  --startup-file "gunicorn --bind=0.0.0.0 --timeout 600 app:app"
```

## 🌐 Custom Domain Setup with Azure DNS

### Step 1: Create DNS Zone

```bash
az network dns zone create \
  --resource-group flask-notes-rg \
  --name yourdomain.com
```

### Step 2: Get Name Servers
```bash
az network dns zone show \
  --resource-group flask-notes-rg \
  --name yourdomain.com \
  --query nameServers
```

**Update your domain registrar** to use these Azure name servers.

### Step 3: Add DNS Records

#### 3.1 Add A Record (Root Domain)
```bash
# Get your App Service IP
az webapp show \
  --resource-group flask-notes-rg \
  --name flask-notes-app-yourname \
  --query defaultHostName

# Add A record
az network dns record-set a add-record \
  --resource-group flask-notes-rg \
  --zone-name yourdomain.com \
  --record-set-name @ \
  --ipv4-address YOUR_APP_SERVICE_IP
```

#### 3.2 Add CNAME Record (www subdomain)
```bash
az network dns record-set cname set-record \
  --resource-group flask-notes-rg \
  --zone-name yourdomain.com \
  --record-set-name www \
  --cname flask-notes-app-yourname.azurewebsites.net
```

#### 3.3 Add CNAME for Domain Verification
```bash
az network dns record-set cname set-record \
  --resource-group flask-notes-rg \
  --zone-name yourdomain.com \
  --record-set-name asuid \
  --cname YOUR_DOMAIN_VERIFICATION_ID
```

### Step 4: Configure Custom Domain in App Service

```bash
# Add custom domain
az webapp config hostname add \
  --webapp-name flask-notes-app-yourname \
  --resource-group flask-notes-rg \
  --hostname yourdomain.com

# Add www subdomain
az webapp config hostname add \
  --webapp-name flask-notes-app-yourname \
  --resource-group flask-notes-rg \
  --hostname www.yourdomain.com
```

## 🔒 SSL Certificate Setup (FREE)

### Option 1: Azure App Service Managed Certificate (Recommended)

```bash
# Create managed certificate for root domain
az webapp config ssl create \
  --resource-group flask-notes-rg \
  --name flask-notes-app-yourname \
  --hostname yourdomain.com

# Create managed certificate for www
az webapp config ssl create \
  --resource-group flask-notes-rg \
  --name flask-notes-app-yourname \
  --hostname www.yourdomain.com

# Bind certificates
az webapp config ssl bind \
  --resource-group flask-notes-rg \
  --name flask-notes-app-yourname \
  --certificate-thumbprint CERT_THUMBPRINT \
  --ssl-type SNI
```

### Option 2: Let's Encrypt (Free Alternative)

If you prefer Let's Encrypt, you can use the App Service Extension:

1. Go to Azure Portal → Your App Service
2. Navigate to "Extensions" → "Add"
3. Search for "Let's Encrypt" and install
4. Configure through the extension interface

## 🚀 Deployment Automation

### Create deployment script (deploy.sh):

```bash
#!/bin/bash

# Build and deploy to Azure
echo "Deploying Flask Notes App to Azure..."

# Git deployment
git add .
git commit -m "Deploy to Azure: $(date)"
git push origin main

# Restart app service
az webapp restart \
  --resource-group flask-notes-rg \
  --name flask-notes-app-yourname

echo "Deployment complete!"
echo "App URL: https://yourdomain.com"
```

## 💡 Cost Optimization Tips

### 1. **Use Azure Free Credits**
- New accounts get $200 free credits
- Many services have free tiers

### 2. **Auto-scaling for Traffic**
```bash
# Set up auto-scaling (only for Standard tier and above)
az monitor autoscale create \
  --resource-group flask-notes-rg \
  --resource flask-notes-app-yourname \
  --min-count 1 \
  --max-count 3 \
  --count 1
```

### 3. **Development/Staging Slots**
Use deployment slots for testing before production:
```bash
az webapp deployment slot create \
  --resource-group flask-notes-rg \
  --name flask-notes-app-yourname \
  --slot staging
```

### 4. **Database Optimization**
- Use Burstable tier for development
- Scale up only when needed
- Enable automatic backup (included in cost)

## 🔧 Production Checklist

### Security
- [ ] Change all default passwords
- [ ] Use strong SECRET_KEY
- [ ] Enable HTTPS only redirect
- [ ] Configure CORS properly
- [ ] Set up monitoring and alerts

### Performance
- [ ] Enable application insights
- [ ] Configure caching
- [ ] Optimize database queries
- [ ] Set up CDN for static files

### Monitoring
```bash
# Enable Application Insights
az monitor app-insights component create \
  --app flask-notes-insights \
  --location "East US" \
  --resource-group flask-notes-rg \
  --application-type web
```

## 🆘 Troubleshooting

### Common Issues:

1. **Database Connection Failed**
   - Check firewall rules
   - Verify connection string
   - Ensure database exists

2. **Domain Not Working**
   - Verify DNS propagation (use dig or nslookup)
   - Check domain verification
   - Wait up to 48 hours for DNS propagation

3. **SSL Certificate Issues**
   - Ensure domain is verified
   - Check certificate binding
   - Try recreating the certificate

### Useful Commands:

```bash
# View application logs
az webapp log tail \
  --resource-group flask-notes-rg \
  --name flask-notes-app-yourname

# SSH into container
az webapp ssh \
  --resource-group flask-notes-rg \
  --name flask-notes-app-yourname

# Check app status
az webapp show \
  --resource-group flask-notes-rg \
  --name flask-notes-app-yourname \
  --query state
```

## 💰 Monthly Cost Breakdown

### Budget Option (~$26/month)
- **App Service B1**: $13.14/month
- **PostgreSQL B1ms**: $12.41/month
- **Azure DNS**: $0.50/month
- **Bandwidth**: ~$0.10/month
- **SSL**: FREE

### Enterprise Option (~$200/month)
- **App Service S1**: $73/month
- **PostgreSQL GP_Gen5_2**: $146/month
- **Application Insights**: Included
- **Backup**: Included
- **Auto-scaling**: Included

## 🎯 Next Steps

1. **Deploy your app** following this guide
2. **Test all functionality** on the live site
3. **Set up monitoring** and alerts
4. **Configure backup strategy**
5. **Plan for scaling** as your user base grows

Your Flask Notes app will be live at `https://yourdomain.com` with enterprise-grade security, scalability, and performance! 🚀

## 📞 Support Resources

- **Azure Documentation**: [docs.microsoft.com](https://docs.microsoft.com/azure/)
- **Azure Support**: Available through Azure Portal
- **Community**: Stack Overflow with `azure` tag
- **Pricing Calculator**: [azure.microsoft.com/pricing/calculator/](https://azure.microsoft.com/pricing/calculator/)

---

**Note**: Replace `yourdomain.com`, `flask-notes-app-yourname`, and other placeholders with your actual values throughout the deployment process.
