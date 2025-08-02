# Azure Container Services Deployment Guide

## 🐳 Complete Container Deployment Options for Flask Notes App

This guide covers three Azure container services with detailed cost analysis and deployment instructions.

## 📊 Container Services Comparison

| Service | Best For | Monthly Cost (Est.) | Pros | Cons |
|---------|----------|-------------------|------|------|
| **Container Instances (ACI)** | Simple apps, burst workloads | $15-45 | Easy setup, pay-per-second | No auto-scaling, limited features |
| **Container Apps** | Modern microservices | $25-80 | Auto-scaling, HTTPS, managed | Newer service, learning curve |
| **Kubernetes Service (AKS)** | Enterprise, complex apps | $75-300+ | Full Kubernetes, enterprise features | Complex, higher costs |

## 🚀 Option 1: Azure Container Instances (ACI)

### **Cost Analysis**
- **Container**: 1 vCPU, 1.5GB RAM = ~$35/month (always on)
- **PostgreSQL**: B1ms Flexible Server = ~$12/month
- **Azure DNS**: ~$0.50/month
- **Storage**: 10GB = ~$2/month
- **Total**: **~$50/month**

### **Deployment Steps**

#### 1.1 Create Container Registry
```bash
# Create Azure Container Registry
az acr create \
  --resource-group flask-notes-rg \
  --name flasknotesacr \
  --sku Basic \
  --admin-enabled true

# Get login server
ACR_LOGIN_SERVER=$(az acr show --name flasknotesacr --resource-group flask-notes-rg --query loginServer --output tsv)
```

#### 1.2 Build and Push Image
```bash
# Login to ACR
az acr login --name flasknotesacr

# Build and push image
docker build -t $ACR_LOGIN_SERVER/flask-notes:latest .
docker push $ACR_LOGIN_SERVER/flask-notes:latest
```

#### 1.3 Deploy Container Instance
```bash
# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name flasknotesacr --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name flasknotesacr --query passwords[0].value --output tsv)

# Create container instance
az container create \
  --resource-group flask-notes-rg \
  --name flask-notes-container \
  --image $ACR_LOGIN_SERVER/flask-notes:latest \
  --cpu 1 \
  --memory 1.5 \
  --registry-login-server $ACR_LOGIN_SERVER \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --dns-name-label flask-notes-app \
  --ports 8000 \
  --environment-variables \
    FLASK_ENV=production \
    DATABASE_URL="postgresql://flaskadmin:YourPassword@flask-notes-db.postgres.database.azure.com:5432/notesdb" \
    SECRET_KEY="your-secret-key" \
  --restart-policy Always
```

### **ACI with Custom Domain**
```bash
# Create Application Gateway for custom domain
az network application-gateway create \
  --name flask-notes-gateway \
  --resource-group flask-notes-rg \
  --location eastus \
  --capacity 1 \
  --sku Standard_Small \
  --public-ip-address flask-notes-public-ip \
  --vnet-name flask-notes-vnet \
  --subnet gateway-subnet \
  --servers flask-notes-app.eastus.azurecontainer.io
```

## 🔄 Option 2: Azure Container Apps (Recommended)

### **Cost Analysis**
- **Container Apps**: 0.5 vCPU, 1GB RAM = ~$25/month
- **PostgreSQL**: B1ms Flexible Server = ~$12/month  
- **Azure DNS**: ~$0.50/month
- **Load Balancer**: Included
- **SSL Certificate**: FREE
- **Total**: **~$38/month**

### **Deployment Steps**

#### 2.1 Create Container Apps Environment
```bash
# Install Container Apps extension
az extension add --name containerapp

# Create Container Apps environment
az containerapp env create \
  --name flask-notes-env \
  --resource-group flask-notes-rg \
  --location eastus
```

