#!/usr/bin/env python3
"""
Database Configuration Test Script
Tests the flexible database configuration functionality
"""

import os
import tempfile
import shutil
from pathlib import Path

def test_database_configuration():
    """Test different database configuration scenarios"""
    
    print("🧪 Testing Database Configuration Flexibility")
    print("=" * 50)
    
    # Save original environment
    original_env = dict(os.environ)
    
    # Test scenarios
    scenarios = [
        {
            "name": "SQLite with explicit type",
            "env": {
                "DATABASE_TYPE": "sqlite",
                "SQLITE_PATH": "test_sqlite.db"
            },
            "expected": "sqlite:///test_sqlite.db"
        },
        {
            "name": "PostgreSQL with individual params",
            "env": {
                "DATABASE_TYPE": "postgresql",
                "POSTGRES_HOST": "localhost",
                "POSTGRES_PORT": "5432",
                "POSTGRES_USER": "testuser",
                "POSTGRES_PASSWORD": "testpass",
                "POSTGRES_DB": "testdb"
            },
            "expected": "postgresql://testuser:testpass@localhost:5432/testdb"
        },
        {
            "name": "PostgreSQL with DATABASE_URL",
            "env": {
                "DATABASE_URL": "postgresql://user:pass@server:5432/mydb"
            },
            "expected": "postgresql://user:pass@server:5432/mydb"
        },
        {
            "name": "SQLite default (no config)",
            "env": {},
            "expected": "sqlite:///instance/notes_app.db"
        },
        {
            "name": "SQLite with DATABASE_URL",
            "env": {
                "DATABASE_URL": "sqlite:///custom.db"
            },
            "expected": "sqlite:///custom.db"
        }
    ]
    
    for i, scenario in enumerate(scenarios, 1):
        print(f"\n🔍 Test {i}: {scenario['name']}")
        print("-" * 40)
        
        # Clear environment
        for key in list(os.environ.keys()):
            if key.startswith(('DATABASE_', 'POSTGRES_', 'SQLITE_')):
                del os.environ[key]
        
        # Set test environment
        for key, value in scenario['env'].items():
            os.environ[key] = value
        
        try:
            # Import app module (this will trigger database configuration)
            import importlib
            import sys
            
            # Remove app module if already imported
            if 'app' in sys.modules:
                del sys.modules['app']
            
            # Import fresh app module
            app_module = importlib.import_module('app')
            
            # Get configured database URI
            actual_uri = app_module.app.config['SQLALCHEMY_DATABASE_URI']
            
            # Check if it matches expected
            if actual_uri == scenario['expected']:
                print(f"✅ PASS: {actual_uri}")
            else:
                print(f"❌ FAIL: Expected {scenario['expected']}, got {actual_uri}")
                
        except Exception as e:
            print(f"❌ ERROR: {e}")
    
    # Restore original environment
    os.environ.clear()
    os.environ.update(original_env)
    
    print("\n" + "=" * 50)
    print("🎉 Database configuration tests completed!")

def test_configuration_files():
    """Test that configuration files exist and are valid"""
    
    print("\n📄 Testing Configuration Files")
    print("=" * 50)
    
    config_files = [
        ".env.sqlite",
        ".env.postgresql", 
        ".env.azure",
        "configure-database.sh",
        "configure-database.bat"
    ]
    
    for config_file in config_files:
        if os.path.exists(config_file):
            print(f"✅ {config_file} exists")
            
            # Check if it has database configuration
            if config_file.startswith('.env'):
                with open(config_file, 'r') as f:
                    content = f.read()
                    if 'DATABASE_TYPE' in content or 'DATABASE_URL' in content:
                        print(f"   📝 Contains database configuration")
                    else:
                        print(f"   ⚠️  Missing database configuration")
        else:
            print(f"❌ {config_file} missing")

if __name__ == "__main__":
    # Run tests
    test_database_configuration()
    test_configuration_files()
    
    print("\n💡 Usage Examples:")
    print("================")
    print("# Switch to SQLite:")
    print("cp .env.sqlite .env")
    print()
    print("# Switch to PostgreSQL:")  
    print("cp .env.postgresql .env")
    print()
    print("# Use interactive configuration:")
    print("./configure-database.sh  # Linux/Mac")
    print("configure-database.bat   # Windows")
