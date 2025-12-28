<?php

use App\Http\Controllers\AdminDashboard;
use App\Http\Controllers\AdminLoginController;
use App\Http\Controllers\UsersController;
use App\Http\Middleware\FirebaseMiddleware;
use Illuminate\Support\Facades\Route;


//Admin Login Route 
Route::get('/', [AdminLoginController::class, 'showLoginForm'])->name('admin.login');
Route::post('/login', [AdminLoginController::class, 'login'])->name('admin.login.submit');

Route::middleware('auth:admin')->group(function () {
    //Dasboard and logout routes
    Route::get('/handylingoadmin/dashboard', [AdminDashboard::class, 'index'])->name('admin.dashboard');
    Route::get('/handylingoadmin/logout', [AdminDashboard::class, 'logout'])->name('admin.logout');
    //Manage Users Route
    Route::get('/handylingoadmin/manage-users', [UsersController::class, 'index'])->name('admin.manage.users');
});