#### 2.2 Deploy Container App
```bash
# Create container app
az containerapp create \
  --name flask-notes-app \
  --resource-group flask-notes-rg \
  --environment flask-notes-env \
  --image $ACR_LOGIN_SERVER/flask-notes:latest \
  --registry-server $ACR_LOGIN_SERVER \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --target-port 8000 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 5 \
  --cpu 0.5 \
  --memory 1Gi \
  --env-vars \
    FLASK_ENV=production \
    DATABASE_URL="postgresql://flaskadmin:YourPassword@flask-notes-db.postgres.database.azure.com:5432/notesdb" \
    SECRET_KEY="your-secret-key"
```

#### 2.3 Configure Custom Domain
```bash
# Add custom domain
az containerapp hostname add \
  --hostname yourdomain.com \
  --name flask-notes-app \
  --resource-group flask-notes-rg

# Bind SSL certificate (automatic)
az containerapp ssl bind \
  --hostname yourdomain.com \
  --name flask-notes-app \
  --resource-group flask-notes-rg
```

### **Auto-scaling Configuration**
```yaml
# container-app-config.yaml
scale:
  minReplicas: 1
  maxReplicas: 10
  rules:
  - name: http-requests
    http:
      metadata:
        concurrentRequests: 50
  - name: cpu-usage
    custom:
      type: cpu
      metadata:
        type: Utilization
        value: "70"
```

## ⚙️ Option 3: Azure Kubernetes Service (AKS)

### **Cost Analysis**
- **AKS Cluster**: 2-node Standard_B2s = ~$75/month
- **Load Balancer**: Standard = ~$20/month
- **PostgreSQL**: GP_Gen5_1 = ~$55/month
- **Storage**: Premium SSD = ~$15/month
- **Azure DNS**: ~$0.50/month
- **Total**: **~$165/month**

### **Deployment Steps**

#### 3.1 Create AKS Cluster
```bash
# Create AKS cluster
az aks create \
  --resource-group flask-notes-rg \
  --name flask-notes-aks \
  --node-count 2 \
  --node-vm-size Standard_B2s \
  --generate-ssh-keys \
  --attach-acr flasknotesacr \
  --enable-managed-identity
```

#### 3.2 Configure kubectl
```bash
# Get credentials
az aks get-credentials --resource-group flask-notes-rg --name flask-notes-aks

# Verify connection
kubectl get nodes
```

#### 3.3 Deploy Application
```yaml
# kubernetes-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-notes-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: flask-notes
  template:
    metadata:
      labels:
        app: flask-notes
    spec:
      containers:
      - name: flask-notes
        image: flasknotesacr.azurecr.io/flask-notes:latest
        ports:
        - containerPort: 8000
        env:
        - name: FLASK_ENV
          value: "production"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: flask-secrets
              key: database-url
        - name: SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: flask-secrets
              key: secret-key
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: flask-notes-service
spec:
  selector:
    app: flask-notes
  ports:
  - port: 80
    targetPort: 8000
  type: LoadBalancer
```

#### 3.4 Deploy with kubectl
```bash
# Create secrets
kubectl create secret generic flask-secrets \
  --from-literal=database-url="postgresql://flaskadmin:YourPassword@flask-notes-db.postgres.database.azure.com:5432/notesdb" \
  --from-literal=secret-key="your-secret-key"

# Deploy application
kubectl apply -f kubernetes-deployment.yaml

# Get external IP
kubectl get service flask-notes-service
```

## 💰 Detailed Cost Comparison

### **Monthly Cost Breakdown**

#### 🟢 Container Instances (ACI) - Basic
| Component | Specification | Monthly Cost |
|-----------|---------------|--------------|
| Container | 1 vCPU, 1.5GB RAM, 720h | $35.28 |
| Container Registry | Basic | $5.00 |
| PostgreSQL | B1ms Burstable | $12.41 |
| Public IP | Static | $3.50 |
| Azure DNS | 1 zone | $0.50 |
| **Total** | | **$56.69** |

#### 🟡 Container Apps - Recommended  
| Component | Specification | Monthly Cost |
|-----------|---------------|--------------|
| Container App | 0.5 vCPU, 1GB RAM | $25.20 |
| Environment | Shared | $0.00 |
| Container Registry | Basic | $5.00 |
| PostgreSQL | B1ms Burstable | $12.41 |
| Azure DNS | 1 zone | $0.50 |
| **Total** | | **$43.11** |

