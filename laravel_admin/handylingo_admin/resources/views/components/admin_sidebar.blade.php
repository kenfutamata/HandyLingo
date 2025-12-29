<aside class="flex flex-col w-64 h-full bg-[#1e293b] text-slate-300 z-50 overflow-hidden border-r border-slate-700/50 flex-shrink-0">

    <!-- HEADER: Stays at top -->
    <div class="flex-none p-6 border-b border-slate-700/50">
        <h1 class="text-xl font-bold text-white uppercase tracking-wider">
            Admin Panel
        </h1>
    </div>

    <!-- NAVIGATION: Scrolls if content is too long -->
    <nav class="flex-1 min-h-0 px-4 py-4 space-y-1 overflow-y-auto custom-scrollbar">

        <a href="{{ route('admin.dashboard') }}" id="nav-dashboard"
           class="sidebar-item w-full flex items-center p-3 rounded-lg transition-all
           {{ request()->routeIs('admin.dashboard') ? 'active text-white bg-slate-800' : 'hover:text-white hover:bg-slate-800' }}">
            <i data-lucide="layout-dashboard" class="mr-3 w-5 h-5"></i>
            <span class="font-medium">Dashboard</span>
        </a>

        <a href="{{ route('admin.manage.users') }}" id="nav-users"
           class="sidebar-item w-full flex items-center p-3 rounded-lg transition-all
           {{ request()->routeIs('admin.manage.users') ? 'active text-white bg-slate-800' : 'hover:text-white hover:bg-slate-800' }}">
            <i data-lucide="users" class="mr-3 w-5 h-5"></i>
            <span class="font-medium">Users</span>
        </a>

        <button onclick="showSection('feedback')" id="nav-feedback" class="sidebar-item w-full flex items-center p-3 rounded-lg transition-all hover:text-white hover:bg-slate-800">
            <i data-lucide="message-square" class="mr-3 w-5 h-5"></i>
            <span class="font-medium">Feedback</span>
        </button>

        <button onclick="showSection('updates')" id="nav-updates" class="sidebar-item w-full flex items-center p-3 rounded-lg transition-all hover:text-white hover:bg-slate-800">
            <i data-lucide="refresh-cw" class="mr-3 w-5 h-5"></i>
            <span class="font-medium">Updates</span>
        </button>

        <button onclick="showSection('reports')" id="nav-reports" class="sidebar-item w-full flex items-center p-3 rounded-lg transition-all hover:text-white hover:bg-slate-800">
            <i data-lucide="bar-chart-3" class="mr-3 w-5 h-5"></i>
            <span class="font-medium">Reports</span>
        </button>

    </nav>

    <!-- FOOTER: Pinned to bottom -->
    <div class="flex-none p-4 border-t border-slate-700/50 mt-auto bg-[#1e293b]">
        <form method="GET" action="{{ route('admin.logout') }}">
            @csrf
            <button type="submit"
                class="flex items-center p-3 w-full text-slate-400 hover:text-red-400 hover:bg-red-400/10 rounded-lg transition-all group">
                <i data-lucide="log-out" class="mr-3 w-5 h-5 group-hover:-translate-x-1 transition-transform"></i>
                <span class="font-medium">Log out</span>
            </button>
        </form>
    </div>

</aside>