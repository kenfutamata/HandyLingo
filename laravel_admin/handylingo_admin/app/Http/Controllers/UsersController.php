<?php

namespace App\Http\Controllers;

use App\Models\Users;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class UsersController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $user = Auth::guard('admin')->user();
        $search = $request->input('search');
        $query = Users::query()->where('role', 'user');
        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->whereRaw('LOWER(first_name || \' \' || last_name) LIKE ?', [$search])
                    ->orWhere('user_name', 'like', "%{$search}%")
                    ->orWhere('first_name', 'like', "%{$search}%")
                    ->orWhere('last_name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhere('status', 'like', "%{$search}%");
            });
        }
        $users = $query->paginate(10)->withQueryString();

        return view('admin.admin_manage_users', compact('user', 'users'));
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        //
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $user = Users::findOrFail($id);

        $supabaseUrl = env('SUPABASE_URL');
        $supabaseServiceKey = env('SUPABASE_SERVICE_ROLE_KEY');

        try {
            $url = rtrim($supabaseUrl, '/') . '/auth/v1/admin/users/' . $user->id;

            $response = Http::withHeaders([
                'apikey' => $supabaseServiceKey,
                'Authorization' => 'Bearer ' . $supabaseServiceKey,
            ])->delete($url);

            if ($response->successful() || $response->status() == 404) {
                $user->delete();
                return redirect()->route('admin.manage.users')->with('Success', 'User deleted successfully.');
            }

            // If we reach here, it failed. Log everything.
            Log::error('Supabase Delete Failed', [
                'status' => $response->status(),
                'url'    => $url,
                'error'  => $response->json() ?? $response->body(),
            ]);
        } catch (\Exception $e) {
            Log::error('Supabase Connection Error', [
                'message' => $e->getMessage()
            ]);
        }

        return redirect()->route('admin.manage.users')->with('error', 'Failed to delete user. Check logs.');
    }
}
