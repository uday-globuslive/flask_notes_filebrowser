# Flask Notes App - Complete Project Structure

## 📁 Project Overview
A comprehensive Flask web application for creating, sharing, and managing notes and files with user authentication and PostgreSQL/SQLite database support.

## 🗂️ Complete Folder Structure

```
flask_notes_app/
├── 📄 app.py                          # Main Flask application entry point
├── 📄 models.py                       # Database models (User, Note, Folder, File, etc.)
├── 📄 routes.py                       # All application routes and endpoints
├── 📄 requirements.txt                # Python dependencies
├── 📄 README.md                       # Detailed project documentation
├── 📄 .env.example                    # Environment variables template
├── 📄 setup.bat                       # Windows setup script
├── 📄 setup.sh                        # Linux/Mac setup script
├── 
├── 📁 venv/                           # Python virtual environment
│   ├── Scripts/                       # Windows executables
│   └── Lib/                          # Python packages
├── 
├── 📁 instance/                       # Flask instance folder
│   └── 📄 notes_app.db              # SQLite database file
├── 
├── 📁 migrations/                     # Database migration files
│   ├── 📄 alembic.ini                # Alembic configuration
│   ├── 📄 env.py                     # Migration environment
│   ├── 📄 README                     # Migration documentation
│   ├── 📄 script.py.mako             # Migration template
│   └── 📁 versions/                  # Migration versions
│       └── 📄 f178a649251f_initial_migration.py
├── 
├── 📁 templates/                      # HTML templates
│   ├── 📄 base.html                  # Base template with navigation
│   ├── 📄 index.html                 # Home page
│   ├── 📄 login.html                 # User login page
│   ├── 📄 register.html              # User registration page
│   ├── 📄 dashboard.html             # User dashboard
│   ├── 📄 create_note.html           # Create new note
│   ├── 📄 edit_note.html             # Edit existing note
│   ├── 📄 view_note.html             # View note details
│   ├── 📄 share_note.html            # Share note with users
│   ├── 📄 create_folder.html         # Create new folder
│   ├── 📄 view_folder.html           # View folder contents
│   ├── 📄 share_folder.html          # Share folder with users
│   ├── 📄 upload_file.html           # Upload files to folder
│   ├── 📄 public_drop.html           # Public file drop interface
│   └── 📁 errors/                    # Error page templates
│       ├── 📄 403.html               # Access forbidden
│       ├── 📄 404.html               # Page not found
│       └── 📄 500.html               # Internal server error
├── 
├── 📁 static/                         # Static assets
│   ├── 📁 css/                       # Stylesheets
│   │   └── 📄 style.css              # Custom CSS styles
│   └── 📁 js/                        # JavaScript files
│       └── 📄 app.js                 # Custom JavaScript functions
├── 
└── 📁 uploads/                        # File upload directory
    └── (uploaded files stored here)
```

## 🔧 Core Files Description

### **app.py** - Main Application
- Flask application initialization
- Database and migration setup
- User authentication configuration
- File upload settings
- Extension initialization

### **models.py** - Database Models
- **User**: User authentication and profile
- **Note**: Notes with sharing capabilities
- **Folder**: File organization containers
- **File**: Uploaded file metadata
- **SharedNote**: Note sharing relationships
- **SharedFolder**: Folder sharing relationships

### **routes.py** - Application Routes
- Authentication routes (login, register, logout)
- Note management (create, read, update, delete, share)
- Folder management (create, view, share, delete)
- File operations (upload, download, delete)
- Public access routes
- API endpoints

## 📋 Template Structure

### **Base Templates**
- `base.html`: Main layout with navigation and Bootstrap
- `index.html`: Public homepage with featured content

### **Authentication Templates**
- `login.html`: User login form
- `register.html`: New user registration
- `dashboard.html`: User's personal dashboard

### **Note Templates**
- `create_note.html`: Create new note form
- `edit_note.html`: Edit existing note
- `view_note.html`: Display note content
- `share_note.html`: Share note with other users

### **Folder & File Templates**
- `create_folder.html`: Create new folder
- `view_folder.html`: Browse folder contents
- `share_folder.html`: Share folder with users
- `upload_file.html`: File upload interface
- `public_drop.html`: Anonymous file upload

### **Error Templates**
- `403.html`: Access forbidden page
- `404.html`: Page not found
- `500.html`: Server error page

## 🎨 Static Assets

### **CSS (`static/css/style.css`)**
- Custom styling for the application
- Responsive design utilities
- File upload styling
- Card hover effects
- Drag and drop styles

### **JavaScript (`static/js/app.js`)**
- File upload preview functionality
- Drag and drop file handling
- Auto-save capabilities
- Search functionality
- Confirmation dialogs
- Toast notifications

## 🗄️ Database Structure

### **Tables Created**
1. **user** - User accounts and authentication
2. **note** - User notes with metadata
3. **folder** - File organization containers
4. **file** - Uploaded file information
5. **shared_note** - Note sharing relationships
6. **shared_folder** - Folder sharing relationships

### **Key Features**
- User authentication with password hashing
- Public and private content
- File sharing with specific users
- Anonymous file uploads to public folders
- Full CRUD operations for all entities

## 🚀 Setup Instructions

### **Quick Start**
1. Run `setup.bat` (Windows) or `setup.sh` (Linux/Mac)
2. Edit `.env` file with your configuration
3. Activate virtual environment: `venv\Scripts\activate`
4. Run application: `python app.py`
5. Open browser to `http://localhost:5000`

### **Manual Setup**
1. Create virtual environment: `python -m venv venv`
2. Activate environment: `venv\Scripts\activate`
3. Install dependencies: `pip install -r requirements.txt`
4. Initialize database: `flask db upgrade`
5. Start application: `python app.py`

## 🔒 Security Features
- Password hashing with Werkzeug
- CSRF protection with Flask-WTF
- File upload restrictions
- Access control for private content
- SQL injection prevention

## 📦 Dependencies
- **Flask**: Web framework
- **Flask-SQLAlchemy**: Database ORM
- **Flask-Login**: User session management
- **Flask-Migrate**: Database migrations
- **Flask-WTF**: Form handling and CSRF protection
- **WTForms**: Form validation
- **Werkzeug**: WSGI utilities and security
- **python-dotenv**: Environment variable management

## 🌐 Deployment Ready
- Gunicorn configuration for production
- Environment variable support
- SQLite for development, PostgreSQL for production
- Static file serving
- Error handling

This structure provides a complete, production-ready Flask application with all modern web development best practices implemented.
