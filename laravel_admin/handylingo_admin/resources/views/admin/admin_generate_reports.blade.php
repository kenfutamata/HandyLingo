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
        [x-cloak] {
            display: none !important;
        }

        body {
            font-family: 'Inter', system-ui, -apple-system, sans-serif;
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
    </style>
</head>

<body class="bg-[#F8FAFC] text-slate-900 flex flex-col h-screen overflow-hidden">

    <!-- Topbar -->
    <div class="flex-none z-50">
        <x-admin_topbar :user="$user" :notifications="$notifications" :unreadNotifications="$unreadNotifications" />
    </div>

    <div class="flex flex-1 overflow-hidden">
        <!-- Sidebar -->
        <x-admin_sidebar />

        <!-- Main Content Area -->
        <main class="flex-1 overflow-y-auto p-6 md:p-10 pb-24">

            <!-- Notifications -->
            @foreach (['Success' => 'emerald', 'error' => 'rose'] as $key => $color)
            @if (session($key))
            <div id="notification-bar" class="fixed top-20 left-1/2 transform -translate-x-1/2 bg-{{ $color }}-500 text-white px-6 py-3 rounded-xl shadow-2xl z-[60] transition-all duration-500">
                {{ session($key) }}
            </div>
            @endif
            @endforeach

            <div class="max-w-6xl mx-auto">

                <!-- Page Header & Filters Row -->
                <div class="flex flex-col lg:flex-row justify-between items-start lg:items-center mb-10 gap-6">
                    <div>
                        <h1 class="text-3xl font-extrabold text-slate-900 tracking-tight">System Performance Report</h1>
                        <p class="text-slate-500 mt-1 flex items-center gap-2">
                            <i data-lucide="calendar" class="w-4 h-4"></i>
                            Analytics for {{ \Carbon\Carbon::parse($selectedMonth)->format('F Y') }}
                        </p>
                    </div>

                    <div class="flex flex-col sm:flex-row items-center gap-4 w-full lg:w-auto">
                        <!-- Month Filter Form -->
                        <form method="GET" action="{{ url()->current() }}" class="flex items-center gap-3 bg-white border border-slate-200 p-2 rounded-xl shadow-sm w-full sm:w-auto">
                            <label for="month" class="pl-3 text-xs font-bold uppercase text-slate-400">Period</label>
                            <input type="month" id="month" name="month" value="{{ $selectedMonth }}" onchange="this.form.submit()"
                                class="border-0 bg-transparent text-sm font-semibold focus:ring-0 cursor-pointer">
                        </form>

                        <a href="#" class="flex items-center justify-center gap-2 bg-slate-900 hover:bg-slate-800 text-white px-5 py-2.5 rounded-xl text-sm font-bold transition-all shadow-lg w-full sm:w-auto">
                            <i data-lucide="download" class="w-4 h-4"></i>
                            Export PDF
                        </a>
                    </div>
                </div>

                <!-- Report Sections -->
                @if($ratingsChartData)
                <div class="grid grid-cols-1 gap-8">

                    <!-- Feedback Ratings Card -->
                    <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-8">
                        <div class="flex items-center justify-between mb-8">
                            <div>
                                <h2 class="text-xl font-bold text-slate-800">Application Feedback</h2>
                                <p class="text-sm text-slate-500">Aggregated feedback from both Landing Page and Mobile App</p>
                            </div>
                            <div class="p-3 bg-blue-50 text-blue-600 rounded-xl">
                                <i data-lucide="bar-chart-3" class="w-6 h-6"></i>
                            </div>
                        </div>

                        <div class="relative h-[400px] w-full">
                            <canvas id="ratingsChart"></canvas>
                        </div>
                    </div>

                    <!-- You can add more summary cards here if needed (e.g. Total Users) -->
                </div>
                @else
                <!-- Empty State -->
                <div class="bg-white border border-dashed border-slate-300 rounded-3xl p-20 text-center max-w-2xl mx-auto mt-10">
                    <div class="bg-slate-50 w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-6">
                        <i data-lucide="database-zap" class="w-10 h-10 text-slate-300"></i>
                    </div>
                    <h3 class="text-2xl font-bold text-slate-800">No Analytics Found</h3>
                    <p class="text-slate-500 mt-2">There is no feedback data recorded for the selected month. Please try selecting a different period.</p>
                </div>
                @endif
                <!--Users Count-->
                @if($usersChartData)
                <div class="grid grid-cols-1 gap-8">

                    <!-- Users Card -->
                    <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-8">
                        <div class="flex items-center justify-between mb-8">
                            <div>
                                <h2 class="text-xl font-bold text-slate-800">User Count</h2>
                                <p class="text-sm text-slate-500">Number of Users registered</p>
                            </div>
                            <div class="p-3 bg-blue-50 text-blue-600 rounded-xl">
                                <i data-lucide="bar-chart-3" class="w-6 h-6"></i>
                            </div>
                        </div>

                        <div class="relative h-[400px] w-full">
                            <canvas id="usersChart"></canvas>
                        </div>
                    </div>

                    <!-- You can add more summary cards here if needed (e.g. Total Users) -->
                </div>
                @else
                <!-- Empty State -->
                <div class="bg-white border border-dashed border-slate-300 rounded-3xl p-20 text-center max-w-2xl mx-auto mt-10">
                    <div class="bg-slate-50 w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-6">
                        <i data-lucide="database-zap" class="w-10 h-10 text-slate-300"></i>
                    </div>
                    <h3 class="text-2xl font-bold text-slate-800">No Analytics Found</h3>
                    <p class="text-slate-500 mt-2">There is no feedback data recorded for the selected month. Please try selecting a different period.</p>
                </div>
                @endif
            </div>
        </main>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', () => {
            // Initialize Lucide Icons
            if (typeof lucide !== 'undefined') {
                lucide.createIcons();
            }

            // Notification handling
            const notifBar = document.getElementById('notification-bar');
            if (notifBar) {
                setTimeout(() => {
                    notifBar.style.opacity = '0';
                    setTimeout(() => notifBar.remove(), 500);
                }, 3000);
            }

            // 1. Application Feedback Chart
            @if($ratingsChartData)
            const feedbackData = @json($ratingsChartData);
            new Chart(document.getElementById('ratingsChart').getContext('2d'), {
                type: 'bar',
                data: {
                    labels: feedbackData.labels.map(l => `★ ${l}`),
                    datasets: [{
                        label: 'Rating Count',
                        data: feedbackData.values,
                        backgroundColor: '#3b82f6',
                        borderRadius: 12,
                        barThickness: 45
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            display: false
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            ticks: {
                                precision: 0
                            }
                        }
                    }
                }
            });
            @endif

            // 2. User Count Chart
            @if($usersChartData)
            const usersData = @json($usersChartData);
            new Chart(document.getElementById('usersChart').getContext('2d'), {
                type: 'bar',
                data: {
                    labels: usersData.labels,
                    datasets: [{
                        label: 'Users Registered',
                        data: usersData.values,
                        backgroundColor: '#10b981',
                        borderRadius: 12,
                        barThickness: 45
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            display: false
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            ticks: {
                                precision: 0
                            }
                        }
                    }
                }
            });
            @endif
        });
    </script>
</body>

</html>