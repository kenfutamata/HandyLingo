@props(['user', 'notifications' => collect(), 'unreadNotifications' => collect()])

<header class="flex justify-between items-center h-16 px-8 border-b border-gray-200 bg-white/80 backdrop-blur-md sticky top-0 z-40">
    <div class="hidden md:block">
        <h1 class="text-xs font-bold text-gray-400 uppercase tracking-widest">Admin Control Panel</h1>
    </div>

    <div class="flex items-center space-x-6">
        <!-- Notifications Dropdown -->
        <div x-data="{ open: false }" class="relative">
            <button @click="open = !open" class="p-2 text-gray-400 hover:text-blue-600 rounded-full hover:bg-gray-100 transition-colors relative focus:outline-none">
                <i data-lucide="bell" class="w-6 h-6"></i>
                @if($unreadNotifications->isNotEmpty())
                    <span class="absolute top-2 right-2 w-2 h-2 bg-red-500 border-2 border-white rounded-full"></span>
                @endif
            </button>

            <div x-show="open" 
                 x-cloak
                 @click.away="open = false" 
                 x-transition:enter="transition ease-out duration-200"
                 x-transition:enter-start="opacity-0 scale-95 translate-y-2"
                 x-transition:enter-end="opacity-100 scale-100 translate-y-0"
                 class="absolute right-0 mt-3 w-80 bg-white border border-gray-200 rounded-xl shadow-xl z-50 overflow-hidden">
                
                <div class="px-4 py-3 border-b border-gray-100 flex justify-between items-center bg-slate-50/50">
                    <span class="font-bold text-gray-800">Notifications</span>
                    <span class="text-[10px] bg-blue-100 text-blue-600 px-2 py-0.5 rounded-full font-bold">{{ $unreadNotifications->count() }} NEW</span>
                </div>

                <div class="max-h-[350px] overflow-y-auto">
                    @forelse($notifications as $notification)
                        <div class="px-4 py-3 hover:bg-gray-50 border-b border-gray-50 transition-colors cursor-pointer group">
                            <p class="text-sm text-gray-800 {{ $notification->read_at ? '' : 'font-semibold' }}">
                                {{ $notification->data['message'] ?? 'Notification' }}
                            </p>
                            <span class="text-[10px] text-gray-400 mt-1 block">{{ $notification->created_at->diffForHumans() }}</span>
                        </div>
                    @empty
                        <div class="p-8 text-center">
                            <p class="text-sm text-gray-400 italic">All caught up!</p>
                        </div>
                    @endforelse
                </div>
                <button class="w-full py-2.5 text-center text-xs font-bold text-blue-600 bg-slate-50 hover:bg-slate-100 border-t border-gray-100 transition-colors">
                    VIEW ALL NOTIFICATIONS
                </button>
            </div>
        </div>

        <!-- Profile Badge -->
        <div class="flex items-center pl-6 border-l border-gray-200">
            <div class="text-right mr-3 hidden sm:block">
                <p class="text-sm font-bold text-slate-800 leading-none">{{ $user->first_name }}</p>
                <p class="text-[10px] text-slate-400 font-bold uppercase mt-1 tracking-tighter">{{ $user->role }}</p>
            </div>
            <div class="relative group cursor-pointer">
                <img src="{{ asset('assets/admin/handylingo.jpg') }}" 
                     class="w-10 h-10 rounded-xl border-2 border-white shadow-sm ring-1 ring-gray-200 group-hover:ring-blue-400 transition-all" />
                <span class="absolute -bottom-0.5 -right-0.5 w-3.5 h-3.5 bg-emerald-500 border-2 border-white rounded-full"></span>
            </div>
        </div>
    </div>
</header>