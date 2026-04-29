// Supabase Credentials (Directly from auth_service.dart)
const SUPABASE_URL = 'https://xelqafpkriikivviasfm.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhlbHFhZnBrcmlpa2l2dmlhc2ZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcyMDMxNDAsImV4cCI6MjA5Mjc3OTE0MH0.roRtHxgAzM2h9lhQjQ2zCjYQnWbT4NRN7NpzQ3nhqBs';

let supabaseClient = null;
let currentUsers = [];
let selectedUserId = null;

// DOM Elements
const loginOverlay = document.getElementById('login-overlay');
const dashboard = document.getElementById('dashboard');
const userList = document.getElementById('user-list');
const totalUsersEl = document.getElementById('total-users');
const loader = document.getElementById('loader');
const modalContainer = document.getElementById('modal-container');

// Modals
const editModal = document.getElementById('edit-modal');
const notifyModal = document.getElementById('notify-modal');
const deleteModal = document.getElementById('delete-modal');

// Inputs
const editUsernameInput = document.getElementById('edit-username');
const editPasswordInput = document.getElementById('edit-password');
const editBadgeInput = document.getElementById('edit-badge');
const notifyTitleInput = document.getElementById('notify-title');
const notifyMessageInput = document.getElementById('notify-message');
const notifySpeechInput = document.getElementById('notify-speech');

// --- Initialization ---

async function initializeSystem() {
    try {
        // Initialize using hardcoded credentials
        supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_KEY);
        
        // Fetch users immediately
        await fetchUsers();

        // Hide login, show dashboard
        loginOverlay.classList.add('hidden');
        dashboard.classList.remove('hidden');
        showToast('Control Board Synced', 'success');
    } catch (err) {
        console.error(err);
        showToast('Initialization Error: ' + err.message, 'error');
    }
}

// Run on load
window.addEventListener('DOMContentLoaded', initializeSystem);


// --- Data Fetching ---

async function fetchUsers() {
    loader.classList.remove('hidden');
    try {
        const { data, error } = await supabaseClient
            .from('users')
            .select('*')
            .order('created_at', { ascending: false });

        if (error) throw error;

        currentUsers = data;
        renderUsers(data);
        totalUsersEl.textContent = data.length;
    } catch (err) {
        showToast('Fetch Error: ' + err.message, 'error');
    } finally {
        loader.classList.add('hidden');
    }
}

function renderUsers(users) {
    userList.innerHTML = users.map(user => `
        <tr>
            <td>
                ${user.username}
                ${user.verified_type === 'blue' ? '<i data-lucide="check-circle" class="badge-blue"></i>' : ''}
                ${user.verified_type === 'gold' ? '<i data-lucide="check-circle" class="badge-gold"></i>' : ''}
            </td>
            <td>${user.country || 'Unknown'}</td>
            <td>${new Date(user.created_at).toLocaleDateString()}</td>
            <td class="actions-col">
                <div class="action-btns">
                    <button class="action-btn verify-blue ${user.verified_type === 'blue' ? 'active' : ''}" onclick="setVerify('${user.id}', 'blue')" title="Set Blue Badge">
                        <i data-lucide="check-circle"></i>
                    </button>
                    <button class="action-btn verify-gold ${user.verified_type === 'gold' ? 'active' : ''}" onclick="setVerify('${user.id}', 'gold')" title="Set Gold Badge">
                        <i data-lucide="check-circle"></i>
                    </button>
                    <button class="action-btn notify" onclick="openNotifyModal('${user.id}')" title="Send Notification"><i data-lucide="send"></i></button>
                    <button class="action-btn edit" onclick="openEditModal('${user.id}')" title="Edit User"><i data-lucide="edit-3"></i></button>
                    <button class="action-btn delete" onclick="openDeleteModal('${user.id}')" title="Delete User"><i data-lucide="trash-2"></i></button>
                </div>
            </td>
        </tr>
    `).join('');
    lucide.createIcons();
}

// --- User Actions ---

async function openEditModal(userId) {
    selectedUserId = userId;
    const user = currentUsers.find(u => u.id === userId);
    editUsernameInput.value = user.username;
    editPasswordInput.value = '';
    editBadgeInput.value = user.verified_type || 'none';
    
    showModal(editModal);
}

