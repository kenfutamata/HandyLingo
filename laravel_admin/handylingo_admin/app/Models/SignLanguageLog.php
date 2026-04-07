<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class SignLanguageLog extends Model
{
    use HasUuids; 

    protected $fillable = [
        'user_id',
        'sign_language_id',
        'accuracy',
    ];
}
