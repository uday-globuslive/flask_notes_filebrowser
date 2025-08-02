// JavaScript functions for Flask Notes App

// File upload preview functionality
function previewFiles(input, previewContainer) {
    const files = input.files;
    previewContainer.innerHTML = '';
    
    if (files.length > 0) {
        const title = document.createElement('h6');
        title.textContent = 'Selected Files:';
        previewContainer.appendChild(title);
        
        const fileList = document.createElement('ul');
        fileList.className = 'list-group';
        
        Array.from(files).forEach(file => {
            const listItem = document.createElement('li');
            listItem.className = 'list-group-item d-flex justify-content-between align-items-center';
            listItem.innerHTML = `
                <span><i class="fas fa-file"></i> ${file.name}</span>
                <span class="badge bg-primary rounded-pill">${(file.size / 1024).toFixed(1)} KB</span>
            `;
            fileList.appendChild(listItem);
        });
        
        previewContainer.appendChild(fileList);
    }
}

// Drag and drop functionality
function setupDragAndDrop(dropZone, fileInput) {
    dropZone.addEventListener('dragover', function(e) {
        e.preventDefault();
        dropZone.classList.add('dragover');
    });
    
    dropZone.addEventListener('dragleave', function(e) {
        e.preventDefault();
        dropZone.classList.remove('dragover');
    });
    
    dropZone.addEventListener('drop', function(e) {
        e.preventDefault();
        dropZone.classList.remove('dragover');
        
        const files = e.dataTransfer.files;
        fileInput.files = files;
        
        // Trigger change event
        const event = new Event('change');
        fileInput.dispatchEvent(event);
    });
}

// Auto-save functionality for notes
function setupAutoSave(formId, saveUrl) {
    const form = document.getElementById(formId);
    if (!form) return;
    
    let saveTimeout;
    
    form.addEventListener('input', function() {
        clearTimeout(saveTimeout);
        saveTimeout = setTimeout(function() {
            // Auto-save logic here
            console.log('Auto-saving...');
        }, 2000); // Save after 2 seconds of inactivity
    });
}

// Search functionality
function setupSearch(searchInput, itemsContainer) {
    searchInput.addEventListener('input', function() {
        const query = this.value.toLowerCase();
        const items = itemsContainer.querySelectorAll('.searchable-item');
        
        items.forEach(item => {
            const text = item.textContent.toLowerCase();
            if (text.includes(query)) {
                item.style.display = 'block';
            } else {
                item.style.display = 'none';
            }
        });
    });
}

// Confirmation dialogs
function confirmDelete(message) {
    return confirm(message || 'Are you sure you want to delete this item?');
}

// Toast notifications
function showToast(message, type = 'info') {
    const toastContainer = document.getElementById('toast-container');
    if (!toastContainer) return;
    
    const toast = document.createElement('div');
    toast.className = `toast align-items-center text-white bg-${type} border-0`;
    toast.setAttribute('role', 'alert');
    toast.innerHTML = `
        <div class="d-flex">
            <div class="toast-body">${message}</div>
            <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
        </div>
    `;
    
    toastContainer.appendChild(toast);
    
    const bsToast = new bootstrap.Toast(toast);
    bsToast.show();
    
    // Remove toast after it's hidden
    toast.addEventListener('hidden.bs.toast', function() {
        toast.remove();
    });
}

// Initialize common functionality
document.addEventListener('DOMContentLoaded', function() {
    // Setup file input previews
    const fileInputs = document.querySelectorAll('input[type="file"]');
    fileInputs.forEach(input => {
        const previewContainer = document.getElementById('file-preview');
        if (previewContainer) {
            input.addEventListener('change', function() {
                previewFiles(this, previewContainer);
            });
        }
    });
    
    // Setup drag and drop for file upload zones
    const dropZones = document.querySelectorAll('.file-drop-zone');
    dropZones.forEach(zone => {
        const fileInput = zone.querySelector('input[type="file"]');
        if (fileInput) {
            setupDragAndDrop(zone, fileInput);
        }
    });
    
    // Add confirmation to delete buttons
    const deleteButtons = document.querySelectorAll('.btn-danger[type="submit"]');
    deleteButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            if (!confirmDelete()) {
                e.preventDefault();
            }
        });
    });
});
