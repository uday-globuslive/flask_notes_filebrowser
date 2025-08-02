#!/bin/bash

# Flask Notes App Setup Script

echo "Setting up Flask Notes App..."

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python -m venv venv
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate  # For Linux/Mac
# For Windows, use: venv\Scripts\activate

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

# Copy environment file
if [ ! -f ".env" ]; then
    echo "Creating .env file..."
    cp .env.example .env
    echo "Please edit .env file with your configuration"
fi

# Create upload directory
mkdir -p uploads

# Initialize database
echo "Initializing database..."
flask db init
flask db migrate -m "Initial migration"
flask db upgrade

echo "Setup complete!"
echo "To run the application:"
echo "1. Edit .env file with your database credentials"
echo "2. Activate virtual environment: source venv/bin/activate (Linux/Mac) or venv\\Scripts\\activate (Windows)"
echo "3. Run: python app.py"
