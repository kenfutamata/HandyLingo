<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>HANDYLINGO</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" cross origin>
    <link href="https://fonts.googleapis.com/css2?family=Open+Sans:wght@400;600;700&family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@3.3.3/dist/tailwind.min.css" rel="stylesheet">
    <link rel="stylesheet" href="{{ asset('assets/landing_page/css/landing_page.css') }}">
    <script src="https://cdn.tailwindcss.com"></script>

    <link rel="icon" type="image/x-icon" href="{{asset('assets/admin/handylingologo.png')}}">
</head>

<body class="bg-white text-gray-800">
    @if(session('Success'))
    <div id="notification-bar" class="fixed top-6 left-1/2 transform -translate-x-1/2 bg-green-500 text-white px-6 py-3 rounded shadow-lg z-50">
        {{ session('Success') }}
    </div>
    @elseif(session('error'))
    <div id="notification-bar" class="fixed top-6 left-1/2 transform -translate-x-1/2 bg-red-500 text-white px-6 py-3 rounded shadow-lg z-50">
        {{ session('error') }}
    </div>
    @endif
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@3.3.3/dist/tailwind.min.css" rel="stylesheet">

    <header class="bg-blue-300 w-full shadow-sm">
        <div class="max-w-screen-xl mx-auto flex items-center justify-between px-4 sm:px-8 py-3 relative">
            <a href="{{ route('admin.landingpage') }}" class="flex items-center gap-2 no-underline">
                <img src="{{ asset('assets/admin/handylingologo.png') }}" alt="EquiJob Logo" class="w-12 h-12 object-contain" />
                <span class="text-sm font-semibold text-[#0b3c5d]">HandyLingo</span>
            </a>

            <nav class="hidden md:flex gap-8 text-sm font-semibold text-white">
                <a href="#about-us" class="text-gray-100 hover:text-green-300 transition">About Us</a>
                <a href="#features" class="text-gray-100 hover:text-green-300 transition">Features</a>
                <a href="#our-team" class="text-gray-100 hover:text-green-300 transition">Our Team</a>
                <a href="#contact-us" class="text-gray-100 hover:text-green-300 transition">Contact Us</a>
            </nav>
            <!--  Menu Button -->
            <div class="md:hidden">
                <button id="mobile-menu-button" class="text-gray-700 focus:outline-none">
                    <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6" fill="none"
                        viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round"
                            stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                    </svg>
                </button>
            </div>

            <div id="mobile-menu" class="absolute top-full right-4 mt-2 w-48 bg-white rounded-lg shadow-lg border hidden md:hidden z-50">
                <a href="#about-us" class="block px-4 py-2 text-sm text-gray-700 hover:bg-blue-100">About Us</a>
                <a href="#features" class="block px-4 py-2 text-sm text-gray-700 hover:bg-blue-100">Features</a>
                <a href="#our-team" class="block px-4 py-2 text-sm text-gray-700 hover:bg-blue-100">Our Team</a>
                <a href="#contact-us" class="block px-4 py-2 text-sm text-gray-700 hover:bg-blue-100">Contact Us</a>
            </div>
        </div>
    </header>
    </nav>

    <!-- Hero Section -->
    <section id="hero" class="relative overflow-hidden bg-gradient-to-br from-blue-600 via-blue-500 to-indigo-600 text-white">
        <div class="container mx-auto px-6 lg:px-16 py-24 flex flex-col-reverse lg:flex-row items-center gap-16">

            <!-- Left Content -->
            <div class="lg:w-1/2 text-center lg:text-left">
                <span class="inline-block mb-4 px-4 py-1 text-sm font-semibold rounded-full bg-white/20 backdrop-blur">
                    AI • Accessibility • Inclusion
                </span>

                <h1 class="text-4xl md:text-5xl lg:text-6xl font-extrabold leading-tight mb-6">
                    AI-Powered <span class="text-green-300">Sign Language</span><br />
                    Translator for Everyone
                </h1>

                <p class="text-lg text-white/90 max-w-xl mx-auto lg:mx-0 mb-8">
                    Break communication barriers with real-time sign language translation powered by artificial intelligence. Designed for people with hearing impairments.
                </p>

                <!-- CTA Buttons -->
                <div class="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start">
                    <a href="#"
                        class="inline-flex items-center justify-center gap-2 bg-green-500 hover:bg-green-600 text-white text-lg font-semibold px-8 py-3 rounded-xl shadow-lg transition duration-300">
                        Download App
                    </a>
                </div>
            </div>

            <!-- Right Image -->
            <div class="lg:w-1/2 relative flex justify-center">
                <div class="absolute -top-10 -right-10 w-72 h-72 bg-green-400/30 rounded-full blur-3xl"></div>

                <img src="{{ asset('assets/landing_page/handylingophone.png') }}"
                    alt="HandyLingo Mobile App"
                    class="relative w-[320px] md:w-[380px] lg:w-[420px] drop-shadow-2xl animate-float" />
            </div>

        </div>
    </section>

    <section id="about-us" class="relative min-h-screen bg-blue-800 text-white flex items-center">
        <img src="{{ asset('assets/landing_page/handylingo_documentation.png') }}"
            alt="Main background"
            class="absolute inset-0 w-full h-full object-cover opacity-40">

        <div class="relative max-w-4xl mx-auto px-6 text-center space-y-8">
            <h1 class="text-5xl md:text-6xl font-bold">About Us</h1>

            <p class="text-lg md:text-xl leading-relaxed">
                “HandyLingo: a Capstone Project is an AI-Powered Mobile Application that translates sign language into text and vice versa. HandyLingo is better served with persons with hearing barriers which the system
                is well benefited for them.”
            </p>

            <a href="#about"
                class="inline-block bg-yellow-300 text-black px-6 py-3 rounded-lg
                   font-semibold hover:bg-yellow-400 transition">
                See More
            </a>
        </div>
    </section>



    <!-- Features Section -->
    <section id="features" class="py-20 lg:py-32 px-6 lg:px-16 bg-gradient-to-b from-white to-slate-50">
        <div class="container mx-auto">

            <!-- Section Header -->
            <div class="text-center max-w-3xl mx-auto mb-14">
                <h2 class="text-3xl md:text-4xl font-bold font-poppins text-gray-800 mb-4">
                    HandyLingo Features
                </h2>
                <p class="text-gray-600 text-lg">
                    Empowering communication through intelligent and accessible sign language technology.
                </p>
            </div>

            <!-- Feature Cards -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-10">

                <!-- Card 1 -->
                <div class="group bg-white rounded-2xl shadow-md hover:shadow-xl transition-all duration-300 overflow-hidden">

                    <div class="bg-sky-50 h-72 flex items-center justify-center p-6">
                        <img src="{{ asset('assets/landing_page/feature2.png') }}"
                            alt="User-Friendly Dashboard"
                            class="h-full w-auto object-contain transition-transform duration-300 group-hover:scale-105">
                    </div>

                    <div class="p-6">
                        <h3 class="text-xl font-semibold font-poppins mb-3 text-gray-800">
                            User-Friendly Dashboard
                        </h3>
                        <p class="text-gray-600 leading-relaxed">
                            Manage your profile, preferences, and activity effortlessly with an intuitive and clean dashboard experience.
                        </p>
                    </div>
                </div>

                <div class="group bg-white rounded-2xl shadow-md hover:shadow-xl transition-all duration-300 overflow-hidden">

                    <div class="bg-sky-50 h-72 flex items-center justify-center p-6">
                        <img src="{{ asset('assets/landing_page/feature1.png') }}"
                            alt="Text to Sign Language"
                            class="h-full w-auto object-contain transition-transform duration-300 group-hover:scale-105">
                    </div>

                    <div class="p-6">
                        <h3 class="text-xl font-semibold font-poppins mb-3 text-gray-800">
                            Text to Sign Language
                        </h3>
                        <p class="text-gray-600 leading-relaxed">
                            Instantly convert written text into sign language, enabling clearer and more inclusive communication.
                        </p>
                    </div>
                </div>

                <div class="group bg-white rounded-2xl shadow-md hover:shadow-xl transition-all duration-300 overflow-hidden">

                    <div class="bg-sky-50 h-72 flex items-center justify-center p-6">
                        <img src="{{ asset('assets/landing_page/feature3.png') }}"
                            alt="Sign Language to Text"
                            class="h-full w-auto object-contain transition-transform duration-300 group-hover:scale-105">
                    </div>

                    <div class="p-6">
                        <h3 class="text-xl font-semibold font-poppins mb-3 text-gray-800">
                            Sign Language to Text
                        </h3>
                        <p class="text-gray-600 leading-relaxed">
                            Translate sign language gestures into readable text, bridging communication gaps in real time.
                        </p>
                    </div>
                </div>

            </div>
        </div>
    </section>

    <!-- Team Section -->
    <section id="our-team" class="py-20 px-6 md:px-16 bg-white">
        <h2 class="text-4xl font-semibold text-center mb-12">Meet Our Team</h2>

        <div class="max-w-6xl mx-auto grid sm:grid-cols-2 lg:grid-cols-3 gap-8">
            <div class="bg-gray-50 p-6 rounded-2xl shadow-lg hover:shadow-2xl transition transform hover:-translate-y-2">
                <img src="{{ asset('assets/landing_page/landy.png') }}" alt="Team Member" class="w-24 h-24 mx-auto rounded-full mb-4">
                <h3 class="text-xl font-medium text-center">Luxury Landy Joren</h3>
                <p class="text-blue-600 text-center font-medium">Project Manager</p>
                <p class="text-gray-600 text-sm mt-2 text-center">HandyLingo's Team Leader. Manages the team.</p>
            </div>

            <div class="bg-gray-50 p-6 rounded-2xl shadow-lg hover:shadow-2xl transition transform hover:-translate-y-2">
                <img src="{{ asset('assets/landing_page/shan.png') }}" alt="Team Member" class="w-24 h-24 mx-auto rounded-full mb-4">
                <h3 class="text-xl font-medium text-center">Shan Harielle A. Geraldez</h3>
                <p class="text-blue-600 text-center font-medium">Hacker</p>
                <p class="text-gray-600 text-sm mt-2 text-center">Develops HandyLingo with the aligned functions selected for the benefit for Hearing Problems.</p>
            </div>

            <div class="bg-gray-50 p-6 rounded-2xl shadow-lg hover:shadow-2xl transition transform hover:-translate-y-2">
                <img src="{{ asset('assets/landing_page/jelio.png') }}" alt="Team Member" class="w-24 h-24 mx-auto rounded-full mb-4">
                <h3 class="text-xl font-medium text-center">Jeilo R. Sapanta </h3>
                <p class="text-blue-600 text-center font-medium">Hipster</p>
                <p class="text-gray-600 text-sm mt-2 text-center">Designs HandyLingo's Interface.</p>
            </div>
        </div>

        <div class="max-w-4xl mx-auto mt-16 grid grid-cols-1 md:grid-cols-2 gap-10">
            <div class="bg-white border border-gray-200 rounded-2xl shadow-xl hover:shadow-2xl transition transform hover:-translate-y-2">
                <div class="p-6 text-center">
                    <img src="{{ asset('assets/landing_page/kevin.png') }}" alt="Team Member" class="w-20 h-20 mx-auto rounded-full mb-4">
                    <h3 class="text-lg font-semibold">James Kevin P. Velasco</h3>
                    <p class="text-blue-600 font-medium">Hustler</p>
                    <p class="text-gray-600 text-sm mt-2">Manages the Documents and promotes HandyLingo.</p>
                </div>
            </div>

            <div class="bg-white border border-gray-200 rounded-2xl shadow-xl hover:shadow-2xl transition transform hover:-translate-y-2">

                <div class="p-6 text-center">
                    <img src="{{ asset('assets/landing_page/eric.png') }}" alt="Team Member" class="w-20 h-20 mx-auto rounded-full mb-4">
                    <h3 class="text-lg font-semibold">Carl Eric C. Monroid</h3>
                    <p class="text-blue-600 font-medium">Tester</p>
                    <p class="text-gray-600 text-sm mt-2">Tests the system to ensure full functionality of HandyLingo.</p>
                </div>
            </div>
        </div>
    </section>

    <section id="contact-us" class="bg-slate-50 py-20 px-6">
        <div class="max-w-6xl mx-auto">

            <!-- Header -->
            <div class="text-center mb-16">
                <h1 class="text-5xl md:text-6xl font-bold text-gray-900 mb-4">
                    Contact Us
                </h1>
                <p class="text-xl text-gray-600 max-w-3xl mx-auto">
                    Have questions or concerns? We’re here to help. Send us a message and we’ll get back to you shortly.
                </p>
            </div>

            <!-- Form Card -->
            <div class="bg-white rounded-3xl shadow-xl p-8 md:p-12">
                <h2 class="text-3xl font-semibold text-gray-800 mb-8">
                    How may we help you?
                </h2>

                <form class="space-y-8" action="{{route('submit.feedback')}}" method="POST">
                    @csrf
                    <!-- Name Fields -->
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                        <div>
                            <label class="block text-lg font-semibold text-gray-700 mb-2">
                                First Name <span class="text-red-500">*</span>
                            </label>
                            <input
                                type="text"
                                name="first_name"
                                id="last_name"
                                placeholder="John"
                                class="w-full p-4 border-2 border-gray-300 rounded-xl text-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition"
                                pattern="[A-Za-z\s]+"
                                required>
                        </div>

                        <div>
                            <label class="block text-lg font-semibold text-gray-700 mb-2">
                                Last Name <span class="text-red-500">*</span>
                            </label>
                            <input
                                type="text"
                                name="last_name"
                                id="last_name"
                                placeholder="Doe"
                                class="w-full p-4 border-2 border-gray-300 rounded-xl text-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition"
                                pattern="[A-Za-z\s]+"
                                required>
                        </div>
                    </div>

                    <!-- Email -->
                    <div>
                        <label class="block text-lg font-semibold text-gray-700 mb-2">
                            Email Address <span class="text-red-500">*</span>
                        </label>
                        <input
                            type="email"
                            id="email"
                            name="email"
                            placeholder="you@example.com"
                            class="w-full p-4 border-2 border-gray-300 rounded-xl text-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition"
                            required>
                    </div>
                    <!-- Topic -->
                    <div>
                        <label class="block text-lg font-semibold text-gray-700 mb-2">
                            Which HandyLingo topic fits your needs? <span class="text-red-500">*</span>
                        </label>
                        <select
                            class="w-full p-4 border-2 border-gray-300 rounded-xl text-lg bg-white focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition"
                            id="feedback_type"
                            name="feedback_type"
                            required>
                            <option disabled selected>Select HandyLingo Topic</option>
                            <option>App Feedback</option>
                            <option>Issue Report</option>
                        </select>
                    </div>

                    <!-- Message -->
                    <div>
                        <label class="block text-lg font-semibold text-gray-700 mb-2">
                            Message
                        </label>
                        <textarea
                            rows="5"
                            name="message"
                            id="message"
                            placeholder="Tell us more about your concern or Feedback."
                            class="w-full p-4 border-2 border-gray-300 rounded-xl text-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition resize-none"></textarea>
                    </div>
                    <!-- Submit Button -->
                    <div class="text-center pt-6">
                        <button
                            type="submit"
                            class="bg-blue-600 hover:bg-blue-700 text-white px-14 py-4 text-xl font-bold rounded-2xl shadow-lg transition transform hover:-translate-y-1 focus:outline-none focus:ring-4 focus:ring-blue-300">
                            Submit Message
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </section>

    <footer id="footer" class="bg-blue-400 pt-16 pb-8 px-6 lg:px-16 text-gray-700 flex justify-center items-center">
        <div class="container mx-auto flex flex-col justify-center items-center">
            <img src="{{ asset('assets/admin/handylingologo.png') }}" alt="HandyLingo Logo" class="mx-auto w-32 h-auto mb-4">
            <p class="text-sm text-gray-600 leading-relaxed text-center max-w-xl">
                AI-Powered Sign Language Translator for People with Hearing problems.
            </p>
            <p class="text-sm text-gray-600 leading-relaxed text-center max-w-xl">
                Copyright &copy; 2026 HandyLingo. All rights reserved.
            </p>
            <a href="{{route('admin.login')}}" class="text-sm-100 hover:text-green-300 transition">Admin Login</a>

        </div>
    </footer>

</body>


<script src="{{ asset('assets/landing_page/js/landing_page.js') }}"></script>

</html>