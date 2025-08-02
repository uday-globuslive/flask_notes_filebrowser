from flask import Flask
from flask_login import LoginManager
from flask_migrate import Migrate
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = Flask(__name__)

# Configuration
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'your-secret-key-change-this-in-production')

# Enhanced Database configuration with user choice
def configure_database():
    """
    Configure database based on environment variables and user preference.
    
    Environment Variables:
    - DATABASE_TYPE: 'sqlite' or 'postgresql' (explicit choice)
    - DATABASE_URL: Full database connection string (takes precedence)
    - SQLITE_PATH: Custom SQLite database path (default: instance/notes_app.db)
    - POSTGRES_HOST, POSTGRES_PORT, POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB: PostgreSQL connection details
    """
    
    # Check for explicit database type preference
    db_type = os.getenv('DATABASE_TYPE', '').lower()
    database_url = os.getenv('DATABASE_URL', '')
    
    print("🔧 Configuring database...")
    
    if database_url:
        # Use explicit DATABASE_URL (takes highest precedence)
        app.config['SQLALCHEMY_DATABASE_URI'] = database_url
        if 'postgresql://' in database_url:
            print("✅ Using PostgreSQL database from DATABASE_URL")
        elif 'sqlite://' in database_url:
            print("✅ Using SQLite database from DATABASE_URL")
        else:
            print(f"✅ Using custom database from DATABASE_URL")
            
    elif db_type == 'postgresql':
        # PostgreSQL configuration from individual environment variables
        pg_host = os.getenv('POSTGRES_HOST', 'localhost')
        pg_port = os.getenv('POSTGRES_PORT', '5432')
        pg_user = os.getenv('POSTGRES_USER', 'postgres')
        pg_pass = os.getenv('POSTGRES_PASSWORD', 'password')
        pg_db = os.getenv('POSTGRES_DB', 'notesdb')
        
        app.config['SQLALCHEMY_DATABASE_URI'] = f'postgresql://{pg_user}:{pg_pass}@{pg_host}:{pg_port}/{pg_db}'
        print(f"✅ Using PostgreSQL: {pg_user}@{pg_host}:{pg_port}/{pg_db}")
        
    elif db_type == 'sqlite' or not db_type:
        # SQLite configuration (default)
        sqlite_path = os.getenv('SQLITE_PATH', 'instance/notes_app.db')
        
        # Ensure absolute path for SQLite
        if not os.path.isabs(sqlite_path):
            sqlite_path = os.path.join(app.root_path, sqlite_path)
        
        # Ensure directory exists
        sqlite_dir = os.path.dirname(sqlite_path)
        if sqlite_dir and not os.path.exists(sqlite_dir):
            os.makedirs(sqlite_dir, exist_ok=True)
            print(f"📁 Created directory: {sqlite_dir}")
        
        app.config['SQLALCHEMY_DATABASE_URI'] = f'sqlite:///{sqlite_path}'
        print(f"✅ Using SQLite: {sqlite_path}")
        
    else:
        # Fallback to SQLite if invalid type specified
        print(f"⚠️  Unknown DATABASE_TYPE '{db_type}', falling back to SQLite")
        app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///instance/notes_app.db'
        print("✅ Using SQLite: instance/notes_app.db")

# Configure the database
configure_database()

app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['UPLOAD_FOLDER'] = os.path.join(app.root_path, 'uploads')
app.config['MAX_CONTENT_LENGTH'] = int(os.getenv('MAX_CONTENT_LENGTH', 16 * 1024 * 1024))

# Initialize models first
from models import db, User

# Initialize extensions
db.init_app(app)
migrate = Migrate(app, db)
login_manager = LoginManager(app)
login_manager.login_view = 'login'
login_manager.login_message_category = 'info'

# Create upload directory if it doesn't exist
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

# Import routes after models are defined
from routes import register_routes
register_routes(app)

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(debug=True)