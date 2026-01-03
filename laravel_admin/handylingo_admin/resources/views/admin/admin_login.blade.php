<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Login</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://unpkg.com/lucide@latest"></script>
    <link rel="icon" type="image/x-icon" href="{{asset('assets/admin/handylingologo.png')}}">
    <script src="https://unpkg.com/lucide@latest"></script>

    <style>
        .loader {
            border: 3px solid #f3f3f3;
            border-top: 3px solid #ffffff;
            border-radius: 50%;
            width: 24px;
            height: 24px;
            animation: spin 1s linear infinite;
        }

        @keyframes spin {
            0% {
                transform: rotate(0deg);
            }

            100% {
                transform: rotate(360deg);
            }
        }

        .hidden {
            display: none;
        }
    </style>
</head>

<body class="bg-gray-100 min-h-screen flex flex-col font-sans">

    <header class="bg-[#22324A] text-white p-4 shadow-md">
        <h1 class="text-xl font-semibold max-w-7xl mx-auto">HandyLingo Admin Login</h1>
    </header>

    <!-- Login Container -->
    <main class="flex-1 flex items-center justify-center p-6">
        <div class="w-full max-w-[400px] bg-white p-8 rounded-2xl shadow-xl">
            @if(session('error'))
            <div id="notification-bar"
                class="fixed top-6 left-1/2 transform -translate-x-1/2 bg-red-500 text-white px-6 py-3 rounded shadow-lg z-50 opacity-100 transition-opacity duration-500 ease-in-out">
                {{ session('error') }}
            </div>
            @endif
            <h2 class="text-2xl font-bold text-[#22324A] text-center mb-8">
                Admin Login
            </h2>

            <form method="POST" action="{{route('admin.login.submit')}}" class="space-y-6">
                @csrf
                @method('POST')
                <div class="relative">
                    <label class="block text-gray-600 text-sm mb-1">Email</label>
                    <!-- Icon -->
                    <i data-lucide="mail" class="absolute left-3 top-10 w-5 h-5 text-gray-400"></i>
                    <!-- Input -->
                    <input
                        type="email"
                        id="email"
                        name="email"
                        placeholder="Admin Email"
                        required
                        class="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg
               focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition-all">
                </div>
                <div class="relative">
                    <label class="block text-gray-600 text-sm mb-1">Password</label>
                    <i data-lucide="key" class="absolute left-3 top-10 w-5 h-5 text-gray-400"></i>

                    <input
                        type="password"
                        id="password"
                        name='password'
                        placeholder="Password"
                        required
                        class="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition-all">
                </div>


                <!-- Login Button -->
                <button
                    type="submit"
                    id="submit"
                    name="submit"
                    class="w-full bg-[#21A1FF] hover:bg-blue-500 text-white font-bold py-3 px-4 rounded-lg transition-colors flex justify-center items-center shadow-lg">
                    <span id="btn-text">Login</span>
                    <div id="btn-spinner" class="loader hidden"></div>
                </button>
            </form>

        </div>
    </main>

    <script>
        setTimeout(() => {
            const notif = document.getElementById('notification-bar');
            if (notif) {
                notif.classList.remove("opacity-100");
                notif.classList.add("opacity-0");
                setTimeout(() => notif.remove(), 500);
            }
        }, 2500);
        lucide.createIcons();
    </script>
</body>

</html>