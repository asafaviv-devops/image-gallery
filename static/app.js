// Image Gallery Frontend JavaScript

const API_BASE = '/api/images';
let currentImages = [];

// Initialize app
document.addEventListener('DOMContentLoaded', () => {
    loadImages();
    setupEventListeners();
});

// Setup event listeners
function setupEventListeners() {
    // Upload form
    document.getElementById('uploadBtn').addEventListener('click', uploadImage);
    document.getElementById('imageFile').addEventListener('change', previewImage);
    
    // Edit form
    document.getElementById('saveEditBtn').addEventListener('click', saveEdit);
    
    // Reset form when modal closes
    document.getElementById('uploadModal').addEventListener('hidden.bs.modal', resetUploadForm);
}

// Load all images
async function loadImages() {
    showLoading(true);
    hideEmptyState();
    hideGallery();
    
    try {
        const response = await fetch(API_BASE);
        
        if (!response.ok) {
            throw new Error('Failed to load images');
        }
        
        currentImages = await response.json();
        
        if (currentImages.length === 0) {
            showEmptyState();
        } else {
            displayImages(currentImages);
        }
    } catch (error) {
        console.error('Error loading images:', error);
        showAlert('שגיאה בטעינת התמונות', 'danger');
    } finally {
        showLoading(false);
    }
}

// Display images in grid
function displayImages(images) {
    const gallery = document.getElementById('galleryGrid');
    gallery.innerHTML = '';
    
    images.forEach(image => {
        const card = createImageCard(image);
        gallery.appendChild(card);
    });
    
    showGallery();
}

// Create image card
function createImageCard(image) {
    const col = document.createElement('div');
    col.className = 'col';
    
    const tagsHTML = image.tags && image.tags.length > 0
        ? `<div class="tags-container">
            ${image.tags.map(tag => `<span class="badge bg-secondary">${tag}</span>`).join('')}
           </div>`
        : '';
    
    const descriptionHTML = image.description 
        ? `<p class="card-text">${escapeHtml(image.description)}</p>`
        : '';
    
    const createdDate = new Date(image.created_at).toLocaleDateString('he-IL');
    const fileSize = formatFileSize(image.size);
    
    col.innerHTML = `
        <div class="card h-100">
            <img src="${image.thumbnail_url}" class="card-img-top" alt="${escapeHtml(image.title)}" 
                 onclick="viewImage('${image.id}')">
            <div class="card-body">
                <h5 class="card-title">${escapeHtml(image.title)}</h5>
                ${descriptionHTML}
                ${tagsHTML}
                <div class="image-info">
                    <i class="bi bi-calendar"></i> ${createdDate} | 
                    <i class="bi bi-file-earmark"></i> ${fileSize}
                </div>
            </div>
            <div class="card-footer bg-transparent border-0">
                <div class="card-actions">
                    <button class="btn btn-sm btn-outline-primary" onclick="viewImage('${image.id}')">
                        <i class="bi bi-eye"></i> צפה
                    </button>
                    <div>
                        <button class="btn btn-sm btn-outline-secondary" onclick="editImage('${image.id}')">
                            <i class="bi bi-pencil"></i> ערוך
                        </button>
                        <button class="btn btn-sm btn-outline-danger" onclick="deleteImage('${image.id}')">
                            <i class="bi bi-trash"></i> מחק
                        </button>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    return col;
}

// Preview image before upload
function previewImage(event) {
    const file = event.target.files[0];
    if (file && file.type.startsWith('image/')) {
        const reader = new FileReader();
        reader.onload = (e) => {
            document.getElementById('previewImg').src = e.target.result;
            document.getElementById('imagePreview').style.display = 'block';
        };
        reader.readAsDataURL(file);
    }
}

// Upload image
async function uploadImage() {
    const fileInput = document.getElementById('imageFile');
    const title = document.getElementById('imageTitle').value.trim();
    const description = document.getElementById('imageDescription').value.trim();
    const tags = document.getElementById('imageTags').value.trim();
    
    if (!fileInput.files[0]) {
        showAlert('אנא בחר תמונה', 'warning');
        return;
    }
    
    if (!title) {
        showAlert('אנא הזן כותרת', 'warning');
        return;
    }
    
    const formData = new FormData();
    formData.append('file', fileInput.files[0]);
    formData.append('title', title);
    if (description) formData.append('description', description);
    if (tags) formData.append('tags', tags);
    
    const uploadBtn = document.getElementById('uploadBtn');
    uploadBtn.disabled = true;
    uploadBtn.innerHTML = '<span class="spinner-border spinner-border-sm"></span> מעלה...';
    
    try {
        const response = await fetch(API_BASE, {
            method: 'POST',
            body: formData
        });
        
        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.detail || 'Upload failed');
        }
        
        showAlert('התמונה הועלתה בהצלחה!', 'success');
        
        // Close modal
        const modal = bootstrap.Modal.getInstance(document.getElementById('uploadModal'));
        modal.hide();
        
        // Reload images
        await loadImages();
        
    } catch (error) {
        console.error('Upload error:', error);
        showAlert(`שגיאה בהעלאת התמונה: ${error.message}`, 'danger');
    } finally {
        uploadBtn.disabled = false;
        uploadBtn.innerHTML = '<i class="bi bi-cloud-upload"></i> העלה';
    }
}

// View image
async function viewImage(imageId) {
    const image = currentImages.find(img => img.id === imageId);
    if (!image) return;
    
    document.getElementById('viewTitle').textContent = image.title;
    document.getElementById('viewImage').src = image.url;
    document.getElementById('viewDescription').textContent = image.description || '';
    
    const tagsHTML = image.tags && image.tags.length > 0
        ? image.tags.map(tag => `<span class="badge bg-secondary">${tag}</span>`).join(' ')
        : '';
    document.getElementById('viewTags').innerHTML = tagsHTML;
    
    const createdDate = new Date(image.created_at).toLocaleString('he-IL');
    document.getElementById('viewDate').textContent = `הועלה בתאריך: ${createdDate}`;
    
    const modal = new bootstrap.Modal(document.getElementById('viewModal'));
    modal.show();
}

// Edit image
async function editImage(imageId) {
    const image = currentImages.find(img => img.id === imageId);
    if (!image) return;
    
    document.getElementById('editImageId').value = image.id;
    document.getElementById('editTitle').value = image.title;
    document.getElementById('editDescription').value = image.description || '';
    document.getElementById('editTags').value = image.tags ? image.tags.join(', ') : '';
    
    const modal = new bootstrap.Modal(document.getElementById('editModal'));
    modal.show();
}

// Save edit
async function saveEdit() {
    const imageId = document.getElementById('editImageId').value;
    const title = document.getElementById('editTitle').value.trim();
    const description = document.getElementById('editDescription').value.trim();
    const tagsStr = document.getElementById('editTags').value.trim();
    
    const tags = tagsStr ? tagsStr.split(',').map(t => t.trim()).filter(t => t) : [];
    
    const updateData = {
        title: title || null,
        description: description || null,
        tags: tags.length > 0 ? tags : null
    };
    
    const saveBtn = document.getElementById('saveEditBtn');
    saveBtn.disabled = true;
    saveBtn.innerHTML = '<span class="spinner-border spinner-border-sm"></span> שומר...';
    
    try {
        const response = await fetch(`${API_BASE}/${imageId}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(updateData)
        });
        
        if (!response.ok) {
            throw new Error('Failed to update image');
        }
        
        showAlert('התמונה עודכנה בהצלחה!', 'success');
        
        // Close modal
        const modal = bootstrap.Modal.getInstance(document.getElementById('editModal'));
        modal.hide();
        
        // Reload images
        await loadImages();
        
    } catch (error) {
        console.error('Edit error:', error);
        showAlert('שגיאה בעדכון התמונה', 'danger');
    } finally {
        saveBtn.disabled = false;
        saveBtn.innerHTML = '<i class="bi bi-save"></i> שמור';
    }
}

