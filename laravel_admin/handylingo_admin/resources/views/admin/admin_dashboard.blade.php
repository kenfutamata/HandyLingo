<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Panel</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <!-- Icons -->
    <script src="https://unpkg.com/lucide@latest"></script>
    <style>
        .sidebar-item.active {
            color: #60a5fa;
            border-right: 4px solid #60a5fa;
            background: rgba(255, 255, 255, 0.05);
        }

        .hidden-section {
            display: none;
        }
    </style>
</head>

<body class="bg-gray-50 font-sans">

    <div class="flex h-screen overflow-hidden">
        <!-- SIDEBAR -->
        <aside class="w-64 bg-[#22324A] text-white flex flex-col">
            <div class="p-6">
                <h1 class="text-2xl font-bold">Admin Panel</h1>
            </div>

            <nav class="flex-1 px-4 space-y-2 mt-4">
                <button onclick="showSection('dashboard')" id="nav-dashboard" class="sidebar-item active w-full flex items-center p-3 transition-colors hover:bg-white/10 rounded-lg">
                    <i data-lucide="layout-dashboard" class="mr-3 w-5 h-5"></i> Dashboard
                </button>
                <button onclick="showSection('database')" id="nav-database" class="sidebar-item w-full flex items-center p-3 transition-colors hover:bg-white/10 rounded-lg">
                    <i data-lucide="database" class="mr-3 w-5 h-5"></i> Database
                </button>
                <button onclick="showSection('feedback')" id="nav-feedback" class="sidebar-item w-full flex items-center p-3 transition-colors hover:bg-white/10 rounded-lg">
                    <i data-lucide="message-square" class="mr-3 w-5 h-5"></i> Feedback
                </button>
                <button onclick="showSection('updates')" id="nav-updates" class="sidebar-item w-full flex items-center p-3 transition-colors hover:bg-white/10 rounded-lg">
                    <i data-lucide="refresh-cw" class="mr-3 w-5 h-5"></i> Updates
                </button>
            </nav>

            <div class="p-4 border-t border-white/10">
                <form action="{{ route('admin.logout') }}" method="get">
                    <button id="logout-btn" class="flex items-center p-3 w-full text-white hover:text-red-400 transition-colors">
                        <i data-lucide="log-out" class="mr-3 w-5 h-5"></i> Log out
                    </button>
                </form>
            </div>
        </aside>

        <!-- MAIN CONTENT -->
        <main class="flex-1 overflow-y-auto p-8">

            <!-- SECTION: DASHBOARD -->
            <section id="section-dashboard">
                <h2 class="text-2xl font-bold mb-6">Dashboard Overview</h2>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
                    <!-- Cards -->
                    <div class="bg-white p-6 rounded-xl border-2 border-blue-500 shadow-sm">
                        <p class="text-blue-500 font-semibold mb-2">Total Users</p>
                        <div class="flex items-center">
                            <i data-lucide="users" class="text-blue-500 w-8 h-8 mr-3"></i>
                            <span id="stat-users" class="text-3xl font-bold">...</span>
                        </div>
                    </div>
                    <div class="bg-white p-6 rounded-xl border-2 border-blue-500 shadow-sm">
                        <p class="text-blue-500 font-semibold mb-2">Pending Feedback</p>
                        <div class="flex items-center">
                            <i data-lucide="message-circle" class="text-blue-500 w-8 h-8 mr-3"></i>
                            <span id="stat-feedback" class="text-3xl font-bold">...</span>
                        </div>
                    </div>
                    <div class="bg-white p-6 rounded-xl border-2 border-blue-500 shadow-sm">
                        <p class="text-blue-500 font-semibold mb-2">Recent Updates</p>
                        <div class="flex items-center">
                            <i data-lucide="calendar" class="text-blue-500 w-8 h-8 mr-3"></i>
                            <span class="text-xl font-bold">2023-10-27</span>
                        </div>
                    </div>
                </div>

                <div class="bg-white p-6 rounded-xl shadow-sm border">
                    <h3 class="font-bold mb-4">Recent Activity</h3>
                    <ul class="text-gray-600 space-y-2">
                        <li>• User "admin" logged in.</li>
                        <li>• Table users edited.</li>
                        <li>• New feedback received.</li>
                    </ul>
                </div>
            </section>

            <!-- SECTION: DATABASE (USER MANAGEMENT) -->
            <section id="section-database" class="hidden-section">
                <div class="flex justify-between items-center mb-6">
                    <h2 class="text-2xl font-bold">User Management</h2>
                    <button onclick="openUserModal()" class="bg-blue-600 text-white px-4 py-2 rounded-lg flex items-center hover:bg-blue-700">
                        <i data-lucide="plus" class="w-4 h-4 mr-2"></i> Add User
                    </button>
                </div>
                <div class="bg-white rounded-xl shadow overflow-hidden border">
                    <table class="w-full text-left">
                        <thead class="bg-gray-50 border-b text-gray-600">
                            <tr>
                                <th class="p-4">UID</th>
                                <th class="p-4">Email</th>
                                <th class="p-4">Display Name</th>
                                <th class="p-4">Status</th>
                                <th class="p-4 text-center">Actions</th>
                            </tr>
                        </thead>
                        <tbody id="user-table-body">
                            <!-- Rows injected by JS -->
                        </tbody>
                    </table>
                </div>
            </section>

            <!-- SECTION: FEEDBACK -->
            <section id="section-feedback" class="hidden-section">
                <h2 class="text-2xl font-bold mb-6">Received Feedback</h2>
                <div id="feedback-list" class="space-y-4">
                    <!-- Cards injected by JS -->
                </div>
            </section>

            <!-- SECTION: UPDATES -->
            <section id="section-updates" class="hidden-section">
                <h2 class="text-2xl font-bold mb-4">Recent Updates</h2>
                <p class="text-xl font-medium">Last updated: 2023-10-27</p>
            </section>
        </main>
    </div>

    <!-- MODAL: ADD/EDIT USER -->
    <div id="user-modal" class="fixed inset-0 bg-black/50 hidden flex items-center justify-center">
        <div class="bg-white rounded-xl p-8 w-full max-w-md">
            <h3 id="modal-title" class="text-xl font-bold mb-4">Add New User</h3>
            <div class="space-y-4">
                <input type="text" id="user-email" placeholder="Email" class="w-full border p-2 rounded">
                <input type="password" id="user-pw" placeholder="Password (min 6 chars)" class="w-full border p-2 rounded">
                <input type="text" id="user-name" placeholder="Display Name" class="w-full border p-2 rounded">
                <input type="text" id="user-status" placeholder="Status (e.g. Active)" class="w-full border p-2 rounded">
                <label class="flex items-center">
                    <input type="checkbox" id="user-disabled" class="mr-2"> Account Disabled
                </label>
            </div>
            <div class="flex justify-end mt-6 space-x-3">
                <button onclick="closeUserModal()" class="px-4 py-2 text-gray-600">Cancel</button>
                <button id="save-user-btn" class="px-4 py-2 bg-blue-600 text-white rounded">Save</button>
            </div>
        </div>
    </div>

    <!-- Firebase SDKs -->
    <script type="module">
        import {
            initializeApp
        } from "https://www.gstatic.com/firebasejs/10.5.0/firebase-app.js";
        import {
            getAuth,
            signOut
        } from "https://www.gstatic.com/firebasejs/10.5.0/firebase-auth.js";
        import {
            getFirestore,
            collection,
            query,
            orderBy,
            onSnapshot,
            doc,
            updateDoc
        } from "https://www.gstatic.com/firebasejs/10.5.0/firebase-firestore.js";
        import {
            getFunctions,
            httpsCallable
        } from "https://www.gstatic.com/firebasejs/10.5.0/firebase-functions.js";

        // Your Firebase config (Replace with your own)
        const firebaseConfig = {
            apiKey: "...",
            authDomain: "...",
            projectId: "...",
            storageBucket: "...",
            messagingSenderId: "...",
            appId: "..."
        };

        const app = initializeApp(firebaseConfig);
        const auth = getAuth(app);
        const db = getFirestore(app);
        const functions = getFunctions(app, 'us-central1');

        // Logic to switch sections
        window.showSection = (sectionId) => {
            document.querySelectorAll('main > section').forEach(s => s.classList.add('hidden-section'));
            document.getElementById(`section-${sectionId}`).classList.remove('hidden-section');

            document.querySelectorAll('.sidebar-item').forEach(i => i.classList.remove('active'));
            document.getElementById(`nav-${sectionId}`).classList.add('active');
        };

        // Initialize Icons


        // USER LIST (Using Functions)
        async function fetchUsers() {
            const listUsers = httpsCallable(functions, 'listUsers');
            try {
                const result = await listUsers();
                const users = result.data.users;
                document.getElementById('stat-users').innerText = users.length;

                const tableBody = document.getElementById('user-table-body');
                tableBody.innerHTML = users.map(u => `
                    <tr class="border-b hover:bg-gray-50">
                        <td class="p-4 text-xs font-mono text-gray-500">${u.uid}</td>
                        <td class="p-4">${u.email}</td>
                        <td class="p-4">${u.displayName || ''}</td>
                        <td class="p-4"><span class="bg-green-100 text-green-700 px-2 py-1 rounded text-xs">Active</span></td>
                        <td class="p-4 flex justify-center space-x-2">
                            <button class="text-blue-500 hover:bg-blue-50 p-1 rounded"><i data-lucide="edit-2" class="w-4 h-4"></i></button>
                            <button class="text-red-500 hover:bg-red-50 p-1 rounded"><i data-lucide="trash" class="w-4 h-4"></i></button>
                        </td>
                    </tr>
                `).join('');
                lucide.createIcons();
            } catch (e) {
                console.error(e);
            }
        }

        // FEEDBACK STREAM
        const q = query(collection(db, "feedback"), orderBy("timestamp", "desc"));
        onSnapshot(q, (snapshot) => {
            const feedbackList = document.getElementById('feedback-list');
            let pendingCount = 0;

            feedbackList.innerHTML = snapshot.docs.map(doc => {
                const data = doc.data();
                if (!data.adminReply) pendingCount++;
                return `
                    <div class="bg-white p-4 rounded-xl shadow-sm border">
                        <div class="flex justify-between">
                            <h4 class="font-bold">Subject: ${data.subject}</h4>
                            <span class="text-xs text-gray-400">${data.email || 'Anonymous'}</span>
                        </div>
                        <p class="text-gray-600 mt-2">${data.message}</p>
                        ${data.adminReply ? `<p class="mt-2 text-green-600 text-sm italic">Reply: ${data.adminReply}</p>` : ''}
                        <div class="mt-4 flex space-x-2">
                            ${!data.adminReply ? `<button class="text-blue-600 text-sm font-semibold">Reply</button>` : ''}
                            <button class="text-red-500 text-sm">Delete</button>
                        </div>
                    </div>
                `;
            }).join('');
            document.getElementById('stat-feedback').innerText = pendingCount;
        });

        // Modal Helpers
        window.openUserModal = () => document.getElementById('user-modal').classList.remove('hidden');
        window.closeUserModal = () => document.getElementById('user-modal').classList.add('hidden');

        // Initial Load
        fetchUsers();
    </script>
</body>

</html>