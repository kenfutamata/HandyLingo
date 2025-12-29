<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard</title>
    
    <!-- Scripts -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://unpkg.com/lucide@latest"></script>
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
        
        ::-webkit-scrollbar { width: 6px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: #475569; border-radius: 10px; }
    </style>
</head>

<body class="bg-[#F8FAFC] font-sans text-slate-900 overflow-hidden flex flex-col h-screen">

    <div class="flex-none">
        <x-admin_topbar :user="$user" />
    </div>

    <div class="flex flex-1 overflow-hidden">
        
        <x-admin_sidebar />

        <main class="flex-1 overflow-y-auto p-4 md:p-8 pb-24">
            <div class="max-w-7xl mx-auto">
                
                <!-- SECTION: DASHBOARD -->
                <section id="section-dashboard" class="space-y-8">
                    <header>
                        <h2 class="text-3xl font-extrabold tracking-tight text-slate-800">Dashboard Overview</h2>
                        <p class="text-slate-500">Monitor your system performance and user activity.</p>
                    </header>

                    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                        <!-- Stats Cards -->
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

                    <!-- Activity Log -->
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

    <script>
        document.addEventListener('DOMContentLoaded', () => {
            lucide.createIcons();
        });

        window.showSection = (sectionId) => {
            document.querySelectorAll('main section').forEach(s => s.classList.add('hidden-section'));
            const targetSection = document.getElementById(`section-${sectionId}`);
            if(targetSection) targetSection.classList.remove('hidden-section');
            
            document.querySelectorAll('.sidebar-item').forEach(i => i.classList.remove('active'));
            const activeNav = document.getElementById(`nav-${sectionId}`);
            if(activeNav) activeNav.classList.add('active');
            
            lucide.createIcons();
        };
    </script>
</body>
</html>