<?php

use App\Http\Controllers\Api\LogController;
use App\Http\Controllers\SignLanguageController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::post('/save-log', [LogController::class, 'store']); 


Route::get('/test', function () {
    return response()->json(['message' => 'API is working!']);
});

// routes/api.php
Route::get('/test-route', function () {
    return response()->json(['status' => 'API is working!']);
});