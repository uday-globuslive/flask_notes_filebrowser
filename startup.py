# Azure App Service Startup Script
import os
import sys
from pathlib import Path

# Add the application directory to Python path
app_dir = Path(__file__).parent
sys.path.insert(0, str(app_dir))

# Import the Flask app
from app import app

# Configure for Azure App Service
if __name__ == "__main__":
    # Azure App Service will set the PORT environment variable
    port = int(os.environ.get('PORT', 8000))
    
    # Run the application
    app.run(
        host='0.0.0.0',
        port=port,
        debug=False  # Always False in production
    )
