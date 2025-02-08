<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CounselorSchedule extends Model
{
    protected $fillable = [
        'user_id',
        'day',
        'start_time',
        'end_time',
        'break_start',
        'break_end',
        'is_available'
    ];

    public function counselor()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
} 