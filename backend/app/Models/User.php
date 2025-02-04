<?php

namespace App\Models;

use App\Traits\HasUuid;
// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, HasRoles, HasUuid;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'uuid',
        'name',
        'email',
        'password',
        'status',
        'student_id',
        'department',
        'course',
        'year_level',
        'phone',
        'is_active'
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
        'status' => 'boolean'
    ];

    /**
     * Scope to filter users by role name
     */
    public function scopeRole($query, $roleName)
    {
        return $query->whereHas('roles', function ($q) use ($roleName) {
            $q->where('name', $roleName);
        });
    }

    public function companies()
    {
        return $this->belongsToMany(Company::class, 'company_user')
                    ->withPivot('is_default')
                    ->withTimestamps();
    }

    public function defaultCompany()
    {
        return $this->companies()->wherePivot('is_default', true)->first();
    }

    // Add helper methods for role checks
    public function isStudent()
    {
        return $this->hasRole('student');
    }

    public function isCounselor()
    {
        return $this->hasRole('counselor');
    }

    public function isPersonnel()
    {
        return $this->hasRole('personnel');
    }
}
