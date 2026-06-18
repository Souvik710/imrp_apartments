/**
 * IMRP Apartments - NUI Script
 * Author: Ragna | Immortal Roleplay
 * Theme: Black, Sky Blue, Dark Glass
 */

const app = document.getElementById('app');
const apartmentInfo = document.getElementById('apartment-info');
const notification = document.getElementById('notification');

let notificationTimeout = null;

// Listen for NUI messages from client
window.addEventListener('message', function(event) {
    const data = event.data;

    switch (data.action) {
        case 'showApartmentInfo':
            showApartmentInfo(data.data);
            break;
        case 'showNotification':
            showNotification(data.data.type, data.data.message);
            break;
        case 'hideUI':
            hideAll();
            break;
    }
});

// Show Apartment Info Panel
function showApartmentInfo(info) {
    if (!info) return;

    app.classList.remove('hidden');
    apartmentInfo.classList.remove('hidden');

    document.getElementById('info-name').textContent = info.name || '-';
    document.getElementById('info-type').textContent = info.type || '-';
    document.getElementById('info-id').textContent = info.id || '-';
    document.getElementById('info-bucket').textContent = info.bucket ? `#${info.bucket}` : '-';
    document.getElementById('info-price').textContent = info.price || '-';
    document.getElementById('info-rental').textContent = info.rental_price || '-';
    document.getElementById('info-purchase-date').textContent = info.purchase_date || '-';
    document.getElementById('info-expire-date').textContent = info.expire_date || '-';
    document.getElementById('info-days').textContent = info.days_remaining != null ? `${info.days_remaining} days` : '-';
    document.getElementById('info-stash').textContent = info.stash_slots || '-';
    document.getElementById('info-keys').textContent = info.keys_given != null ? info.keys_given : '-';
    document.getElementById('info-guests').textContent = info.guests != null ? info.guests : '-';
    document.getElementById('info-garage').textContent = info.garage_slots || '-';
    document.getElementById('info-duration').textContent = info.duration ? `${info.duration} days` : '-';
}

// Show Notification
function showNotification(type, message) {
    if (!message) return;

    const iconEl = document.getElementById('notification-icon');
    const msgEl = document.getElementById('notification-message');

    notification.className = 'notification ' + (type || 'info');
    msgEl.textContent = message;

    switch (type) {
        case 'success':
            iconEl.className = 'fas fa-check-circle';
            break;
        case 'error':
            iconEl.className = 'fas fa-exclamation-circle';
            break;
        default:
            iconEl.className = 'fas fa-info-circle';
    }

    notification.classList.remove('hidden');

    if (notificationTimeout) {
        clearTimeout(notificationTimeout);
    }

    notificationTimeout = setTimeout(function() {
        notification.classList.add('hidden');
    }, 4000);
}

// Close UI
function closeUI() {
    hideAll();
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// Hide All Panels
function hideAll() {
    app.classList.add('hidden');
    apartmentInfo.classList.add('hidden');
    notification.classList.add('hidden');
}

// Escape key to close
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        closeUI();
    }
});

// Helper: Get resource name
function GetParentResourceName() {
    return window.GetParentResourceName ? window.GetParentResourceName() : 'imrp_apartments';
}
