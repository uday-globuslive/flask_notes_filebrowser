# Database Configuration Guide

## 🗄️ Flexible Database Support

Your Flask Notes app now supports both **SQLite** and **PostgreSQL** databases with easy switching between them.

## 🚀 Quick Start

### **Option 1: Use Configuration Scripts (Recommended)**

#### Windows:
```bash
# Run the interactive configuration script
configure-database.bat
```

#### Linux/Mac:
```bash
# Make script executable and run
chmod +x configure-database.sh
./configure-database.sh
```

### **Option 2: Manual Configuration**

#### For SQLite (Development):
```bash
# Copy SQLite configuration
cp .env.sqlite .env

# Create database
python -c "from app import app, db; app.app_context().push(); db.create_all()"
```

#### For PostgreSQL (Production):
```bash
# Copy PostgreSQL configuration
cp .env.postgresql .env

# Edit .env with your PostgreSQL details
# Then create database
python -c "from app import app, db; app.app_context().push(); db.create_all()"
```

## 🔧 Configuration Options

### **Environment Variables**

The app reads the following environment variables (in order of precedence):

1. **`DATABASE_URL`** - Full database connection string (highest precedence)
2. **`DATABASE_TYPE`** - Explicit database type (`sqlite` or `postgresql`)
3. **Individual database parameters** (see below)

### **SQLite Configuration**

```bash
# Basic SQLite setup
DATABASE_TYPE=sqlite
SQLITE_PATH=instance/notes_app.db

# Custom SQLite paths
SQLITE_PATH=data/my_notes.db                    # Relative path
SQLITE_PATH=/absolute/path/to/database.db       # Absolute path
SQLITE_PATH=C:\Users\Name\AppData\notes.db      # Windows absolute path
```

### **PostgreSQL Configuration**

```bash
# Method 1: Individual parameters
DATABASE_TYPE=postgresql
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_password
POSTGRES_DB=notesdb

# Method 2: Full connection string (takes precedence)
DATABASE_URL=postgresql://username:password@host:port/database
```

## 📋 Configuration Examples

### **Development (SQLite)**
```bash
# .env file for local development
DATABASE_TYPE=sqlite
SQLITE_PATH=instance/dev_notes.db
SECRET_KEY=dev-secret-key
FLASK_ENV=development
UPLOAD_FOLDER=uploads
MAX_CONTENT_LENGTH=16777216
```

### **Production (PostgreSQL)**
```bash
# .env file for production
DATABASE_TYPE=postgresql
DATABASE_URL=postgresql://user:pass@prod-server:5432/notesdb
SECRET_KEY=your-super-secure-production-key
FLASK_ENV=production
UPLOAD_FOLDER=/app/uploads
MAX_CONTENT_LENGTH=16777216
```

### **Docker Development**
```bash
# .env file for Docker Compose
DATABASE_TYPE=postgresql
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_USER=flaskuser
POSTGRES_PASSWORD=flaskpass
POSTGRES_DB=notesdb
```

### **Azure Production**
```bash
# .env file for Azure deployment
DATABASE_URL=postgresql://admin:password@server.postgres.database.azure.com:5432/notesdb
SECRET_KEY=azure-production-secret-key
FLASK_ENV=production
UPLOAD_FOLDER=/tmp/uploads
```

## 🔄 Switching Between Databases

### **From SQLite to PostgreSQL**

1. **Backup your SQLite data** (if needed):
   ```bash
   # Export data from SQLite
   python -c "
   from app import app, db, User, Note, Folder
   import json
   
   with app.app_context():
       users = [{'username': u.username, 'email': u.email} for u in User.query.all()]
       notes = [{'title': n.title, 'content': n.content} for n in Note.query.all()]
       
   with open('backup.json', 'w') as f:
       json.dump({'users': users, 'notes': notes}, f)
   print('Data exported to backup.json')
   "
   ```

2. **Switch to PostgreSQL**:
   ```bash
   # Copy PostgreSQL configuration
   cp .env.postgresql .env
   
   # Edit .env with your PostgreSQL details
   nano .env  # or notepad .env on Windows
   
   # Initialize new database
   python -c "from app import app, db; app.app_context().push(); db.create_all()"
   ```

3. **Import data** (if needed):
   ```bash
   # Import data to PostgreSQL
   python -c "
   from app import app, db, User, Note
   import json
   
   with open('backup.json', 'r') as f:
       data = json.load(f)
   
   with app.app_context():
       for user_data in data['users']:
           if not User.query.filter_by(username=user_data['username']).first():
               user = User(username=user_data['username'], email=user_data['email'])
               user.set_password('changeme')  # User will need to reset
               db.session.add(user)
       db.session.commit()
   print('Data imported successfully')
   "
   ```

