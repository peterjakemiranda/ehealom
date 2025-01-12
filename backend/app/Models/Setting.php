<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Setting extends Model
{
    use HasFactory;

    protected $fillable = ['company_id', 'key', 'value', 'type', 'description'];

    // Cast method to handle different types
    public function getValueAttribute($value)
    {
        return match($this->attributes['type']) {
            'integer' => (int) $value,
            'float' => (float) $value,
            'boolean' => (bool) $value,
            'json' => json_decode($value, true),
            default => $value
        };
    }

    public function company()
    {
        return $this->belongsTo(Company::class);
    }
}
