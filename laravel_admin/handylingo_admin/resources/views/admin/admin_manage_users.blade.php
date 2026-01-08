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
        <x-admin_topbar :user="$user" />
    </div>

    <div class="flex flex-1 overflow-hidden">

        <x-admin_sidebar />

        <main class="flex-1 overflow-y-auto p-4 md:p-8 pb-24">
            <div class="max-w-7xl mx-auto">

                <section id="section-database">
                    <div class="flex flex-col md:flex-row justify-between items-start md:items-center mb-8 gap-4">
                        <div>
                            <h2 class="text-3xl font-extrabold text-slate-800">User Management</h2>
                            <p class="text-slate-500 text-sm mt-1">Manage platform users and permissions</p>
                        </div>
                    </div>


                    <form method="GET" action="{{ route('admin.manage.users') }}" class="mb-6">
                        <div class="flex flex-col md:flex-row gap-4">
                            <div class="relative w-full md:w-1/3">
                                <i data-lucide="search"
                                    class="w-4 h-4 absolute left-4 top-1/2 -translate-y-1/2 text-slate-400">
                                </i>

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
                        </div>
                    </form>

                    <!-- TABLE -->
                    <div class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-x-auto">
                        <table class="w-full text-left border-collapse min-w-[700px]">
                            <thead class="bg-slate-50">
                                <tr class="border-b border-slate-200 text-slate-500 text-xs uppercase font-bold">
                                    <th class="p-5">#</th>
                                    <th class="p-5">First Name</th>
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
                                        @if($user->role == 'user')
                                        <span class="px-2.5 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-700">User</span>
                                        @endif
                                    </td>
                                    <td class="p-5">
                                        @if($user->status == 'active')
                                        <span class="px-2.5 py-1 rounded-full text-xs font-medium bg-emerald-100 text-emerald-700">Active</span>
                                        @endif
                                    </td>
                                    <td class="p-5">
                                        <div class="flex justify-center gap-2 ">
                                            <button class="p-2 rounded-lg text-slate-400 hover:text-blue-600">
                                                <i data-lucide="eye" class="w-4 h-4"></i>
                                            </button>
                                            <button class="p-2 rounded-lg text-slate-400 hover:text-red-600"
                                                onclick="openDeleteModal('/admin/users/1')">
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
    <div id="viewJobDetailsModal" class="fixed inset-0 bg-black bg-opacity-40 z-50 flex items-center justify-center hidden" aria-hidden="true" aria-modal="true" role="dialog">
        <div class="relative bg-white rounded-lg w-full max-w-6xl mx-4 overflow-auto max-h-[90vh] p-8 flex flex-col gap-6 transform transition-all scale-95 opacity-0" id="modalContent">
            <button onclick="closeViewJobDetailsModal()" class="absolute top-4 right-4 text-gray-600 hover:text-black text-2xl font-bold">&times;</button>

            <div class="flex flex-col md:flex-row gap-6">
                <div class="flex-shrink-0">
                    <img id="modal-companyLogo" src="" alt="Company Logo" class="w-44 h-auto border rounded hidden" />
                </div>
                <div>
                    <h2 id="modal-companyName" class="text-2xl font-semibold text-gray-800">Company Name</h2>
                    <p id="modal-position" class="text-xl text-gray-700 mt-1">Position</p>
                </div>
            </div>

            <div class="flex flex-col md:flex-row gap-6">
                <div class="border w-full md:max-w-xs p-4 flex flex-col gap-4">
                    <h3 class="text-lg font-semibold border-b pb-2">Job Information</h3>
                    <div class="space-y-3 text-sm">
                        <p><strong>Disability Type:</strong> <span id="modal-disabilityType" class="text-blue-600"></span></p>
                        <p><strong>Salary:</strong> <span id="modal-salaryRange" class="text-blue-600"></span></p>
                        <p><strong>Contact:</strong> <span id="modal-contactPhone" class="text-blue-600"></span></p>
                        <p><strong>Email:</strong> <span id="modal-contactEmail" class="text-blue-600"></span></p>
                        <p><strong>Environment:</strong> <span id="modal-workEnvironment" class="text-blue-600"></span></p>
                        <p><strong>Category:</strong> <span id="modal-category" class="text-blue-600"></span></p>
                        <p><strong>Company Address:</strong> <span id="modal-companyAddress" class="text-blue-600"></span></p>
                    </div>
                </div>

                <div class="flex-1 flex flex-col gap-6">
                    <div class="border p-4">
                        <h3 class="text-lg font-semibold border-b pb-2 mb-2">Job Description</h3>
                        <p id="modal-description" class="text-sm text-gray-700 leading-relaxed"></p>
                    </div>
                    <div class="border p-4">
                        <h3 class="text-lg font-semibold border-b pb-2 mb-2">Educational Attainment</h3>
                        <p id="modal-educationalAttainment" class="text-sm text-gray-700"></p>
                    </div>
                    <div class="border p-4">
                        <h3 class="text-lg font-semibold border-b pb-2 mb-2">Skills</h3>
                        <p id="modal-skills" class="text-sm text-gray-700"></p>
                    </div>
                    <div class="border p-4">
                        <h3 class="text-lg font-semibold border-b pb-2 mb-2">Requirements</h3>
                        <p id="modal-requirements" class="text-sm text-gray-700"></p>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div id="viewProfileModal" class="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50 hidden">
        <div class="bg-white rounded-2xl shadow-xl w-full max-w-md max-h-[90vh] overflow-y-auto p-6 space-y-6">
            <button onclick="closeUserModal()" class="absolute top-2 right-2 text-gray-500 hover:text-gray-700">&times;</button>
            <h2 class="text-xl font-bold mb-4">Applicant Profile</h2>
            <div class="space-y-2">
                <label class="block text-xs text-gray-500">First Name:</label>
                <input id="modal_firstName" class="w-full border rounded px-2 py-1" readonly placeholder="First Name">
                <label class="block text-xs text-gray-500">Last Name:</label>
                <input id="modal_lastName" class="w-full border rounded px-2 py-1" readonly placeholder="Last Name">
                <label class="block text-xs text-gray-500">Email Address:</label>
                <input id="modal_email" class="w-full border rounded px-2 py-1" readonly placeholder="Email">
                <label class="block text-xs text-gray-500">Address:</label>
                <input id="modal_address" class="w-full border rounded px-2 py-1" readonly placeholder="Address">
                <label class="block text-xs text-gray-500">Province:</label>
                <input id="modal_province" class="w-full border rounded px-2 py-1" readonly placeholder="Address">
                <label class="block text-xs text-gray-500">City:</label>
                <input id="modal_city" class="w-full border rounded px-2 py-1" readonly placeholder="Address">
                <label class="block text-xs text-gray-500">Phone Number:</label>
                <input id="modal_phoneNumber" class="w-full border rounded px-2 py-1" readonly placeholder="Phone Number">
                <label class="block text-xs text-gray-500">Date of Birth:</label>
                <input id="modal_dateOfBirth" class="w-full border rounded px-2 py-1" readonly placeholder="Date of Birth">
                <label class="block text-xs text-gray-500">PWD ID:</label>
                <input id="modal_pwdId" class="w-full border rounded px-2 py-1" readonly placeholder="PWD ID">
                <label class="block text-xs text-gray-500">Disability:</label>
                <input id="typeOfDisability" class="w-full border rounded px-2 py-1" readonly placeholder="Type of Disability">
                <div>
                    <label class="block text-xs text-gray-500">PWD Card:</label>
                    <img id="modal_pwd_card" class="w-16 h-16 object-cover border rounded" style="display:none;">
                </div>
                <div>
                    <label class="block text-xs text-gray-500">Profile Picture:</label>
                    <img id="modal_profilePicture" class="w-16 h-16 object-cover border rounded" style="display:none;">
                </div>
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
            <form id="deleteUserForm" method="POST" action="" class="space-y-3">
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
    </script>
</body>

</html>