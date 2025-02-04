<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class FirstAid extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'content',
        'icon',
        'priority_order',
        'is_active'
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'priority_order' => 'integer'
    ];
} 