# Flask Notes App - Complete Beginner's Guide

A comprehensive web application for creating, sharing, and managing notes and files with **flexible database support** (SQLite & PostgreSQL).

## 🗄️ Database Options

**Choose your database based on your needs:**

- **🔧 SQLite** - Perfect for development, testing, and small deployments
- **🚀 PostgreSQL** - Recommended for production and high-traffic applications

**Quick Setup:**
```bash
# Windows: Interactive database configuration
configure-database.bat

# Linux/Mac: Interactive database configuration  
chmod +x configure-database.sh && ./configure-database.sh

# Manual: Copy configuration files
cp .env.sqlite .env      # For SQLite
cp .env.postgresql .env  # For PostgreSQL
```

See [DATABASE_CONFIG.md](DATABASE_CONFIG.md) for detailed configuration options.

## 🚀 Features

### 🔐 User Authentication
- User registration and login system
- Secure password hashing with Werkzeug
- Session management with Flask-Login
- User logout functionality

### 📝 Notes Management
- Create, edit, and delete personal notes
- Make notes public (visible to everyone) or private
- Share notes with specific users by username
- Rich text content support
- View shared notes from other users

### 📁 File & Folder Management
- Create folders to organize files
- Upload single or multiple files to folders
- Support for various file types (documents, images, archives)
- Public and private folder sharing
- Share folders with specific users
- File download functionality
- File deletion (by owner or uploader)

### 🌐 Public Features
- Public notes visible to everyone without login
- Public folders with file browsing
- Anonymous file uploads to designated public folders
- File drop zones for easy anonymous uploads
- No registration required for viewing public content

### 🔄 Advanced Sharing System
- Share notes with specific users by username
- Share folders with specific users
- Public sharing for broader community access
- Anonymous file drop functionality for public folders

## 📋 Prerequisites (Must Install First)

### 1. Python 3.7 or Higher
- Download from: https://python.org/downloads/
- During installation, CHECK "Add Python to PATH"
- Verify installation: Open Command Prompt and type `python --version`

### 2. PostgreSQL Database (Recommended for Production)
- Download from: https://www.postgresql.org/download/
- During installation, remember your password for 'postgres' user
- Default port: 5432
- **Alternative**: You can start with SQLite (no installation needed) and upgrade later

### 3. Git (Optional but Recommended)
- Download from: https://git-scm.com/download/win

## 🛠️ Installation & Setup

### Method 1: Automated Setup (Recommended for Beginners)

1. **Open Command Prompt**
   - Press `Windows + R`, type `cmd`, press Enter

2. **Navigate to the project folder**
   ```cmd
   cd "c:\Users\uday\Desktop\test1\flask_notes_app"
   ```

3. **Run the automated setup**
   ```cmd
   setup-base-python.bat
   ```
   
   This will:
   - Install all Python dependencies in your base Python environment
   - Create configuration files
   - Set up database migrations
   - Create necessary directories

4. **Start the application**
   ```cmd
   python app.py
   ```
   
   Or use the quick start script:
   ```cmd
   run.bat
   ```

### Method 2: Manual Setup (For Learning)

1. **Open Command Prompt and navigate to project**
   ```cmd
   cd "c:\Users\uday\Desktop\test1\flask_notes_app"
   ```

2. **Install dependencies**
   ```cmd
   pip install -r requirements.txt --user
   ```

3. **Create environment file**
   ```cmd
   copy .env.example .env
   ```

4. **Edit .env file** (See Database Setup section)

5. **Create uploads directory**
   ```cmd
   mkdir uploads
   ```

6. **Initialize database (optional)**
   ```cmd
   flask db init
   flask db migrate -m "Initial migration"
   flask db upgrade
   ```

7. **Run the application**
   ```cmd
   python app.py
   ```

## 🗄️ Database Setup

### Option A: PostgreSQL (Recommended for Production)

1. **Install PostgreSQL** (if not already installed)
   - Download from https://www.postgresql.org/download/
   - Remember the password you set for 'postgres' user

2. **Create database**
   ```cmd
   psql -U postgres -c "CREATE DATABASE notesdb;"
   ```
   (Enter your postgres password when prompted)

3. **Edit .env file**
   ```env
   DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/notesdb
   SECRET_KEY=your-secret-key-change-this-in-production
   FLASK_ENV=development
   FLASK_DEBUG=True
   ```

### Option B: SQLite (Easy for Development)

