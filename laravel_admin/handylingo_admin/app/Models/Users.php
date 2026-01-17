<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Container\Attributes\Auth;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Notifications\Notifiable;

class Users extends Authenticatable
{
    use Notifiable; 
    protected $keyType = 'string';
    public $incrementing = false;
    protected $table = 'users';

    protected $fillable = [
        'user_name',
        'first_name',
        'last_name',
        'email',
        'password',
    ];
}
