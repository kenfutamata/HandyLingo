<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Notifications\Notifiable;

class Feedbacks extends Model
{
    use HasFactory, HasUuids, Notifiable; 
    protected $table = 'feedbacks';
    public $incrementing = false;

    
    protected $fillable = [
        'user_id',
        'first_name',
        'last_name',
        'email',
        'message',
        'feedback_type',
        'rating',
        'status',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