1. **Edit .env file**
   ```env
   SECRET_KEY=your-secret-key-change-this-in-production
   FLASK_ENV=development
   FLASK_DEBUG=True
   ```
   (Remove or comment out the DATABASE_URL line)

2. SQLite database file will be created automatically

## 🚀 Running the Application

1. **Open Command Prompt**

2. **Navigate to project directory**
   ```cmd
   cd "c:\Users\uday\Desktop\test1\flask_notes_app"
   ```

3. **Start the application**
   ```cmd
   python app.py
   ```
   
   Or use the quick start script:
   ```cmd
   run.bat
   ```

4. **Open your web browser**
   - Go to: http://localhost:5000
   - You should see the Flask Notes App homepage

## 📱 Using the Application

### First Steps
1. **Register a new account**
   - Click "Register" in the top menu
   - Fill in username, email, and password
   - Click "Register"

2. **Login**
   - Click "Login" in the top menu
   - Enter your username and password
   - Click "Login"

### Creating Notes
1. **Create a note**
   - Go to Dashboard → "New Note"
   - Enter title and content
   - Check "Make Public" if you want everyone to see it
   - Click "Create Note"

2. **Share a note**
   - View your note
   - Click "Share Note"
   - Enter username of person to share with
   - Click "Share"

### Managing Files and Folders
1. **Create a folder**
   - Go to Dashboard → "New Folder"
   - Enter folder name and description
   - Check "Make Public" for public access
   - Check "Allow File Drop" for anonymous uploads
   - Click "Create Folder"

2. **Upload files**
   - View a folder
   - Click "Upload Files"
   - Select single or multiple files
   - Click "Upload"

3. **Public file drop**
   - Create a public folder with "Allow File Drop" enabled
   - Share the folder URL with others
   - Anyone can upload files without logging in

## 🔧 Troubleshooting

### Common Issues

1. **"Python is not recognized"**
   - Reinstall Python and check "Add Python to PATH"
   - Restart Command Prompt

2. **"No module named 'flask'"**
   - Install dependencies: `pip install -r requirements.txt --user`

3. **Database connection errors**
   - Check PostgreSQL is running: `net start postgresql-x64-14`
   - Verify database exists: `psql -U postgres -l`
   - Check .env file has correct credentials

4. **Port 5000 already in use**
   - Change port in app.py: `app.run(debug=True, port=5001)`
   - Or stop other applications using port 5000

5. **File upload errors**
   - Check uploads folder exists and has write permissions
   - Verify file size is under 16MB limit

### Getting Help

1. **Check application logs**
   - Look at Command Prompt where you ran `python app.py`
   - Error messages will appear there

2. **Reset database**
   ```cmd
   del notes_app.db
   python app.py
   ```

3. **Reinstall dependencies**
   ```cmd
   pip install -r requirements.txt --user --force-reinstall
   ```

## 🌐 Deployment (Production)

### For Production Deployment:

1. **Use PostgreSQL** (not SQLite)
2. **Change SECRET_KEY** in .env file
3. **Set FLASK_ENV=production**
4. **Use a production WSGI server** like Gunicorn:
   ```cmd
   pip install gunicorn
   gunicorn -w 4 -b 0.0.0.0:8000 app:app
   ```

## 📁 Project Structure
```
flask_notes_app/
├── app.py              # Main Flask application
├── models.py           # Database models
├── routes.py           # URL routes and view functions
├── requirements.txt    # Python dependencies
├── setup.bat          # Automated setup script
├── .env.example       # Environment variables template
├── templates/         # HTML templates
├── static/           # CSS, JS, images
├── uploads/          # User uploaded files
└── migrations/       # Database migration files
```

## 🔒 Security Features
- Password hashing with Werkzeug
- CSRF protection with Flask-WTF
- File type validation for uploads
- User session management
- SQL injection protection with SQLAlchemy

## 📄 Supported File Types
- Documents: txt, pdf, doc, docx, xls, xlsx, ppt, pptx
- Images: png, jpg, jpeg, gif
- Archives: zip, rar

---

