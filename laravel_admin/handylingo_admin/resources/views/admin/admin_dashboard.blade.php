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
    <div id="viewDescriptionModal" class="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50 hidden">
        <div class="bg-white rounded-2xl shadow-xl w-full max-w-md max-h-[90vh] overflow-y-auto p-6 space-y-6 relative">
            <button onclick="closeviewDescriptionModal()" class="absolute top-4 right-4 text-gray-400 hover:text-gray-600 text-2xl">&times;</button>
            <h2 class="text-xl font-bold mb-4">Job Feedback</h2>
            <div class="space-y-2">
                <label class="block text-xs text-gray-500">First Name:</label>
                <input id="modal_firstName" class="w-full border rounded px-2 py-1" readonly placeholder="First Name">
                <label class="block text-xs text-gray-500">Last Name:</label>
                <input id="modal_lastName" class="w-full border rounded px-2 py-1" readonly placeholder="Last Name">
                <label class="block text-xs text-gray-500">Position:</label>
                <input id="modal_position" class="w-full border rounded px-2 py-1" readonly placeholder="Position">
                <label class="block text-xs text-gray-500">Company Name:</label>
                <input id="modal_companyName" class="w-full border rounded px-2 py-1" readonly placeholder="Company Name">
                <label class="block text-xs text-gray-500">Email Address:</label>
                <input id="modal_email" class="w-full border rounded px-2 py-1" readonly placeholder="Email">
                <label class="block text-xs text-gray-500">Phone Number:</label>
                <input id="modal_phoneNumber" class="w-full border rounded px-2 py-1" readonly placeholder="Phone Number">
                <label class="block text-xs text-gray-500">Feedback Type:</label>
                <input id="modal_feedbackType" class="w-full border rounded px-2 py-1" readonly placeholder="Feedback Type">
                <label class="block text-xs text-gray-500">Feedback Text:</label>
                <textarea id="modal_feedbackText" class="w-full border rounded px-2 py-1" readonly placeholder="Feedback Text"></textarea>
                <label class="block text-xs text-gray-500">Rating:</label>
                <input id="modal_rating" class="w-full border rounded px-2 py-1" readonly placeholder="Rating">
                <label class="block text-xs text-gray-500">Date of Updated Feedback:</label>
                <input id="modal_updated_at" class="w-full border rounded px-2 py-1" readonly placeholder="Date of Updated Feedback">
            </div>
        </div>
    </div>

    <div id="deleteFeedbackForm" class="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50 hidden">
        <div class="bg-white rounded-2xl shadow-xl w-full max-w-md p-6 space-y-6">
            <div class="flex justify-between items-center">
                <h3 class="text-xl font-semibold">Delete Feedback?</h3>
                <button onclick="closeDeleteFeedbackForm()" class="text-gray-400 hover:text-gray-600 text-2xl">&times;</button>
            </div>
            <form id="deleteFeedback" method="POST" action="">
                @csrf
                @method('DELETE')
                <button type="submit" class="w-full py-3 px-4 rounded-lg bg-green-200">Yes</button>
            </form>
            <button onclick="closeDeleteFeedbackForm()" class="w-full py-3 px-4 rounded-lg border border-gray-300 hover:bg-gray-50 text-gray-700">Cancel</button>
        </div>
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
    </script>
</body>

</html>