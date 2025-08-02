#!/bin/bash

# Database Configuration Script
# This script helps users easily switch between SQLite and PostgreSQL

set -e

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

# Function to setup SQLite
setup_sqlite() {
    print_header "Setting up SQLite Database"
    
    # Copy SQLite environment file
    if [ -f ".env.sqlite" ]; then
        cp .env.sqlite .env
        print_info "✅ Copied SQLite configuration to .env"
    else
        print_error "❌ .env.sqlite file not found!"
        exit 1
    fi
    
    # Create instance directory
    mkdir -p instance
    print_info "📁 Created instance directory for SQLite database"
    
    # Initialize database
    print_info "🔧 Initializing SQLite database..."
    python -c "
from app import app, db
with app.app_context():
    db.create_all()
    print('✅ SQLite database initialized successfully!')
"
    
    print_info "🎉 SQLite setup complete!"
    echo -e "${GREEN}Your app is now configured to use SQLite database at: instance/notes_app.db${NC}"
}

# Function to setup PostgreSQL
setup_postgresql() {
    print_header "Setting up PostgreSQL Database"
    
    # Check if PostgreSQL is installed
    if ! command -v psql &> /dev/null; then
        print_warning "PostgreSQL client not found. Please install PostgreSQL first."
        echo "Install instructions:"
        echo "  Ubuntu/Debian: sudo apt-get install postgresql postgresql-client"
        echo "  macOS: brew install postgresql"
        echo "  Windows: Download from https://www.postgresql.org/download/"
        echo ""
    fi
    
    # Copy PostgreSQL environment file
    if [ -f ".env.postgresql" ]; then
        cp .env.postgresql .env
        print_info "✅ Copied PostgreSQL configuration to .env"
    else
        print_error "❌ .env.postgresql file not found!"
        exit 1
    fi
    
    # Get database details from user
    echo "Please provide PostgreSQL connection details:"
    read -p "Host (default: localhost): " PG_HOST
    read -p "Port (default: 5432): " PG_PORT
    read -p "Username (default: postgres): " PG_USER
    read -s -p "Password: " PG_PASS
    echo
    read -p "Database name (default: notesdb): " PG_DB
    
    # Use defaults if empty
    PG_HOST=${PG_HOST:-localhost}
    PG_PORT=${PG_PORT:-5432}
    PG_USER=${PG_USER:-postgres}
    PG_DB=${PG_DB:-notesdb}
    
    # Update .env file with user inputs
    sed -i "s/POSTGRES_HOST=.*/POSTGRES_HOST=$PG_HOST/" .env
    sed -i "s/POSTGRES_PORT=.*/POSTGRES_PORT=$PG_PORT/" .env
    sed -i "s/POSTGRES_USER=.*/POSTGRES_USER=$PG_USER/" .env
    sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$PG_PASS/" .env
    sed -i "s/POSTGRES_DB=.*/POSTGRES_DB=$PG_DB/" .env
    
    print_info "✅ Updated PostgreSQL configuration"
    
    # Test connection and create database
    print_info "🔧 Testing PostgreSQL connection..."
    
    # Create database if it doesn't exist
    PGPASSWORD=$PG_PASS psql -h $PG_HOST -p $PG_PORT -U $PG_USER -d postgres -c "CREATE DATABASE $PG_DB;" 2>/dev/null || true
    
    # Test connection
    if PGPASSWORD=$PG_PASS psql -h $PG_HOST -p $PG_PORT -U $PG_USER -d $PG_DB -c "\q" &>/dev/null; then
        print_info "✅ PostgreSQL connection successful!"
        
        # Initialize database
        print_info "🔧 Initializing PostgreSQL database..."
        python -c "
from app import app, db
with app.app_context():
    db.create_all()
    print('✅ PostgreSQL database initialized successfully!')
"
        
        print_info "🎉 PostgreSQL setup complete!"
        echo -e "${GREEN}Your app is now configured to use PostgreSQL database at: $PG_USER@$PG_HOST:$PG_PORT/$PG_DB${NC}"
    else
        print_error "❌ Failed to connect to PostgreSQL. Please check your connection details."
        exit 1
    fi
}

# Function to show current configuration
show_config() {
    print_header "Current Database Configuration"
    
    if [ -f ".env" ]; then
        echo "Current .env file contents:"
        echo "=========================="
        cat .env | grep -E "(DATABASE_TYPE|DATABASE_URL|POSTGRES_|SQLITE_)" || echo "No database configuration found"
        echo ""
        
        # Show which database is configured
        if grep -q "DATABASE_TYPE=sqlite" .env 2>/dev/null; then
            echo -e "${GREEN}✅ Currently configured for: SQLite${NC}"
        elif grep -q "DATABASE_TYPE=postgresql" .env 2>/dev/null; then
            echo -e "${GREEN}✅ Currently configured for: PostgreSQL${NC}"
        else
            echo -e "${YELLOW}⚠️  Database type not explicitly set${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  No .env file found. Database will use defaults.${NC}"
    fi
}

# Function to test current database connection
test_connection() {
    print_header "Testing Database Connection"
    
    print_info "🔧 Testing database connection..."
    python -c "
from app import app, db
try:
    with app.app_context():
        # Try to connect to database
        db.engine.execute('SELECT 1')
        print('✅ Database connection successful!')
        
        # Show database info
        from sqlalchemy import inspect
        inspector = inspect(db.engine)
        tables = inspector.get_table_names()
        print(f'📊 Found {len(tables)} tables: {tables}')
        
except Exception as e:
    print(f'❌ Database connection failed: {e}')
    exit(1)
"
}

# Main menu
main_menu() {
    print_header "Flask Notes Database Configuration"
    
    echo "Choose an option:"
    echo "1. Setup SQLite database (recommended for development)"
    echo "2. Setup PostgreSQL database (recommended for production)"
    echo "3. Show current configuration"
    echo "4. Test database connection"
    echo "5. Exit"
    echo ""
    
    read -p "Enter your choice (1-5): " choice
    
    case $choice in
        1)
            setup_sqlite
            ;;
        2)
            setup_postgresql
            ;;
        3)
            show_config
            ;;
        4)
            test_connection
            ;;
        5)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid choice. Please try again."
            echo ""
            main_menu
            ;;
    esac
}

# Check if we're in the right directory
if [ ! -f "app.py" ]; then
    print_error "This script must be run from the Flask Notes app directory."
    exit 1
fi

# Run main menu
main_menu