**Note**: This application is designed for learning purposes. For production use, implement additional security measures, monitoring, and backups.
   
   # Initialize database
   flask db init
   flask db migrate -m "Initial migration"
   flask db upgrade
   ```

4. **Create upload directory**
   ```bash
   mkdir uploads
   ```

## Configuration

### Environment Variables (.env file)
```env
DATABASE_URL=postgresql://username:password@localhost:5432/notesdb
SECRET_KEY=your-secret-key-here
UPLOAD_FOLDER=uploads
MAX_CONTENT_LENGTH=16777216  # 16MB
FLASK_ENV=development
FLASK_DEBUG=True
```

### Database Configuration
- Default database: PostgreSQL
- Database name: `notesdb`
- Update connection string in `app.py` or `.env` file

## Usage Guide

### For Beginners

1. **Register an Account**
   - Go to `/register`
   - Create username, email, and password
   - Login with your credentials

2. **Create Your First Note**
   - Click "Create New Note" on dashboard
   - Add title and content
   - Choose to make it public or private
   - Save the note

3. **Create a Folder**
   - Click "Create New Folder" on dashboard
   - Name your folder and add description
   - Enable "public" for everyone to see
   - Enable "file drop" to allow anonymous uploads

4. **Upload Files**
   - Go to any folder you own
   - Click "Upload Files"
   - Select single or multiple files
   - Files are automatically saved

5. **Share Content**
   - Use "Share" button on notes or folders
   - Enter username to share with specific user
   - Or make content public for everyone

### Key Features Explained

#### Public File Drop
- Create a public folder with "file drop" enabled
- Anyone can visit the folder and upload files
- No login required for uploads
- Perfect for collecting files from others

#### Sharing System
- **Private**: Only you can see
- **Shared**: Specific users can access
- **Public**: Everyone can view

#### File Management
- Supported file types: txt, pdf, images, documents, archives
- 16MB file size limit
- Download and delete capabilities
- File size and upload information displayed

## Project Structure

```
flask_notes_app/
├── app.py                 # Main Flask application
├── models.py              # Database models
├── routes.py              # Application routes
├── requirements.txt       # Python dependencies
├── setup.bat             # Windows setup script
├── setup.sh              # Linux/Mac setup script
├── .env.example          # Environment variables template
├── templates/            # HTML templates
│   ├── base.html
│   ├── index.html
│   ├── login.html
│   ├── register.html
│   ├── dashboard.html
│   ├── create_note.html
│   ├── view_note.html
│   ├── edit_note.html
│   ├── share_note.html
│   ├── create_folder.html
│   ├── view_folder.html
│   ├── upload_file.html
│   ├── share_folder.html
│   ├── public_drop.html
│   └── errors/
│       ├── 403.html
│       ├── 404.html
│       └── 500.html
├── uploads/              # File upload directory
└── venv/                 # Virtual environment
```

## Database Schema

### Tables
- **users**: User accounts and authentication
- **notes**: User notes with sharing capabilities
- **folders**: File organization containers
- **files**: Uploaded file metadata
- **shared_notes**: Note sharing relationships
- **shared_folders**: Folder sharing relationships

## Deployment

### Local Development
```bash
python app.py
```

### Production Deployment

1. **Using Gunicorn (Linux)**
   ```bash
   pip install gunicorn
   gunicorn -w 4 -b 0.0.0.0:8000 app:app
   ```

2. **Using Waitress (Windows)**
   ```bash
   pip install waitress
   waitress-serve --host=0.0.0.0 --port=8000 app:app
   ```

3. **Cloud Deployment**
   - **Heroku**: Add Procfile with `web: gunicorn app:app`
   - **Railway**: Works out of the box
   - **Render**: Configure build and start commands

### Environment Setup for Production
- Set `FLASK_ENV=production`
- Use strong `SECRET_KEY`
- Configure production database
- Set up proper file storage (AWS S3, etc.)

## Security Features

- Password hashing with Werkzeug
- CSRF protection with Flask-WTF
- File upload restrictions
- SQL injection prevention with SQLAlchemy
- Access control for private content

## Troubleshooting

### Common Issues

1. **Database Connection Error**
   - Check PostgreSQL is running
   - Verify database credentials
   - Ensure database exists

2. **File Upload Issues**
   - Check upload directory exists
   - Verify file size limits
   - Check file type restrictions

3. **Permission Errors**
   - Ensure proper file permissions
   - Check folder write permissions

### Debug Mode
- Set `FLASK_DEBUG=True` in development
- Check console for error messages
- Use browser developer tools

## Contributing

1. Fork the repository
2. Create feature branch
3. Make changes
4. Test thoroughly
5. Submit pull request

## License

This project is open source and available under the MIT License.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review error messages in console
3. Ensure all dependencies are installed
4. Verify database configuration

---

**Happy note-taking and file sharing!** 🎉
