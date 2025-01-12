<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Traits\HasUuid;

class Company extends Model
{
    use HasFactory, HasUuid;

    protected $fillable = [
        'uuid',
        'name',
        'address',
        'email',
        'phone',
        'logo',
        'status'
    ];

    protected $casts = [
        'status' => 'boolean'
    ];

    public function users()
    {
        return $this->belongsToMany(User::class, 'company_user')
                    ->withPivot('is_default')
                    ->withTimestamps();
    }

    public function settings()
    {
        return $this->hasMany(Setting::class);
    }
}
