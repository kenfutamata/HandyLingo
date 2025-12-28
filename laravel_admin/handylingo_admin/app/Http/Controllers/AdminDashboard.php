<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AdminDashboard extends Controller
{
    public function index(){
        $user = Auth::guard('admin')->user();
        return view('admin.admin_dashboard', compact('user')); 
    }

    public function logout(Request $request){
    Auth::guard('admin')->logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect()->route('admin.login');
    }
}
