<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Traits\HasUuid;

class Category extends Model
{
    use HasFactory, HasUuid;

    protected $guarded = [];

    protected $casts = [
        'penalty_rate' => 'decimal:2'
    ];

    public function items()
    {
        return $this->belongsToMany(Item::class, 'item_categories');
    }
}
