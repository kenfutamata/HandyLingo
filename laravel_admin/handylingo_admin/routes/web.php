<?php

use App\Http\Controllers\AdminDashboard;
use App\Http\Controllers\AdminGenerateReportsController;
use App\Http\Controllers\AdminLoginController;
use App\Http\Controllers\FeedbacksController;
use App\Http\Controllers\LandingPageController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\UsersController;
use App\Http\Middleware\FirebaseMiddleware;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;


//Landing Page Route
Route::get('/', [LandingPageController::class, 'index'])->name('admin.landingpage');
//Contact us route
Route::post('/submit-feedback', [LandingPageController::class, 'storeFeedback'])->name('submit.feedback');
//Admin Login Route 
Route::get('/login', [AdminLoginController::class, 'viewLogin'])->name('login');
Route::post('/login', [AdminLoginController::class, 'login'])->name('admin.login.submit');

Route::get('/db-test', function () {
    try {
        DB::connection()->getPdo();
        return "Connected successfully to: " . DB::connection()->getDatabaseName();
    } catch (\Exception $e) {
        return "Could not connect to the database. Please check your configuration. error:" . $e->getMessage();
    }
});

Route::middleware('auth:admin')->group(function () {
    //Dasboard and logout routes
    Route::get('/handylingoadmin/dashboard', [AdminDashboard::class, 'index'])->name('admin.dashboard');
    Route::get('/handylingoadmin/logout', [AdminDashboard::class, 'logout'])->name('admin.logout');
    //Manage Users Route
    Route::get('/handylingoadmin/manage-users', [UsersController::class, 'index'])->name('admin.manage.users');
    Route::delete('/handylingoadmin/manage-users/{id}', [UsersController::class, 'destroy'])->name('admin.manage.users.delete');
    Route::get('/handylingoadmin/manage-users/export', [UsersController::class, 'export'])->name('admin.manage.users.export');
    //Manage Feedbacks
    Route::get('/handylingoadmin/manage-feedbacks', [FeedbacksController::class, 'index'])->name('admin.manage.feedbacks');
    Route::delete('/handylingoadmin/manage-feedbacks/{id}', [FeedbacksController::class, 'destroy'])->name('admin.manage.feedbacks.delete');
    Route::put('/handylingoadmin/manage-feedbacks/{id}', [FeedbacksController::class, 'update'])->name('admin.manage.feedbacks.update');
    Route::get('/handylingoadmin/manage-feedbacks/export', [FeedbacksController::class, 'export'])->name('admin.manage.feedbacks.export');
    //Notifications 
    Route::delete('/handylingoadmin/notifications/{id}', [NotificationController::class, 'destroy'])->name('admin.notifications.destroy');
    //Generate Report
    Route::get('/handylingoadmin/generate-reports', [AdminGenerateReportsController::class, 'index'])->name('admin.generate.reports');
});
