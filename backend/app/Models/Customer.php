<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Traits\HasUuid;

class Customer extends Model
{
    use HasFactory, HasUuid;

    protected $guarded = [];

    public function loans()
    {
        return $this->hasMany(Loan::class);
    }

    public function getNameAttribute()
    {
        return $this->first_name . ' ' . $this->last_name;
    }
}
