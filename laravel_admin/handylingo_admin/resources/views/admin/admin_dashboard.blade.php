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
        [x-cloak] {
            display: none !important;
        }

        .sidebar-item.active {
            color: #60a5fa !important;
            border-right: 4px solid #60a5fa;
            background: rgba(255, 255, 255, 0.05);
        }

        .hidden-section {
            display: none;
        }

        ::-webkit-scrollbar {
            width: 6px;
        }

        ::-webkit-scrollbar-track {
            background: transparent;
        }

        ::-webkit-scrollbar-thumb {
            background: #475569;
            border-radius: 10px;
        }
    </style>
</head>

<body class="bg-[#F8FAFC] font-sans text-slate-900 overflow-hidden flex flex-col h-screen">

    <div class="flex-none">
        <x-admin_topbar :user="$user" :notifications="$notifications" :unreadNotifications="$unreadNotifications" />
    </div>

    <div class="flex flex-1 overflow-hidden">

        <x-admin_sidebar />

        <main class="flex-1 overflow-y-auto p-4 md:p-8 pb-24">
            @if(session('Success'))
            <div id="notification-bar" class="fixed top-6 left-1/2 transform -translate-x-1/2 bg-green-500 text-white px-6 py-3 rounded shadow-lg z-50">
                {{ session('Success') }}
            </div>
            @elseif(session('error'))
            <div id="notification-bar" class="fixed top-6 left-1/2 transform -translate-x-1/2 bg-red-500 text-white px-6 py-3 rounded shadow-lg z-50">
                {{ session('error') }}
            </div>
            @endif
            <div class="max-w-7xl mx-auto">

                <!-- SECTION: DASHBOARD -->
                <section id="section-dashboard" class="space-y-8">
                    <header>
                        <h2 class="text-3xl font-extrabold tracking-tight text-slate-800">Dashboard Overview</h2>
                        <p class="text-slate-500">Monitor your system performance and user activity.</p>
                    </header>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">

                        <!-- Total Users -->
                        <div class="bg-white p-6 rounded-2xl shadow-sm border border-slate-200 group">
                            <div class="flex justify-between items-start">
                                <div>
                                    <p class="text-sm font-medium text-slate-500 uppercase tracking-wider">
                                        Total Users
                                    </p>
                                    <h3 class="text-4xl font-bold mt-2 text-slate-800">
                                        {{ $userCount }}
                                    </h3>
                                </div>

                                <div
                                    class="p-3 bg-blue-50 text-blue-600 rounded-xl
                       group-hover:bg-blue-600 group-hover:text-white transition-colors">
                                    <i data-lucide="users" class="w-6 h-6"></i>
                                </div>
                            </div>
                        </div>

                        <!-- Pending Feedback -->
                        <div class="bg-white p-6 rounded-2xl shadow-sm border border-slate-200 group">
                            <div class="flex justify-between items-start">
                                <div>
                                    <p class="text-sm font-medium text-slate-500 uppercase tracking-wider">
                                        Pending Feedback
                                    </p>
                                    <h3 class="text-4xl font-bold mt-2 text-slate-800">
                                        {{$feedbackCount}}
                                    </h3>
                                </div>

                                <div
                                    class="p-3 bg-amber-50 text-amber-600 rounded-xl
                       group-hover:bg-amber-600 group-hover:text-white transition-colors">
                                    <i data-lucide="message-square" class="w-6 h-6"></i>
                                </div>
                            </div>
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
            if (targetSection) targetSection.classList.remove('hidden-section');

            document.querySelectorAll('.sidebar-item').forEach(i => i.classList.remove('active'));
            const activeNav = document.getElementById(`nav-${sectionId}`);
            if (activeNav) activeNav.classList.add('active');

            lucide.createIcons();
        };
        setTimeout(() => {
            const notif = document.getElementById('notification-bar');
            if (notif) notif.style.opacity = '0';
        }, 2500);
        setTimeout(() => {
            const notif = document.getElementById('notification-bar');
            if (notif) notif.style.display = 'none';
        }, 3000);
    </script>
</body>

</html>