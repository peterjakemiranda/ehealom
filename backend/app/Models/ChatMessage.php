<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class ChatMessage extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'user_id',
        'message',
    ];

    protected $casts = [
        'created_at' => 'datetime',
        'updated_at' => 'datetime'
    ];

    protected $with = ['user:id,name,username'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
} 