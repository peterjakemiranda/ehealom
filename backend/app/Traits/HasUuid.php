<?php

namespace App\Traits;

use Illuminate\Support\Str;
use Illuminate\Database\Eloquent\Model;

trait HasUuid
{
    protected static function bootHasUuid()
    {
        static::creating(function (Model $model) {
            if (!$model->uuid) {
                $model->uuid = (string) Str::uuid();
            }
        });
    }

    public function scopeByUuid($query, $uuid)
    {
        return $query->where('uuid', $uuid);
    }

    public function getRouteKeyName()
    {
        return 'uuid';
    }
}