<?php

namespace App\Http\Controllers;

use App\Models\Feedbacks;
use App\Models\Users;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AdminDashboard extends Controller
{
    public function index(){
        $user = Auth::guard('admin')->user();
        $feedbackCount = Feedbacks::where('status', 'New')->count();
        $userCount = Users::where('role', 'user')->where('status', 'active')->count(); 
        return view('admin.admin_dashboard', compact('user', 'userCount', 'feedbackCount')); 
    }

    public function logout(Request $request){
    Auth::guard('admin')->logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect()->route('admin.landingpage');
    }
}
