<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SignLanguageLog;
use Illuminate\Http\Request;

class LogController extends Controller
{
    public function store(Request $request)
    {
        // 1. Validate the incoming data
        $validated = $request->validate([
            'user_id' => 'required|exists:users,id',
            'translated_output' => 'required|string',
            'accuracy' => 'required|numeric',
        ]);

        // 2. Create the record in the database
        $log = SignLanguageLog::create([
            'user_id' => $validated['user_id'],
            'translated_output' => $validated['translated_output'],
            'accuracy' => $validated['accuracy'],
        ]);

        // 3. Return a JSON response
        return response()->json([
            'message' => 'Log saved successfully',
            'log' => $log
        ], 201);
    }
}