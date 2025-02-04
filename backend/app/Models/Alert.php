<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Alert extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'content',
        'type',
        'notification_type',
        'department',
        'reported_by',
        'is_active',
        'sent_at',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'sent_at' => 'datetime',
    ];

    public function reporter()
    {
        return $this->belongsTo(User::class, 'reported_by');
    }
} 