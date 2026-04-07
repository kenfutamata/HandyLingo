<?php

use App\Http\Controllers\SignLanguageController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::post('/save-log', [SignLanguageController::class, 'store']); 

