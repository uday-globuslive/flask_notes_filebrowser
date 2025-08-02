from flask import render_template, url_for, flash, redirect, request, abort, jsonify, send_file
from flask_login import login_user, current_user, logout_user, login_required
from werkzeug.utils import secure_filename
import os
import uuid
import json
from datetime import datetime

# Import models (db and models will be imported when function is called)
from models import db, User, Note, Folder, File, SharedNote, SharedFolder

# Helper functions
def allowed_file(filename):
    # Allow all file types - just check if filename has any extension
    # You can add security restrictions here if needed
    return '.' in filename and len(filename.strip()) > 0

def generate_unique_filename(filename):
    """Generate a unique filename to prevent conflicts"""
    name, ext = os.path.splitext(filename)
    unique_name = f"{name}_{uuid.uuid4().hex[:8]}{ext}"
    return unique_name

def register_routes(app):
    """Register all routes with the Flask app instance"""
    
    @app.route('/')
    def index():
        # Show public notes and folders on the home page
        public_notes = Note.query.filter_by(is_public=True).order_by(Note.created_at.desc()).limit(10).all()
        public_folders = Folder.query.filter_by(is_public=True).order_by(Folder.created_at.desc()).limit(10).all()
        return render_template('index.html', public_notes=public_notes, public_folders=public_folders)

    @app.route('/register', methods=['GET', 'POST'])
    def register():
        if current_user.is_authenticated:
            return redirect(url_for('dashboard'))
        
        if request.method == 'POST':
            username = request.form['username']
            email = request.form['email']
            password = request.form['password']
            
            # Check if user already exists
            if User.query.filter_by(username=username).first():
                flash('Username already exists. Please choose a different one.', 'danger')
                return render_template('register.html')
            
            if User.query.filter_by(email=email).first():
                flash('Email already registered. Please use a different email.', 'danger')
                return render_template('register.html')
            
            # Create new user
            user = User(username=username, email=email)
            user.set_password(password)
            db.session.add(user)
            db.session.commit()
            
            flash('Registration successful! You can now log in.', 'success')
            return redirect(url_for('login'))
        
        return render_template('register.html')

    @app.route('/login', methods=['GET', 'POST'])
    def login():
        if current_user.is_authenticated:
            return redirect(url_for('dashboard'))
        
        if request.method == 'POST':
            username = request.form['username']
            password = request.form['password']
            user = User.query.filter_by(username=username).first()
            
            if user and user.check_password(password):
                login_user(user)
                flash(f'Welcome back, {user.username}!', 'success')
                next_page = request.args.get('next')
                return redirect(next_page) if next_page else redirect(url_for('dashboard'))
            else:
                flash('Invalid username or password.', 'danger')
        
        return render_template('login.html')

    @app.route('/logout')
    @login_required
    def logout():
        logout_user()
        flash('You have been logged out.', 'info')
        return redirect(url_for('index'))

    @app.route('/dashboard')
    @login_required
    def dashboard():
        # Get user's notes and folders
        user_notes = Note.query.filter_by(user_id=current_user.id).order_by(Note.updated_at.desc()).all()
        user_folders = Folder.query.filter_by(user_id=current_user.id).order_by(Folder.created_at.desc()).all()
        
        # Get shared notes and folders
        shared_notes = db.session.query(Note).join(SharedNote).filter(SharedNote.shared_with_user_id == current_user.id).all()
        shared_folders = db.session.query(Folder).join(SharedFolder).filter(SharedFolder.shared_with_user_id == current_user.id).all()
        
        return render_template('dashboard.html', 
                             user_notes=user_notes, 
                             user_folders=user_folders,
                             shared_notes=shared_notes,
                             shared_folders=shared_folders)

    # Note routes
    @app.route('/create_note', methods=['GET', 'POST'])
    @login_required
    def create_note():
        if request.method == 'POST':
            title = request.form['title']
            content = request.form['content']
            is_public = 'is_public' in request.form
            
            note = Note(title=title, content=content, user_id=current_user.id, is_public=is_public)
            db.session.add(note)
            db.session.commit()
            
            flash('Note created successfully!', 'success')
            return redirect(url_for('dashboard'))
        
        return render_template('create_note.html')

    @app.route('/note/<int:note_id>')
    def view_note(note_id):
        note = Note.query.get_or_404(note_id)
        
        # Check permissions
        if not note.is_public:
            if not current_user.is_authenticated:
                abort(403)
            if note.user_id != current_user.id:
                # Check if note is shared with current user
                shared = SharedNote.query.filter_by(note_id=note_id, shared_with_user_id=current_user.id).first()
                if not shared:
                    abort(403)
        
        return render_template('view_note.html', note=note)

    @app.route('/edit_note/<int:note_id>', methods=['GET', 'POST'])
    @login_required
    def edit_note(note_id):
        note = Note.query.get_or_404(note_id)
        
        # Check if user owns the note
        if note.user_id != current_user.id:
            abort(403)
        
        if request.method == 'POST':
            note.title = request.form['title']
            note.content = request.form['content']
            note.is_public = 'is_public' in request.form
            note.updated_at = datetime.utcnow()
            db.session.commit()
            
            flash('Note updated successfully!', 'success')
            return redirect(url_for('view_note', note_id=note.id))
        
        return render_template('edit_note.html', note=note)

    @app.route('/delete_note/<int:note_id>', methods=['POST'])
    @login_required
    def delete_note(note_id):
        note = Note.query.get_or_404(note_id)
        
        # Check if user owns the note
        if note.user_id != current_user.id:
            abort(403)
        
        db.session.delete(note)
        db.session.commit()
        
        flash('Note deleted successfully!', 'success')
        return redirect(url_for('dashboard'))

    @app.route('/share_note/<int:note_id>', methods=['GET', 'POST'])
    @login_required
    def share_note(note_id):
        note = Note.query.get_or_404(note_id)
        
        # Check if user owns the note
        if note.user_id != current_user.id:
            abort(403)
        
        if request.method == 'POST':
            username = request.form['username']
            user_to_share = User.query.filter_by(username=username).first()
            
            if not user_to_share:
                flash('User not found.', 'danger')
                return render_template('share_note.html', note=note)
            
            if user_to_share.id == current_user.id:
                flash('You cannot share a note with yourself.', 'warning')
                return render_template('share_note.html', note=note)
            
            # Check if already shared
            existing_share = SharedNote.query.filter_by(note_id=note_id, shared_with_user_id=user_to_share.id).first()
            if existing_share:
                flash(f'Note is already shared with {username}.', 'warning')
                return render_template('share_note.html', note=note)
            
            # Create share
            shared_note = SharedNote(note_id=note_id, shared_with_user_id=user_to_share.id, shared_by_user_id=current_user.id)
            db.session.add(shared_note)
            db.session.commit()
            
            flash(f'Note shared with {username} successfully!', 'success')
            return redirect(url_for('view_note', note_id=note.id))
        
        return render_template('share_note.html', note=note)

    # Folder routes
    @app.route('/create_folder', methods=['GET', 'POST'])
    @login_required
    def create_folder():
        if request.method == 'POST':
            name = request.form['name']
            description = request.form.get('description', '')
            is_public = 'is_public' in request.form
            allow_file_drop = 'allow_file_drop' in request.form
            
            folder = Folder(name=name, description=description, user_id=current_user.id, 
                           is_public=is_public, allow_file_drop=allow_file_drop)
            db.session.add(folder)
            db.session.commit()
            
            flash('Folder created successfully!', 'success')
            return redirect(url_for('dashboard'))
        
        return render_template('create_folder.html')

    @app.route('/folder/<int:folder_id>')
    def view_folder(folder_id):
        folder = Folder.query.get_or_404(folder_id)
        
        # Check permissions
        if not folder.is_public:
            if not current_user.is_authenticated:
                abort(403)
            if folder.user_id != current_user.id:
                # Check if folder is shared with current user
                shared = SharedFolder.query.filter_by(folder_id=folder_id, shared_with_user_id=current_user.id).first()
                if not shared:
                    abort(403)
        
        files = File.query.filter_by(folder_id=folder_id).order_by(File.uploaded_at.desc()).all()
        return render_template('view_folder.html', folder=folder, files=files)

    @app.route('/upload_file/<int:folder_id>', methods=['GET', 'POST'])
    def upload_file(folder_id):
        folder = Folder.query.get_or_404(folder_id)
        
        # Check permissions for file upload
        can_upload = False
        if current_user.is_authenticated and folder.user_id == current_user.id:
            can_upload = True
        elif folder.is_public and folder.allow_file_drop:
            can_upload = True
        elif current_user.is_authenticated:
            # Check if folder is shared with current user
            shared = SharedFolder.query.filter_by(folder_id=folder_id, shared_with_user_id=current_user.id).first()
            if shared:
                can_upload = True
        
        if not can_upload:
            abort(403)
        
        if request.method == 'POST':
            if 'files[]' not in request.files:
                flash('No files selected.', 'danger')
                return redirect(request.url)
            
            files = request.files.getlist('files[]')
            uploaded_files = []
            
            for file in files:
                if file and file.filename:
                    if allowed_file(file.filename):
                        # Generate unique filename
                        original_filename = secure_filename(file.filename)
                        unique_filename = generate_unique_filename(original_filename)
                        filepath = os.path.join(app.config['UPLOAD_FOLDER'], unique_filename)
                        
                        # Save file
                        file.save(filepath)
                        file_size = os.path.getsize(filepath)
                        
                        # Create database record
                        uploaded_by = current_user.username if current_user.is_authenticated else 'anonymous'
                        uploaded_by_user_id = current_user.id if current_user.is_authenticated else None
                        
                        db_file = File(
                            filename=unique_filename,
                            original_filename=original_filename,
                            filepath=filepath,
                            file_size=file_size,
                            file_type=file.content_type,
                            folder_id=folder_id,
                            uploaded_by=uploaded_by,
                            uploaded_by_user_id=uploaded_by_user_id
                        )
                        db.session.add(db_file)
                        uploaded_files.append(original_filename)
                    else:
                        flash(f'File type not allowed: {file.filename}', 'warning')
            
            if uploaded_files:
                db.session.commit()
                flash(f'Successfully uploaded: {", ".join(uploaded_files)}', 'success')
            
            return redirect(url_for('view_folder', folder_id=folder_id))
        
        return render_template('upload_file.html', folder=folder)

    @app.route('/download_file/<int:file_id>')
    def download_file(file_id):
        file = File.query.get_or_404(file_id)
        folder = file.folder
        
        # Check permissions
        if not folder.is_public:
            if not current_user.is_authenticated:
                abort(403)
            if folder.user_id != current_user.id:
                # Check if folder is shared with current user
                shared = SharedFolder.query.filter_by(folder_id=folder.id, shared_with_user_id=current_user.id).first()
                if not shared:
                    abort(403)
        
        return send_file(file.filepath, as_attachment=True, download_name=file.original_filename)

    @app.route('/delete_file/<int:file_id>', methods=['POST'])
    @login_required
    def delete_file(file_id):
        file = File.query.get_or_404(file_id)
        folder = file.folder
        
        # Check if user owns the folder or uploaded the file
        if folder.user_id != current_user.id and file.uploaded_by_user_id != current_user.id:
            abort(403)
        
        # Delete file from filesystem
        if os.path.exists(file.filepath):
            os.remove(file.filepath)
        
        # Delete from database
        db.session.delete(file)
        db.session.commit()
        
        flash('File deleted successfully!', 'success')
        return redirect(url_for('view_folder', folder_id=folder.id))

    @app.route('/share_folder/<int:folder_id>', methods=['GET', 'POST'])
    @login_required
    def share_folder(folder_id):
        folder = Folder.query.get_or_404(folder_id)
        
        # Check if user owns the folder
        if folder.user_id != current_user.id:
            abort(403)
        
        if request.method == 'POST':
            username = request.form['username']
            user_to_share = User.query.filter_by(username=username).first()
            
            if not user_to_share:
                flash('User not found.', 'danger')
                return render_template('share_folder.html', folder=folder)
            
            if user_to_share.id == current_user.id:
                flash('You cannot share a folder with yourself.', 'warning')
                return render_template('share_folder.html', folder=folder)
            
            # Check if already shared
            existing_share = SharedFolder.query.filter_by(folder_id=folder_id, shared_with_user_id=user_to_share.id).first()
            if existing_share:
                flash(f'Folder is already shared with {username}.', 'warning')
                return render_template('share_folder.html', folder=folder)
            
            # Create share
            shared_folder = SharedFolder(folder_id=folder_id, shared_with_user_id=user_to_share.id, shared_by_user_id=current_user.id)
            db.session.add(shared_folder)
            db.session.commit()
            
            flash(f'Folder shared with {username} successfully!', 'success')
            return redirect(url_for('view_folder', folder_id=folder.id))
        
        return render_template('share_folder.html', folder=folder)

    @app.route('/delete_folder/<int:folder_id>', methods=['POST'])
    @login_required
    def delete_folder(folder_id):
        folder = Folder.query.get_or_404(folder_id)
        
        # Check if user owns the folder
        if folder.user_id != current_user.id:
            abort(403)
        
        # Delete all files in the folder from filesystem
        for file in folder.files:
            if os.path.exists(file.filepath):
                os.remove(file.filepath)
        
        # Delete folder from database (cascade will handle files and shares)
        db.session.delete(folder)
        db.session.commit()
        
        flash('Folder and all its contents deleted successfully!', 'success')
        return redirect(url_for('dashboard'))

    # Public file drop route
    @app.route('/public_drop/<int:folder_id>')
    def public_drop(folder_id):
        folder = Folder.query.get_or_404(folder_id)
        
        # Check if folder allows public file drop
        if not (folder.is_public and folder.allow_file_drop):
            abort(404)
        
        return render_template('public_drop.html', folder=folder)

    # API routes for AJAX functionality
    @app.route('/api/search_users')
    @login_required
    def search_users():
        query = request.args.get('q', '')
        if len(query) < 2:
            return jsonify([])
        
        users = User.query.filter(
            User.username.ilike(f'%{query}%'),
            User.id != current_user.id
        ).limit(10).all()
        
        return jsonify([{'id': user.id, 'username': user.username} for user in users])

    # Error handlers
    @app.errorhandler(403)
    def forbidden(error):
        return render_template('errors/403.html'), 403

    @app.errorhandler(404)
    def not_found(error):
        return render_template('errors/404.html'), 404

    @app.errorhandler(500)
    def internal_error(error):
        db.session.rollback()
        return render_template('errors/500.html'), 500