document.getElementById('save-user').addEventListener('click', async () => {
    const newUsername = editUsernameInput.value.trim();
    const newPassword = editPasswordInput.value.trim();
    const newBadge = editBadgeInput.value;

    if (!newUsername) {
        showToast('Username cannot be empty', 'error');
        return;
    }

    const updates = { 
        username: newUsername,
        verified_type: newBadge
    };
    if (newPassword) updates.password = newPassword;

    try {
        const { error } = await supabaseClient
            .from('users')
            .update(updates)
            .eq('id', selectedUserId);

        if (error) throw error;

        showToast('User Updated', 'success');
        closeModals();
        fetchUsers();
    } catch (err) {
        showToast('Update Failed: ' + err.message, 'error');
    }
});

async function setVerify(userId, type) {
    const user = currentUsers.find(u => u.id === userId);
    // If clicking the same one again, remove it (toggle off)
    const newType = user.verified_type === type ? 'none' : type;
    
    try {
        const { error } = await supabaseClient
            .from('users')
            .update({ verified_type: newType })
            .eq('id', userId);

        if (error) throw error;
        showToast(`Badge updated to ${newType}`, 'success');
        fetchUsers();
    } catch (err) {
        showToast('Update Failed: ' + err.message, 'error');
    }
}

async function openDeleteModal(userId) {
    selectedUserId = userId;
    showModal(deleteModal);
}

document.getElementById('confirm-delete').addEventListener('click', async () => {
    try {
        const { error } = await supabaseClient
            .from('users')
            .delete()
            .eq('id', selectedUserId);

        if (error) throw error;

        showToast('User Purged', 'success');
        closeModals();
        fetchUsers();
    } catch (err) {
        showToast('Purge Failed: ' + err.message, 'error');
    }
});

async function openNotifyModal(userId) {
    selectedUserId = userId;
    notifyTitleInput.value = 'System Alert';
    notifyMessageInput.value = '';
    notifySpeechInput.value = '';
    showModal(notifyModal);
}

document.getElementById('send-notification').addEventListener('click', async () => {
    const title = notifyTitleInput.value.trim();
    const message = notifyMessageInput.value.trim();
    const speechText = notifySpeechInput.value.trim();

    if (!title || !message) {
        showToast('Title and Message required', 'error');
        return;
    }

    try {
        const { error } = await supabaseClient
            .from('notifications')
            .insert([{
                user_id: selectedUserId,
                title: title,
                message: message,
                speech_text: speechText
            }]);

        if (error) throw error;

        showToast('Transmission Sent', 'success');
        closeModals();
    } catch (err) {
        showToast('Transmission Failed: ' + err.message, 'error');
    }
});


// --- Modal Helpers ---

function showModal(modal) {
    modalContainer.classList.remove('hidden');
    modal.classList.remove('hidden');
}

function closeModals() {
    modalContainer.classList.add('hidden');
    editModal.classList.add('hidden');
    notifyModal.classList.add('hidden');
    deleteModal.classList.add('hidden');
}

document.querySelectorAll('.close-modal').forEach(btn => {
    btn.addEventListener('click', closeModals);
});

// --- Global UI ---

document.getElementById('btn-refresh').addEventListener('click', fetchUsers);
document.getElementById('btn-logout').addEventListener('click', () => {
    dashboard.classList.add('hidden');
    loginOverlay.classList.remove('hidden');
    supabase = null;
});

function showToast(message, type = 'info') {
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.textContent = message;
    
    if (type === 'error') toast.style.borderColor = 'var(--red)';
    if (type === 'success') toast.style.borderColor = 'var(--accent)';

    document.getElementById('toast-container').appendChild(toast);
    setTimeout(() => toast.remove(), 4000);
}

// --- Background Animation (Waves) ---

const canvas = document.getElementById('waves');
const ctx = canvas.getContext('2d');

let width, height;
let progress = 0;

function resize() {
    width = canvas.width = window.innerWidth;
    height = canvas.height = window.innerHeight * 0.4;
}

window.addEventListener('resize', resize);
resize();

function animate() {
    progress += 0.005;
    ctx.clearRect(0, 0, width, height);

    const waveLayers = 5;
    for (let i = 0; i < waveLayers; i++) {
        ctx.beginPath();
        ctx.lineWidth = 1;
        ctx.strokeStyle = `rgba(255, 255, 255, ${0.05 + (i * 0.05)})`;

        const yBase = (i / waveLayers) * height;
        const phase = progress * (1 + i);

        for (let x = 0; x <= width; x += 10) {
            const wave1 = Math.sin(phase + (x * 0.01) + (i * 0.5));
            const wave2 = Math.cos(phase * 0.5 + (x * 0.02) + (i * 1.2)) * 0.5;
            const y = yBase + (wave1 + wave2) * (10 + (i * 5));
            
            if (x === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
        }
        ctx.stroke();
    }

    requestAnimationFrame(animate);
}

animate();