#### 🔴 AKS - Enterprise
| Component | Specification | Monthly Cost |
|-----------|---------------|--------------|
| AKS Cluster | 2x Standard_B2s nodes | $75.60 |
| Load Balancer | Standard | $19.71 |
| Container Registry | Standard | $20.00 |
| PostgreSQL | GP_Gen5_1 | $54.00 |
| Storage | Premium SSD 50GB | $15.20 |
| Azure DNS | 1 zone | $0.50 |
| **Total** | | **$185.01** |

## 📈 Scaling Cost Analysis

### Container Apps Auto-scaling Costs
```
Base: 1 instance (0.5 vCPU, 1GB) = $25/month
Peak: 5 instances during traffic spikes = $125/month (only during spikes)
Average with moderate traffic = ~$40-60/month
```

### AKS Cluster Auto-scaling
```
Base: 2 nodes = $75/month
Peak: 5 nodes = $189/month
Average with auto-scaling = ~$100-150/month
```

## 🎯 Recommendation by Use Case

### **Personal Projects / Startups**
✅ **Container Apps** ($43/month)
- Built-in HTTPS and custom domains
- Auto-scaling included
- Managed infrastructure
- Easy deployment

### **Development / Testing**
✅ **Container Instances** ($57/month)
- Simple setup
- Pay-per-use model
- Good for burst workloads
- No management overhead

### **Enterprise / Production**
✅ **AKS** ($185/month)
- Full Kubernetes features
- Advanced networking
- Enterprise security
- Multi-environment support

## 🚀 Quick Deployment Scripts

### Container Apps Deployment Script
```bash
#!/bin/bash
# deploy-container-apps.sh

RESOURCE_GROUP="flask-notes-rg"
LOCATION="eastus"
ACR_NAME="flasknotesacr"
APP_NAME="flask-notes-app"
ENV_NAME="flask-notes-env"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create container registry
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic

# Build and push image
az acr build --registry $ACR_NAME --image flask-notes:latest .

# Create Container Apps environment
az containerapp env create \
  --name $ENV_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION

# Deploy container app
az containerapp create \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $ENV_NAME \
  --image $ACR_NAME.azurecr.io/flask-notes:latest \
  --target-port 8000 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 5

echo "Deployment complete!"
```

## 🔧 Production Optimizations

### **Container Apps Production Config**
```yaml
# container-apps-production.yaml
properties:
  configuration:
    ingress:
      external: true
      targetPort: 8000
      customDomains:
      - name: yourdomain.com
        certificateType: ManagedCertificate
    secrets:
    - name: database-url
      value: "postgresql://..."
    - name: secret-key
      value: "your-secret-key"
  template:
    containers:
    - image: flasknotesacr.azurecr.io/flask-notes:latest
      name: flask-notes
      resources:
        cpu: 0.5
        memory: 1Gi
    scale:
      minReplicas: 1
      maxReplicas: 10
      rules:
      - name: http-scaling
        http:
          metadata:
            concurrentRequests: 50
```

### **AKS Production Features**
- **Horizontal Pod Autoscaler**
- **Cluster Autoscaler**
- **Azure Active Directory Integration**
- **Network Policies**
- **Azure Monitor Integration**

## 🎉 Summary Recommendations

### **Best Value: Container Apps ($43/month)**
- Perfect balance of features and cost
- Built-in auto-scaling and HTTPS
- Managed infrastructure
- Modern serverless approach

### **Simplest: Container Instances ($57/month)**
- Easiest to understand and deploy
- Good for simple workloads
- Pay-per-second billing
- Quick startup

### **Most Powerful: AKS ($185/month)**
- Full Kubernetes ecosystem
- Enterprise-grade features
- Maximum flexibility
- Best for complex applications

**For your Flask Notes app, I recommend starting with Container Apps** - it provides the best balance of cost, features, and ease of management! 🚀
