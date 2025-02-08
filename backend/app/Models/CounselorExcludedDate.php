<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CounselorExcludedDate extends Model
{
    protected $fillable = [
        'user_id',
        'excluded_date',
        'reason'
    ];

    protected $casts = [
        'excluded_date' => 'date'
    ];

    public function counselor()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
} 