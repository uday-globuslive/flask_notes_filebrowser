from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash

# Initialize db here to avoid circular imports
db = SQLAlchemy()

class User(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(150), unique=True, nullable=False)
    email = db.Column(db.String(150), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    notes = db.relationship('Note', backref='user', lazy=True, cascade='all, delete-orphan')
    folders = db.relationship('Folder', backref='user', lazy=True, cascade='all, delete-orphan')
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
    
    def __repr__(self):
        return f'<User {self.username}>'

class Note(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    content = db.Column(db.Text, nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    is_public = db.Column(db.Boolean, default=False)
    shared_with = db.Column(db.Text)  # JSON string of user IDs
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f'<Note {self.title}>'

class Folder(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(150), nullable=False)
    description = db.Column(db.Text)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    is_public = db.Column(db.Boolean, default=False)
    allow_file_drop = db.Column(db.Boolean, default=False)
    shared_with = db.Column(db.Text)  # JSON string of user IDs
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    files = db.relationship('File', backref='folder', lazy=True, cascade='all, delete-orphan')
    
    def __repr__(self):
        return f'<Folder {self.name}>'

class File(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    filename = db.Column(db.String(255), nullable=False)
    original_filename = db.Column(db.String(255), nullable=False)
    filepath = db.Column(db.String(500), nullable=False)
    file_size = db.Column(db.Integer, nullable=False)
    file_type = db.Column(db.String(100))
    folder_id = db.Column(db.Integer, db.ForeignKey('folder.id'), nullable=False)
    uploaded_by = db.Column(db.String(150))  # Can be 'anonymous' for public uploads
    uploaded_by_user_id = db.Column(db.Integer, db.ForeignKey('user.id'))
    uploaded_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f'<File {self.original_filename}>'

class SharedNote(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    note_id = db.Column(db.Integer, db.ForeignKey('note.id'), nullable=False)
    shared_with_user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    shared_by_user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    shared_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    note = db.relationship('Note', backref='shared_notes')
    shared_with_user = db.relationship('User', foreign_keys=[shared_with_user_id])
    shared_by_user = db.relationship('User', foreign_keys=[shared_by_user_id])

class SharedFolder(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    folder_id = db.Column(db.Integer, db.ForeignKey('folder.id'), nullable=False)
    shared_with_user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    shared_by_user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    shared_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    folder = db.relationship('Folder', backref='shared_folders')
    shared_with_user = db.relationship('User', foreign_keys=[shared_with_user_id])
    shared_by_user = db.relationship('User', foreign_keys=[shared_by_user_id])