### **From PostgreSQL to SQLite**

Similar process, but in reverse:

1. **Export PostgreSQL data**
2. **Switch to SQLite configuration**
3. **Import data into SQLite**

## 🐳 Docker Support

### **Using Docker Compose**

The included `docker-compose.yml` automatically sets up PostgreSQL:

```bash
# Start with PostgreSQL
docker-compose up -d

# Use SQLite instead (modify docker-compose.yml)
# Change environment variables in the flask-app service:
# - DATABASE_TYPE=sqlite
# - SQLITE_PATH=/app/data/notes.db
```

## ☁️ Cloud Deployment

### **Azure App Service**
```bash
# Set environment variables in Azure
az webapp config appsettings set \
  --resource-group your-rg \
  --name your-app \
  --settings DATABASE_URL="postgresql://..."
```

### **Heroku**
```bash
# Heroku automatically provides DATABASE_URL
# Just ensure your app reads it correctly (it does!)
```

### **AWS/GCP**
```bash
# Set DATABASE_URL environment variable
# or use individual POSTGRES_* variables
```

## 🛠️ Advanced Configuration

### **Connection Pooling**

For PostgreSQL in production, you can add connection pooling:

```python
# Add to app.py if needed
app.config['SQLALCHEMY_ENGINE_OPTIONS'] = {
    'pool_size': 10,
    'pool_recycle': 120,
    'pool_pre_ping': True
}
```

### **Multiple Databases**

You can configure different databases for different environments:

```bash
# .env.development
DATABASE_TYPE=sqlite
SQLITE_PATH=dev_notes.db

# .env.testing  
DATABASE_TYPE=sqlite
SQLITE_PATH=test_notes.db

# .env.production
DATABASE_URL=postgresql://prod-connection-string
```

## 🔍 Troubleshooting

### **Common Issues**

1. **SQLite file not found**
   ```bash
   # Check if directory exists
   ls -la instance/
   
   # Create if missing
   mkdir -p instance
   ```

2. **PostgreSQL connection failed**
   ```bash
   # Test connection manually
   psql -h localhost -U postgres -d notesdb
   
   # Check if database exists
   psql -h localhost -U postgres -c "\l"
   ```

3. **Permission denied on SQLite**
   ```bash
   # Fix permissions
   chmod 666 instance/notes_app.db
   chmod 755 instance/
   ```

### **Debugging Commands**

```bash
# Check current database configuration
python -c "from app import app; print(app.config['SQLALCHEMY_DATABASE_URI'])"

# Test database connection
python -c "from app import app, db; app.app_context().push(); db.engine.execute('SELECT 1')"

# List all tables
python -c "from app import app, db; from sqlalchemy import inspect; app.app_context().push(); print(inspect(db.engine).get_table_names())"
```

## 💡 Best Practices

### **Development**
- ✅ Use **SQLite** for local development
- ✅ Keep database files in `instance/` directory
- ✅ Add `instance/` to `.gitignore`

### **Testing**
- ✅ Use separate SQLite database for tests
- ✅ Set `DATABASE_TYPE=sqlite` in test environment
- ✅ Clean database between tests

### **Production**
- ✅ Use **PostgreSQL** for production
- ✅ Use environment variables for connection details
- ✅ Enable connection pooling
- ✅ Set up database backups
- ✅ Use read replicas for high traffic

### **Security**
- ✅ Never commit database passwords to Git
- ✅ Use strong passwords for PostgreSQL
- ✅ Restrict database access to application servers only
- ✅ Use SSL connections for remote databases

## 📊 Performance Comparison

| Feature | SQLite | PostgreSQL |
|---------|--------|------------|
| **Setup Complexity** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Performance (Small)** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Performance (Large)** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Concurrent Users** | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Backup/Recovery** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Cloud Support** | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Cost** | Free | Varies |

## 📚 Additional Resources

- **SQLite Documentation**: [sqlite.org](https://www.sqlite.org/docs.html)
- **PostgreSQL Documentation**: [postgresql.org](https://www.postgresql.org/docs/)
- **Flask-SQLAlchemy**: [flask-sqlalchemy.palletsprojects.com](https://flask-sqlalchemy.palletsprojects.com/)
- **SQLAlchemy**: [sqlalchemy.org](https://www.sqlalchemy.org/)

---

**Your Flask Notes app now supports flexible database configuration! 🎉**

Choose SQLite for development and PostgreSQL for production, or switch between them anytime using the configuration scripts.
