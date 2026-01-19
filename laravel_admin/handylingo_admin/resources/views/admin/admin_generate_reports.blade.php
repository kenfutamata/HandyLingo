<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin - Generate Reports</title>

    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://unpkg.com/lucide@latest"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>

    <link rel="icon" type="image/x-icon" href="{{ asset('assets/admin/handylingologo.png') }}">

    <style>
        @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

        [x-cloak] {
            display: none !important;
        }

        body {
            font-family: 'Plus Jakarta Sans', sans-serif;
            background-color: #F8FAFC;
        }

        .chart-container {
            position: relative;
            height: 300px;
            width: 100%;
        }

        ::-webkit-scrollbar {
            width: 5px;
        }

        ::-webkit-scrollbar-track {
            background: transparent;
        }

        ::-webkit-scrollbar-thumb {
            background: #cbd5e1;
            border-radius: 10px;
        }

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

<body class="text-slate-900 flex flex-col h-screen overflow-hidden">

    <!-- Topbar -->
    <div class="flex-none z-50">
        <x-admin_topbar :user="$user" :notifications="$notifications" :unreadNotifications="$unreadNotifications" />
    </div>

    <div class="flex flex-1 overflow-hidden">
        <!-- Sidebar -->
        <x-admin_sidebar />

        <!-- Main Content Area -->
        <main class="flex-1 overflow-y-auto p-6 md:p-8 lg:p-10 pb-24">

            <!-- Notifications -->
            @foreach (['Success' => 'emerald', 'error' => 'rose'] as $key => $color)
            @if (session($key))
            <div id="notification-bar" class="fixed top-24 left-1/2 transform -translate-x-1/2 bg-slate-900 text-white px-6 py-3 rounded-2xl shadow-2xl z-[70] flex items-center gap-3 transition-all duration-500 border border-slate-700">
                <div class="w-2 h-2 rounded-full bg-{{ $color }}-400 animate-pulse"></div>
                <span class="text-sm font-bold">{{ session($key) }}</span>
            </div>
            @endif
            @endforeach

            <div class="max-w-7xl mx-auto space-y-8">

                <!-- Header Section -->
                <div class="flex flex-col md:flex-row md:items-end justify-between gap-6">
                    <div class="space-y-2">
                        <div class="flex items-center gap-2 text-indigo-600 font-bold text-xs uppercase tracking-widest">
                            <i data-lucide="pie-chart" class="w-4 h-4"></i>
                            System Analytics
                        </div>
                        <h1 class="text-4xl font-extrabold text-slate-900 tracking-tight">Reports Data</h1>
                        <p class="text-slate-500 font-medium">Viewing performance data for <span class="text-slate-900 font-bold">{{ \Carbon\Carbon::parse($selectedMonth)->format('F Y') }}</span></p>
                    </div>

                    <div class="flex flex-wrap items-center gap-3">
                        <form method="GET" action="{{ url()->current() }}" class="flex items-center bg-white border border-slate-200 p-1.5 rounded-2xl shadow-sm hover:border-indigo-300 transition-colors">
                            <label for="month" class="px-3 text-[10px] font-black uppercase text-slate-400 border-r border-slate-100">Period</label>
                            <input type="month" id="month" name="month" value="{{ $selectedMonth }}" onchange="this.form.submit()"
                                class="border-0 bg-transparent text-sm font-bold focus:ring-0 cursor-pointer text-slate-700 px-3">
                        </form>

                        <button onclick="window.print()" class="flex items-center justify-center gap-2 bg-slate-900 hover:bg-indigo-600 text-white px-6 py-3 rounded-2xl text-sm font-bold transition-all shadow-lg active:scale-95">
                            <i data-lucide="file-down" class="w-4 h-4"></i>
                            Export PDF
                        </button>
                    </div>
                </div>

                <!-- Metrics Grid -->
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                    <div class="bg-white p-6 rounded-[2rem] border border-slate-200 shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all duration-300 group">
                        <div class="flex justify-between items-start">
                            <div class="p-4 bg-blue-50 text-blue-600 rounded-2xl group-hover:bg-blue-600 group-hover:text-white transition-colors duration-300">
                                <i data-lucide="users" class="w-6 h-6"></i>
                            </div>
                            <div class="text-right">
                                <p class="text-xs font-bold text-slate-400 uppercase tracking-widest">Total Users</p>
                                <h3 class="text-3xl font-black text-slate-900 mt-1">{{ number_format($userCount) }}</h3>
                            </div>
                        </div>
                    </div>

                    <div class="bg-white p-6 rounded-[2rem] border border-slate-200 shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all duration-300 group">
                        <div class="flex justify-between items-start">
                            <div class="p-4 bg-amber-50 text-amber-600 rounded-2xl group-hover:bg-amber-500 group-hover:text-white transition-colors duration-300">
                                <i data-lucide="message-square" class="w-6 h-6"></i>
                            </div>
                            <div class="text-right">
                                <p class="text-xs font-bold text-slate-400 uppercase tracking-widest">Feedback</p>
                                <h3 class="text-3xl font-black text-slate-900 mt-1">{{ number_format($feedbackCount) }}</h3>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Charts Section -->
                @if($ratingsChartData || $usersChartData)
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
                    @if($ratingsChartData)
                    <div class="bg-white rounded-[2.5rem] shadow-sm border border-slate-200 p-8">
                        <h2 class="text-xl font-extrabold text-slate-900 mb-8">User Satisfaction</h2>
                        <div class="chart-container">
                            <canvas id="ratingsChart"></canvas>
                        </div>
                    </div>
                    @endif

                    @if($usersChartData)
                    <div class="bg-white rounded-[2.5rem] shadow-sm border border-slate-200 p-8">
                        <h2 class="text-xl font-extrabold text-slate-900 mb-8">Growth Trend</h2>
                        <div class="chart-container">
                            <canvas id="usersChart"></canvas>
                        </div>
                    </div>
                    @endif
                </div>
                @else
                <div class="bg-white border-2 border-dashed border-slate-200 rounded-[3rem] p-20 text-center max-w-2xl mx-auto">
                    <i data-lucide="bar-chart-2" class="w-12 h-12 text-slate-300 mx-auto mb-6"></i>
                    <h3 class="text-2xl font-black text-slate-800">No Data Found</h3>
                </div>
                @endif
            </div>
        </main>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', () => {
            if (typeof lucide !== 'undefined') lucide.createIcons();

            // Corrected JSON Access logic
            @if($ratingsChartData)
            const ctxR = document.getElementById('ratingsChart').getContext('2d');
            new Chart(ctxR, {
                type: 'bar',
                data: {
                    // Use array syntax ['labels'] instead of dot notation
                    labels: @json($ratingsChartData['labels']).map(l => `★ ${l}`),
                    datasets: [{
                        data: @json($ratingsChartData['values']),
                        backgroundColor: '#6366f1',
                        borderRadius: 12,
                        barThickness: 30,
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            display: false
                        }
                    }
                }
            });
            @endif

            @if($usersChartData)
            const ctxU = document.getElementById('usersChart').getContext('2d');
            new Chart(ctxU, {
                type: 'line',
                data: {
                    // Use array syntax ['labels'] instead of dot notation
                    labels: @json($usersChartData['labels']),
                    datasets: [{
                        label: 'Registrations',
                        data: @json($usersChartData['values']),
                        borderColor: '#10b981',
                        borderWidth: 4,
                        fill: true,
                        backgroundColor: 'rgba(16, 185, 129, 0.1)',
                        tension: 0.4
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            display: false
                        }
                    }
                }
            });
            @endif
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
    </script>
</body>

</html>