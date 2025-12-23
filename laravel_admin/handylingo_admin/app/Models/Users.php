<?php

namespace App\Models;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Container\Attributes\Auth;
use Illuminate\Database\Eloquent\Model;

class Users extends Authenticatable
{
    protected $table = 'users'; 

    protected $fillable = [
        'user_name',
        'first_name',
        'last_name',
        'email',
        'password',
    ];
}
