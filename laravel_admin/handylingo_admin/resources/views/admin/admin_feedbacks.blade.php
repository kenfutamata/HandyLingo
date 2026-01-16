<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin - Feedbacks</title>

    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://unpkg.com/lucide@latest"></script>
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>

    <link rel="icon" type="image/x-icon" href="{{ asset('assets/admin/handylingologo.png') }}">

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

                <section id="section-database">
                    <div class="flex flex-col md:flex-row justify-between items-start md:items-center mb-8 gap-4">
                        <div>
                            <h2 class="text-3xl font-extrabold text-slate-800">User Feedbacks</h2>
                            <p class="text-slate-500 text-sm mt-1">Manage feedbacks to improve system</p>
                        </div>
                    </div>

                    <!-- FILTERS -->
                    <form method="GET" action="{{ route('admin.manage.feedbacks') }}" class="mb-6">
                        <div class="flex flex-col md:flex-row gap-4">
                            <div class="relative w-full md:w-1/3">
                                <i data-lucide="search"
                                    class="w-4 h-4 absolute left-4 top-1/2 -translate-y-1/2 text-slate-400">
                                </i>

                                <input
                                    type="text"
                                    name="search"
                                    placeholder="Search feedbacks..."
                                    value="{{ request('search') }}"
                                    class="w-full pl-11 pr-24 py-2.5 rounded-xl border border-slate-200 
                       bg-white text-sm
                       focus:outline-none focus:ring-2 focus:ring-blue-500 
                       focus:border-blue-500 transition">
                                <button
                                    type="submit"
                                    class="absolute right-1.5 top-1/2 -translate-y-1/2 
                       bg-blue-500 hover:bg-blue-600 
                       text-white text-sm font-medium 
                       px-4 py-1.5 rounded-lg transition">
                                    Search
                                </button>
                            </div>
                        </div>
                    </form>

                    <!-- TABLE -->
                    <div class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-x-auto">
                        <table class="w-full text-left border-collapse min-w-[700px]">
                            <thead class="bg-slate-50">
                                <tr class="border-b border-slate-200 text-slate-500 text-xs uppercase font-bold">
                                    <th class="p-5">#</th>
                                    <th class="p-5">First Name</th>
                                    <th class="p-5">Last Name</th>
                                    <th class="p-5">Email</th>
                                    <th class="p-5">Feedback Type</th>
                                    <th class="p-5">Status</th>
                                    <th class="p-5 text-center">Actions</th>
                                </tr>
                            </thead>
                            <tbody id="user-table-body" class="divide-y divide-slate-100 text-sm">
                                @foreach($feedbacks as $feedback)
                                <tr class="hover:bg-slate-50 transition group">
                                    <td class="p-5 text-slate-400">{{$feedbacks->firstItem() + $loop->index}}</td>
                                    <td class="p-5 font-semibold text-slate-700">{{$feedback->first_name}}</td>
                                    <td class="p-5 text-slate-600">{{$feedback->last_name}}</td>
                                    <td class="p-5 text-slate-600">{{$feedback->email}}</td>
                                    <td class="p-5 text-slate-600">{{$feedback->feedback_type}}</td>
                                    <td class="p-5 text-slate-600">{{$feedback->status}}</td>
                                    <td class="p-5">
                                        <div class="flex justify-center gap-2 ">
                                            <form action="{{ route('admin.manage.feedbacks.update', $feedback->id) }}" method="POST">
                                                @csrf
                                                @METHOD('PUT')
                                                <button class="p-2 rounded-lg text-slate-400 hover:text-green-600">
                                                    <i data-lucide="check" class="w-4 h-4"></i>
                                            </form>
                                            </button>
                                            <button class="p-2 rounded-lg text-slate-400 hover:text-blue-600" onclick="openviewFeedbackModal(this)" data-feedback='@json($feedback)'>
                                                <i data-lucide="eye" class="w-4 h-4"></i>
                                            </button>
                                            <button class="p-2 rounded-lg text-slate-400 hover:text-red-600"
                                                onclick="openDeleteModal( '{{ route('admin.manage.feedbacks.delete', $feedback->id) }}')">
                                                <i data-lucide="trash-2" class="w-4 h-4"></i>
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                                @endforeach

                            </tbody>
                        </table>
                    </div>
                    @if($feedbacks->hasPages())
                    <div class="p-5 border-t border-slate-100">
                        {{ $feedbacks->links() }}
                    </div>
                    @endif
                </section>
            </div>
        </main>
    </div>
    <div id="viewFeedbackModal" class="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50 hidden">
        <div class="bg-white rounded-2xl shadow-xl w-full max-w-md max-h-[90vh] overflow-y-auto p-6 space-y-6 relative">
            <button onclick="closeviewFeedbackModal()" class="absolute top-4 right-4 text-gray-400 hover:text-gray-600 text-2xl">&times;</button>
            <h2 class="text-xl font-bold mb-4">Feedback/Report</h2>
            <div class="space-y-2">
                <label class="block text-xs text-gray-500">First Name:</label>
                <input id="modal_first_name" class="w-full border rounded px-2 py-1" readonly placeholder="First Name">
                <label class="block text-xs text-gray-500">Last Name:</label>
                <input id="modal_last_name" class="w-full border rounded px-2 py-1" readonly placeholder="Last Name">
                <label class="block text-xs text-gray-500">Email Address:</label>
                <input id="modal_email" class="w-full border rounded px-2 py-1" readonly placeholder="Email">
                <label class="block text-xs text-gray-500">Feedback Type:</label>
                <input id="modal_feedback_type" class="w-full border rounded px-2 py-1" readonly placeholder="Feedback Type">
                <label class="block text-xs text-gray-500">Feedback Text:</label>
                <textarea id="modal_feedback_text" class="w-full border rounded px-2 py-1" readonly placeholder="Feedback Text"></textarea>
                <label class="block text-xs text-gray-500">Rating:</label>
                <div id="modal_rating" class="flex gap-1 text-2xl">
                    <span class="star text-gray-300">★</span>
                    <span class="star text-gray-300">★</span>
                    <span class="star text-gray-300">★</span>
                    <span class="star text-gray-300">★</span>
                    <span class="star text-gray-300">★</span>
                </div>
                <label class="block text-xs text-gray-500">Feedback Status:</label>
                <textarea id="modal_status" class="w-full border rounded px-2 py-1" readonly placeholder="Feedback Status"></textarea>
            </div>
        </div>
    </div>

    <div id="DeleteFeedback" class="fixed inset-0 bg-slate-900/50 backdrop-blur-sm flex items-center justify-center z-[100] hidden">
        <div class="bg-white rounded-2xl shadow-xl w-full max-w-md p-6">
            <div class="flex items-center gap-4 text-red-600 mb-4">
                <div class="p-3 bg-red-100 rounded-full"><i data-lucide="alert-triangle"></i></div>
                <h3 class="text-xl font-bold">Delete User Feedback?</h3>
            </div>
            <p class="text-slate-500 mb-6">Are you sure you want to delete this feedback? This action cannot be undone.</p>
            <form id="deleteFeedbackForm" method="POST" class="space-y-3">
                @csrf
                @method('DELETE')
                <button type="submit" class="w-full py-3 px-4 rounded-xl bg-red-600 text-white font-bold hover:bg-red-700 transition-colors">Yes, Delete Feedback</button>
                <button type="button" onclick="closeDeleteModal()" class="w-full py-3 px-4 rounded-xl border border-slate-200 text-slate-600 font-bold hover:bg-slate-50 transition-colors">Cancel</button>
            </form>
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', () => {
            lucide.createIcons();
            const currentPath = window.location.pathname;
            if (currentPath.includes('users')) {
                document.getElementById('nav-database')?.classList.add('active');
            }
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

        function openDeleteModal(url) {
            const form = document.getElementById('deleteFeedbackForm');
            form.action = url;
            document.getElementById('DeleteFeedback').classList.remove('hidden');
        }

        function closeDeleteModal() {
            document.getElementById('DeleteFeedback').classList.add('hidden');
        }

        function openviewFeedbackModal(button) {
            document.getElementById('viewFeedbackModal').classList.remove('hidden');

            const feedback = JSON.parse(button.getAttribute('data-feedback'));

            document.getElementById('modal_first_name').value = feedback.first_name || '';
            document.getElementById('modal_last_name').value = feedback.last_name || '';
            document.getElementById('modal_email').value = feedback.email || '';
            document.getElementById('modal_feedback_type').value = feedback.feedback_type || '';
            document.getElementById('modal_feedback_text').value = feedback.message || '';
            document.getElementById('modal_status').value = feedback.status || '';

            const stars = document.querySelectorAll('#modal_rating .star');
            const rating = parseInt(feedback.rating) || 0;

            stars.forEach((star, index) => {
                if (index < rating) {
                    star.classList.add('text-yellow-400');
                    star.classList.remove('text-gray-300');
                } else {
                    star.classList.remove('text-yellow-400');
                    star.classList.add('text-gray-300');
                }
            });
        }

        function closeviewFeedbackModal() {
            document.getElementById('viewFeedbackModal').classList.add('hidden');
        }

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