<?php

namespace App\Http\Controllers;

use Exception;
use Illuminate\Support\Facades\Auth;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;


class AdminLoginController extends Controller
{
    protected $auth;
    protected $firestore;


    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $credentials = $request->only('email', 'password');

        $adminCredentials = array_merge($credentials, ['role' => 'admin', 'status' => 'active']);
        if (Auth::guard('admin')->attempt($adminCredentials)) {
            $request->session()->regenerate();
            return redirect()->route('admin.dashboard');
        }
        return back()->with('error', 'Invalid credentials or not an admin user.');
    }

    public function showLoginForm()
    {
        return view('admin.admin_login');
    }
}
