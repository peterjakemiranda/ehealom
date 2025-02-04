<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Support\Facades\Storage;

class Emergency extends Model
{
    use HasFactory;

    protected $fillable = [
        'reported_by',
        'type',
        'description',
        'departments',
        'location',
        'latitude',
        'longitude',
        'image_path',
        'status',
    ];

    protected $casts = [
        'departments' => 'array',
        'resolved_at' => 'datetime'
    ];

    public function reporter()
    {
        return $this->belongsTo(User::class, 'reported_by');
    }

    public function getImageUrlAttribute()
    {
        return $this->image_path ? Storage::url($this->image_path) : null;
    }
}
