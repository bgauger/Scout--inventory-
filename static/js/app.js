// Service Management Application - Client-side JavaScript

let updateInterval;
let isRestarting = false;

/**
 * Initialize the application
 */
document.addEventListener('DOMContentLoaded', function() {
    console.log('Service Manager initialized');
    updateStatus();
    startAutoRefresh();
});

/**
 * Start automatic status refresh
 */
function startAutoRefresh() {
    if (updateInterval) {
        clearInterval(updateInterval);
    }
    updateInterval = setInterval(updateStatus, REFRESH_INTERVAL);
}

/**
 * Update service status from the API
 */
async function updateStatus() {
    try {
        const response = await fetch('/api/status');
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        updateUI(data);
        updateLastUpdateTime(data.timestamp);
    } catch (error) {
        console.error('Error fetching status:', error);
        showNotification('Failed to fetch status', 'error');
    }
}

/**
 * Update the UI with new status data
 */
function updateUI(data) {
    // Update web application status
    updateServiceCard('web', data.containers.web);

    // Update database status
    updateServiceCard('db', data.containers.database);
}

/**
 * Update a single service card
 */
function updateServiceCard(serviceType, containerData) {
    const statusEl = document.getElementById(`${serviceType}-status`);
    const stateEl = document.getElementById(`${serviceType}-state`);
    const imageEl = document.getElementById(`${serviceType}-image`);
    const idEl = document.getElementById(`${serviceType}-id`);

    // Update status indicator
    statusEl.className = 'status-indicator';
    statusEl.classList.add(containerData.status);

    // Update status text
    const statusText = statusEl.querySelector('.status-text');
    statusText.textContent = formatStatus(containerData.status);

    // Update info fields
    stateEl.textContent = containerData.state || 'Unknown';
    imageEl.textContent = containerData.image || 'N/A';
    idEl.textContent = containerData.id || 'N/A';

    // Show error if present
    if (containerData.error) {
        stateEl.textContent = containerData.error;
        stateEl.style.color = '#dc3545';
    } else {
        stateEl.style.color = '#495057';
    }
}

/**
 * Format status string for display
 */
function formatStatus(status) {
    const statusMap = {
        'running': '✓ Running',
        'stopped': '✕ Stopped',
        'exited': '✕ Exited',
        'restarting': '⟳ Restarting',
        'paused': '⏸ Paused',
        'not_found': '⚠ Not Found',
        'error': '⚠ Error',
        'unknown': '? Unknown'
    };

    return statusMap[status] || status.toUpperCase();
}

/**
 * Update the last update timestamp
 */
function updateLastUpdateTime(timestamp) {
    const updateEl = document.getElementById('last-update');
    const date = new Date(timestamp);
    updateEl.textContent = `Last updated: ${date.toLocaleTimeString()}`;
}

/**
 * Restart a service
 */
async function restartService(serviceType) {
    if (isRestarting) {
        showNotification('Please wait for the current operation to complete', 'error');
        return;
    }

    const confirmRestart = confirm(`Are you sure you want to restart the ${serviceType === 'web' ? 'web application' : 'database'}?`);
    if (!confirmRestart) {
        return;
    }

    isRestarting = true;
    const button = document.getElementById(`restart-${serviceType === 'web' ? 'web' : 'db'}`);
    button.disabled = true;
    button.textContent = '⏳ Restarting...';

    try {
        const response = await fetch(`/api/restart/${serviceType}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        });

        const data = await response.json();

        if (data.success) {
            showNotification(data.message, 'success');
            // Force an immediate update after restart
            setTimeout(updateStatus, 2000);
        } else {
            showNotification(data.message, 'error');
        }
    } catch (error) {
        console.error('Error restarting service:', error);
        showNotification('Failed to restart service', 'error');
    } finally {
        isRestarting = false;
        button.disabled = false;
        button.textContent = `🔄 Restart ${serviceType === 'web' ? 'Web App' : 'Database'}`;
    }
}

/**
 * Show a notification toast
 */
function showNotification(message, type = 'success') {
    const notification = document.getElementById('notification');
    notification.textContent = message;
    notification.className = `notification ${type}`;

    // Trigger reflow to restart animation
    notification.offsetHeight;

    notification.classList.add('show');

    setTimeout(() => {
        notification.classList.remove('show');
    }, 4000);
}

/**
 * Handle visibility change to pause/resume updates
 */
document.addEventListener('visibilitychange', function() {
    if (document.hidden) {
        if (updateInterval) {
            clearInterval(updateInterval);
        }
    } else {
        updateStatus();
        startAutoRefresh();
    }
});
