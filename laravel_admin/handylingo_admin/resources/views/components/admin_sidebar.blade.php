<aside class="w-64 bg-[#1e293b] text-slate-300 flex flex-col flex-shrink-0 z-50">
    <div class="p-6 border-b border-slate-700/50">
        <h1 class="text-xl font-bold text-white flex items-center">
            Admin Panel
        </h1>
    </div>

    <nav class="flex-1 px-4 space-y-1 mt-4">
        <a href="{{route('admin.dashboard')}}" id="nav-dashboard" class="sidebar-item active w-full flex items-center p-3 transition-all hover:text-white hover:bg-slate-800 rounded-lg group">
            <i data-lucide="layout-dashboard" class="mr-3 w-5 h-5 group-hover:scale-110 transition-transform"></i>
            <span class="font-medium">Dashboard</span>
        </a>
        <a href="{{route('admin.manage.users')}}" id="nav-database" class="sidebar-item w-full flex items-center p-3 transition-all hover:text-white hover:bg-slate-800 rounded-lg group">
            <i data-lucide="users" class="mr-3 w-5 h-5 group-hover:scale-110 transition-transform"></i>
            <span class="font-medium">Users</span>
        </a>
        <button onclick="" id="nav-feedback" class="sidebar-item w-full flex items-center p-3 transition-all hover:text-white hover:bg-slate-800 rounded-lg group">
            <i data-lucide="message-square" class="mr-3 w-5 h-5 group-hover:scale-110 transition-transform"></i>
            <span class="font-medium">Feedback</span>
        </button>
        <button onclick="" id="nav-updates" class="sidebar-item w-full flex items-center p-3 transition-all hover:text-white hover:bg-slate-800 rounded-lg group">
            <i data-lucide="refresh-cw" class="mr-3 w-5 h-5 group-hover:scale-110 transition-transform"></i>
            <span class="font-medium">Updates</span>
        </button>
        <button onclick="" id="nav-updates" class="sidebar-item w-full flex items-center p-3 transition-all hover:text-white hover:bg-slate-800 rounded-lg group">
            <i data-lucide="bar-chart-3" class="mr-3 w-5 h-5 group-hover:scale-110 transition-transform"></i>
            <span class="font-medium">Reports</span>
        </button>
    </nav>

    <div class="p-4 border-t border-slate-700/50">
        <a href="{{ route('admin.logout') }}" class="flex items-center p-3 w-full text-slate-400 hover:text-red-400 hover:bg-red-400/10 rounded-lg transition-all group">
            <i data-lucide="log-out" class="mr-3 w-5 h-5 group-hover:-translate-x-1 transition-transform"></i>
            <span class="font-medium">Log out</span>
        </a>
    </div>
</aside>