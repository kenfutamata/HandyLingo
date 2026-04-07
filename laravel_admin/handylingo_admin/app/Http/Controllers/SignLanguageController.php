<?php

namespace App\Http\Controllers;

use App\Models\SignLanguageLog;
use Illuminate\Http\Request;

class SignLanguageController extends Controller
{
    public function store(Request $request)
    {
        $validatedData = $request->validate([
            'user_id' => 'required|integer',
            'sign_language_id' => 'required|integer',
            'accuracy' => 'required|numeric',
        ]);

        $log = SignLanguageLog::create($validatedData);

        return response()->json(['message' => 'Sign language log created successfully', 'data' => $log], 201);
    }
}
