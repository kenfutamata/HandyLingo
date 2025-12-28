<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin - User Management</title>

    <!-- Tailwind -->
    <script src="https://cdn.tailwindcss.com"></script>

    <!-- Lucide Icons -->
    <script src="https://unpkg.com/lucide@latest"></script>

    <!-- Alpine.js -->
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
            background: #cbd5e1;
            border-radius: 10px;
        }
    </style>
</head>

<body class="bg-[#F8FAFC] font-sans text-slate-900 overflow-hidden">

    <!-- TOPBAR -->
    <x-admin_topbar :user="$user" />

    <div class="flex h-screen">

        <!-- SIDEBAR -->
        <x-admin_sidebar />

        <!-- MAIN CONTENT -->
        <main class="flex-1 overflow-y-auto p-4 md:p-8 pb-24">
            <div class="max-w-7xl mx-auto">

                <!-- USER MANAGEMENT -->
                <section id="section-database" class="hidden-section">

                    <!-- HEADER -->
                    <div class="flex flex-col md:flex-row justify-between items-start md:items-center mb-8 gap-4">
                        <div>
                            <h2 class="text-3xl font-extrabold">User Management</h2>
                            <p class="text-slate-500 text-sm mt-1">
                                Manage platform users and permissions
                            </p>
                        </div>
                    </div>

                    <!-- SEARCH / FILTER -->
                    <div class="flex flex-col md:flex-row gap-4 mb-4">
                        <input type="text"
                            placeholder="Search users..."
                            class="w-full md:w-1/3 px-4 py-2 rounded-xl border border-slate-200 focus:ring-2 focus:ring-blue-500 outline-none">

                        <select
                            class="w-full md:w-40 px-4 py-2 rounded-xl border border-slate-200 focus:ring-2 focus:ring-blue-500 outline-none">
                            <option>All Roles</option>
                            <option>Admin</option>
                            <option>User</option>
                        </select>
                    </div>

                    <!-- TABLE -->
                    <div class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-x-auto">
                        <table class="w-full text-left border-collapse min-w-[700px]">
                            <thead class="sticky top-0 bg-slate-50 z-10">
                                <tr class="border-b border-slate-200 text-slate-500 text-xs uppercase font-bold">
                                    <th class="p-5">#</th>
                                    <th class="p-5">First Name</th>
                                    <th class="p-5">Last Name</th>
                                    <th class="p-5">Email</th>
                                    <th class="p-5">Role</th>
                                    <th class="p-5">Status</th>
                                    <th class="p-5 text-center">Actions</th>
                                </tr>
                            </thead>

                            <tbody id="user-table-body" class="divide-y divide-slate-100 text-sm">

                                <!-- SAMPLE ROW -->
                                <tr class="hover:bg-slate-50 transition group">
                                    <td class="p-5">1</td>

                                    <td class="p-5">
                                        Juan
                                    </td>

                                    <td class="p-5 text-slate-600">
                                        Tamad
                                    </td>

                                    <td class="p-5 text-slate-600">
                                        juantamad@gmail.com
                                    </td>

                                    <td class="p-5">
                                        <span
                                            class="px-2.5 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-700">
                                            User
                                        </span>
                                    </td>
                                    <td class="p-5">
                                        <span
                                            class="px-2.5 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-700">
                                            Active
                                        </span>
                                    </td>
                                    <td class="p-5">
                                        <div
                                            class="flex justify-center gap-2 opacity-0 group-hover:opacity-100 transition">
                                            <button
                                                class="p-2 rounded-lg text-slate-400 hover:text-blue-600 hover:bg-blue-50">
                                                <i data-lucide="eye" class="w-4 h-4"></i>
                                            </button>
                                            <button
                                                class="p-2 rounded-lg text-slate-400 hover:text-red-600 hover:bg-red-50"
                                                onclick="openDeleteModal('/admin/users/1')">
                                                <i data-lucide="trash-2" class="w-4 h-4"></i>
                                            </button>
                                        </div>
                                    </td>
                                </tr>

                                <!-- EMPTY STATE (OPTIONAL) -->
                                <!--
                                <tr>
                                    <td colspan="5" class="p-10 text-center text-slate-500">
                                        <i data-lucide="users" class="mx-auto mb-3 w-6 h-6"></i>
                                        No users found
                                    </td>
                                </tr>
                                -->

                            </tbody>
                        </table>
                    </div>

                </section>

            </div>
        </main>
    </div>
    <div id="DeleteUser" class="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50 hidden">
        <div class="bg-white rounded-2xl shadow-xl w-full max-w-md p-6 space-y-6">
            <div class="flex justify-between items-center">
                <h3 class="text-xl font-semibold">Delete User Account?</h3>
                <button onclick="closeDeleteModal()" class="text-gray-400 hover:text-gray-600 text-2xl">×</button>
            </div>
            <form id="deleteJobApplicantAccount" method="POST" action="">
                @csrf
                @method('DELETE')
                <button type="submit" class="w-full py-3 px-4 rounded-lg bg-green-100">Yes</button>
            </form>
            <button onclick="closeDeleteModal()" class="w-full py-3 px-4 rounded-lg border border-gray-300 hover:bg-gray-50 text-gray-700">Cancel</button>
        </div>
    </div>

    <!-- SCRIPTS -->
    <script>
        document.addEventListener('DOMContentLoaded', () => {
            lucide.createIcons();
            showSection('database');
        });

        // SECTION SWITCHER
        window.showSection = (sectionId) => {
            document.querySelectorAll('main section')
                .forEach(section => section.classList.add('hidden-section'));

            const activeSection = document.getElementById(`section-${sectionId}`);
            if (activeSection) activeSection.classList.remove('hidden-section');

            document.querySelectorAll('.sidebar-item')
                .forEach(item => item.classList.remove('active'));

            const activeNav = document.getElementById(`nav-${sectionId}`);
            if (activeNav) activeNav.classList.add('active');

            lucide.createIcons();
        };

        window.openUserModal = () =>
            document.getElementById('user-modal')?.classList.remove('hidden');

        window.closeUserModal = () =>
            document.getElementById('user-modal')?.classList.add('hidden');

        function openDeleteModal(url) {
            const form = document.getElementById('deleteJobApplicantAccount');
            form.action = url;
            document.getElementById('DeleteUser').classList.remove('hidden');
        }

        function closeDeleteModal() {
            document.getElementById('DeleteUser').classList.add('hidden');
        }
    </script>

</body>

</html>