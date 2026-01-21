<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin - User Management</title>

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

                <section id="section-database">
                    <div class="flex flex-col md:flex-row justify-between items-start md:items-center mb-8 gap-4">
                        <div>
                            <h2 class="text-3xl font-extrabold text-slate-800">User Management</h2>
                            <p class="text-slate-500 text-sm mt-1">Manage platform users and permissions</p>
                        </div>
                    </div>


                    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4 mb-6">

                        <!-- SEARCH -->
                        <form method="GET" action="{{ route('admin.manage.users') }}" class="w-full md:w-auto">
                            <div class="relative w-full md:w-80">
                                <i data-lucide="search"
                                    class="w-4 h-4 absolute left-4 top-1/2 -translate-y-1/2 text-slate-400"></i>

                                <input
                                    type="text"
                                    name="search"
                                    placeholder="Search users..."
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
                        </form>

                        <!-- EXPORT -->
                        <a href="{{route('admin.manage.users.export')}}"
                            class="inline-flex items-center gap-2 
              bg-emerald-500 hover:bg-emerald-600 
              text-white text-sm font-semibold 
              px-5 py-2.5 rounded-xl shadow-sm transition">
                            <i data-lucide="file-spreadsheet" class="w-4 h-4"></i>
                            Export to Excel
                        </a>

                    </div>
                    <!-- TABLE -->
                    <div class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-x-auto">
                        <table class="w-full text-left border-collapse min-w-[700px]">
                            <thead class="bg-slate-50">
                                <tr class="border-b border-slate-200 text-slate-500 text-xs uppercase font-bold">
                                    <th class="p-5">#</th>
                                    <th class="p-5">Username</th>
                                    <th class="p-5">First Name</th>
                                    <th class="p-5">Last Name</th>
                                    <th class="p-5">Email</th>
                                    <th class="p-5">Role</th>
                                    <th class="p-5">Status</th>
                                    <th class="p-5 text-center">Actions</th>
                                </tr>
                            </thead>
                            <tbody id="user-table-body" class="divide-y divide-slate-100 text-sm">
                                @foreach($users as $user)
                                <tr class="hover:bg-slate-50 transition group">
                                    <td class="p-5 text-slate-400">{{$users->firstItem() + $loop->index}}</td>
                                    <td class="p-5 font-semibold text-slate-700">{{$user->user_name}}</td>
                                    <td class="p-5 font-semibold text-slate-700">{{$user->first_name}}</td>
                                    <td class="p-5 text-slate-600">{{$user->last_name}}</td>
                                    <td class="p-5 text-slate-600">{{$user->email}}</td>
                                    <td class="p-5">
                                        <span class="px-2.5 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-700">{{ucfirst($user->role)}}</span>
                                    </td>
                                    <td class="p-5">
                                        <span class="px-2.5 py-1 rounded-full text-xs font-medium bg-emerald-100 text-emerald-700">{{ucfirst($user->status)}}</span>
                                    </td>
                                    <td class="p-5">
                                        <div class="flex justify-center gap-2 ">
                                            <button onclick="openUserModal({{ json_encode($user) }})" class="p-2 rounded-lg text-slate-400 hover:text-blue-600">
                                                <i data-lucide="eye" class="w-4 h-4"></i>
                                            </button>
                                            <button class="p-2 rounded-lg text-slate-400 hover:text-red-600"
                                                onclick="openDeleteModal( '{{ route('admin.manage.users.delete', $user->id) }}')">
                                                <i data-lucide="trash-2" class="w-4 h-4"></i>
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            </tbody>
                            @endforeach
                        </table>
                    </div>
                    @if($users->hasPages())
                    <div class="p-5 border-t border-slate-100">
                        {{ $users->links() }}
                    </div>
                    @endif
                </section>
            </div>
        </main>
    </div>

    <div id="viewProfileModal" class="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50 hidden backdrop-blur-sm">
        <div class="bg-white rounded-2xl shadow-xl w-full max-w-md max-h-[90vh] overflow-y-auto p-6 space-y-6 relative">
            <button onclick="closeUserModal()" class="absolute top-2 right-2 text-gray-500 hover:text-gray-700" aria-label="Close">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
            </button>
            <h2 class="text-xl font-bold mb-4">User Profile</h2>
            <div class="space-y-2">
                <label class="block text-xs text-gray-500">Username:</label>
                <input id="modal_user_name" class="w-full border rounded px-2 py-1" readonly placeholder="Username">
                <label class="block text-xs text-gray-500">First Name:</label>
                <input id="modal_first_name" class="w-full border rounded px-2 py-1" readonly placeholder="First Name">
                <label class="block text-xs text-gray-500">Last Name:</label>
                <input id="modal_last_name" class="w-full border rounded px-2 py-1" readonly placeholder="Last Name">
                <label class="block text-xs text-gray-500">Email Address:</label>
                <input id="modal_email" class="w-full border rounded px-2 py-1" readonly placeholder="Email">
                <label class="block text-xs text-gray-500">Role:</label>
                <input id="modal_role" class="w-full border rounded px-2 py-1" readonly placeholder="Role">
                <label class="block text-xs text-gray-500">Status:</label>
                <input id="modal_status" class="w-full border rounded px-2 py-1" readonly placeholder="Status">
            </div>
        </div>
    </div>

    <div id="DeleteUser" class="fixed inset-0 bg-slate-900/50 backdrop-blur-sm flex items-center justify-center z-[100] hidden">
        <div class="bg-white rounded-2xl shadow-xl w-full max-w-md p-6">
            <div class="flex items-center gap-4 text-red-600 mb-4">
                <div class="p-3 bg-red-100 rounded-full"><i data-lucide="alert-triangle"></i></div>
                <h3 class="text-xl font-bold">Delete Account?</h3>
            </div>
            <p class="text-slate-500 mb-6">Are you sure you want to delete this user? This action cannot be undone.</p>
            <form id="deleteUserForm" method="POST" class="space-y-3">
                @csrf
                @method('DELETE')
                <button type="submit" class="w-full py-3 px-4 rounded-xl bg-red-600 text-white font-bold hover:bg-red-700 transition-colors">Yes, Delete Account</button>
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
            const form = document.getElementById('deleteUserForm');
            form.action = url;
            document.getElementById('DeleteUser').classList.remove('hidden');
        }

        function closeDeleteModal() {
            document.getElementById('DeleteUser').classList.add('hidden');
        }

        function openUserModal(user) {
            document.getElementById('modal_user_name').value = user.user_name;
            document.getElementById('modal_first_name').value = user.first_name;
            document.getElementById('modal_last_name').value = user.last_name;
            document.getElementById('modal_email').value = user.email;
            document.getElementById('modal_role').value = user.role;
            document.getElementById('modal_status').value = user.status;
            document.getElementById('viewProfileModal').classList.remove('hidden');
        }

        function closeUserModal() {
            document.getElementById('viewProfileModal').classList.add('hidden');
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