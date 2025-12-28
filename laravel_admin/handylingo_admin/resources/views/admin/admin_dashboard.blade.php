<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard</title>
    
    <!-- Scripts -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://unpkg.com/lucide@latest"></script>
    <!-- Essential: Alpine.js for dropdowns and modals -->
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>

    <link rel="icon" type="image/x-icon" href="{{asset('assets/admin/handylingologo.png')}}">

    <style>
        [x-cloak] { display: none !important; }
        
        .sidebar-item.active {
            color: #60a5fa !important;
            border-right: 4px solid #60a5fa;
            background: rgba(255, 255, 255, 0.05);
        }

        .hidden-section { display: none; }
        
        /* Custom scrollbar for a cleaner look */
        ::-webkit-scrollbar { width: 6px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 10px; }
    </style>
</head>

<body class="bg-[#F8FAFC] font-sans text-slate-900 overflow-hidden">
    <!-- Topbar Component -->
    <x-admin_topbar :user="$user" />

    <div class="flex h-screen">
        <!-- Sidebar Component -->
        <x-admin_sidebar />

        <!-- MAIN CONTENT -->
        <main class="flex-1 overflow-y-auto p-4 md:p-8 pb-24">
            <div class="max-w-7xl mx-auto">
                
                <!-- SECTION: DASHBOARD -->
                <section id="section-dashboard" class="space-y-8">
                    <header>
                        <h2 class="text-3xl font-extrabold tracking-tight text-slate-800">Dashboard Overview</h2>
                        <p class="text-slate-500">Monitor your system performance and user activity.</p>
                    </header>

                    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                        <div class="bg-white p-6 rounded-2xl shadow-sm border border-slate-200 group">
                            <div class="flex justify-between items-start">
                                <div>
                                    <p class="text-sm font-medium text-slate-500 uppercase tracking-wider">Total Users</p>
                                    <h3 id="stat-users" class="text-4xl font-bold mt-2 text-slate-800">...</h3>
                                </div>
                                <div class="p-3 bg-blue-50 text-blue-600 rounded-xl group-hover:bg-blue-600 group-hover:text-white transition-colors">
                                    <i data-lucide="users" class="w-6 h-6"></i>
                                </div>
                            </div>
                        </div>

                        <div class="bg-white p-6 rounded-2xl shadow-sm border border-slate-200 group">
                            <div class="flex justify-between items-start">
                                <div>
                                    <p class="text-sm font-medium text-slate-500 uppercase tracking-wider">Pending Feedback</p>
                                    <h3 id="stat-feedback" class="text-4xl font-bold mt-2 text-slate-800">...</h3>
                                </div>
                                <div class="p-3 bg-amber-50 text-amber-600 rounded-xl group-hover:bg-amber-600 group-hover:text-white transition-colors">
                                    <i data-lucide="message-square" class="w-6 h-6"></i>
                                </div>
                            </div>
                        </div>

                        <div class="bg-white p-6 rounded-2xl shadow-sm border border-slate-200 group">
                            <div class="flex justify-between items-start">
                                <div>
                                    <p class="text-sm font-medium text-slate-500 uppercase tracking-wider">System Status</p>
                                    <h3 class="text-2xl font-bold mt-2 text-slate-800">Operational</h3>
                                </div>
                                <div class="p-3 bg-emerald-50 text-emerald-600 rounded-xl">
                                    <i data-lucide="check-circle" class="w-6 h-6"></i>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
                        <div class="px-6 py-4 border-b border-slate-100 flex justify-between items-center bg-slate-50/50">
                            <h3 class="font-bold text-slate-800">Recent System Activity</h3>
                            <button class="text-blue-600 text-sm font-semibold hover:underline">View Log</button>
                        </div>
                        <div class="p-6">
                            <ul class="space-y-4">
                                <li class="flex items-center text-sm text-slate-600">
                                    <span class="w-2 h-2 bg-blue-500 rounded-full mr-3"></span>
                                    <span>User <b class="text-slate-900">Admin_Primary</b> updated the Global Configuration</span>
                                    <span class="ml-auto text-xs text-slate-400">2 mins ago</span>
                                </li>
                            </ul>
                        </div>
                    </div>
                </section>

            </div>
        </main>
    </div>

    <!-- Modals and Scripts follow same pattern as your upload... -->
    
    <script>
        // Initialize Icons on Load
        document.addEventListener('DOMContentLoaded', () => {
            lucide.createIcons();
        });

        window.showSection = (sectionId) => {
            document.querySelectorAll('main section').forEach(s => s.classList.add('hidden-section'));
            document.getElementById(`section-${sectionId}`).classList.remove('hidden-section');
            
            document.querySelectorAll('.sidebar-item').forEach(i => i.classList.remove('active'));
            const activeNav = document.getElementById(`nav-${sectionId}`);
            if(activeNav) activeNav.classList.add('active');
            
            lucide.createIcons(); // Refresh icons for new section
        };

        function renderUsers(users) {
            const tableBody = document.getElementById('user-table-body');
            tableBody.innerHTML = users.map(u => `
                <tr class="hover:bg-slate-50 transition-colors group">
                    <td class="p-5">
                        <div class="flex items-center">
                            <div class="h-10 w-10 rounded-full bg-blue-100 text-blue-600 flex items-center justify-center font-bold mr-3">
                                ${u.displayName ? u.displayName.charAt(0) : 'U'}
                            </div>
                            <div>
                                <p class="font-bold text-slate-800 leading-none">${u.displayName || 'Unnamed User'}</p>
                                <p class="text-xs text-slate-500 mt-1">${u.email}</p>
                            </div>
                        </div>
                    </td>
                    <td class="p-5 font-mono text-[10px] text-slate-400 tracking-tighter uppercase">${u.uid}</td>
                    <td class="p-5">
                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${u.disabled ? 'bg-red-100 text-red-700' : 'bg-emerald-100 text-emerald-700'}">
                            ${u.disabled ? 'Disabled' : 'Active'}
                        </span>
                    </td>
                    <td class="p-5">
                        <div class="flex justify-center space-x-1 opacity-0 group-hover:opacity-100 transition-opacity">
                            <button class="p-2 text-slate-400 hover:text-blue-600"><i data-lucide="edit-3" class="w-4 h-4"></i></button>
                            <button class="p-2 text-slate-400 hover:text-red-600"><i data-lucide="trash-2" class="w-4 h-4"></i></button>
                        </div>
                    </td>
                </tr>
            `).join('');
            lucide.createIcons();
        }

        window.openUserModal = () => document.getElementById('user-modal').classList.remove('hidden');
        window.closeUserModal = () => document.getElementById('user-modal').classList.add('hidden');
    </script>
</body>
</html>