// Delete image
async function deleteImage(imageId) {
    const image = currentImages.find(img => img.id === imageId);
    if (!image) return;
    
    if (!confirm(`האם אתה בטוח שברצונך למחוק את "${image.title}"?`)) {
        return;
    }
    
    try {
        const response = await fetch(`${API_BASE}/${imageId}`, {
            method: 'DELETE'
        });
        
        if (!response.ok) {
            throw new Error('Failed to delete image');
        }
        
        showAlert('התמונה נמחקה בהצלחה!', 'success');
        
        // Reload images
        await loadImages();
        
    } catch (error) {
        console.error('Delete error:', error);
        showAlert('שגיאה במחיקת התמונה', 'danger');
    }
}

// Reset upload form
function resetUploadForm() {
    document.getElementById('uploadForm').reset();
    document.getElementById('imagePreview').style.display = 'none';
}

// Show/hide loading
function showLoading(show) {
    document.getElementById('loadingSpinner').style.display = show ? 'block' : 'none';
}

// Show/hide empty state
function showEmptyState() {
    document.getElementById('emptyState').style.display = 'block';
}

function hideEmptyState() {
    document.getElementById('emptyState').style.display = 'none';
}

// Show/hide gallery
function showGallery() {
    document.getElementById('galleryGrid').style.display = 'flex';
}

function hideGallery() {
    document.getElementById('galleryGrid').style.display = 'none';
}

// Show alert
function showAlert(message, type = 'info') {
    const alertContainer = document.getElementById('alertContainer');
    
    const alertDiv = document.createElement('div');
    alertDiv.className = `alert alert-${type} alert-dismissible fade show`;
    alertDiv.role = 'alert';
    alertDiv.innerHTML = `
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    alertContainer.appendChild(alertDiv);
    
    // Auto-dismiss after 5 seconds
    setTimeout(() => {
        alertDiv.remove();
    }, 5000);
}

// Utility functions
function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, m => map[m]);
}

function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
}
