<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Support\Facades\Storage;

class Category extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'title',
        'description',
        'image_url'
    ];

    protected $appends = ['image_path'];

    /**
     * Get the columns that should receive a unique identifier.
     *
     * @return array
     */
    public function uniqueIds(): array
    {
        return ['uuid'];
    }

    public function getImagePathAttribute()
    {
        return $this->image_url ? Storage::disk('public')->url($this->image_url) : null;
    }

    public function resources()
    {
        return $this->belongsToMany(Resource::class, 'resource_categories');
    }

    public function getRouteKeyName()
    {
        return 'uuid';
    }
}
