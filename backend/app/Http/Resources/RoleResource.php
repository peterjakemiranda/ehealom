<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RoleResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'uuid' => $this->uuid,
            'name' => $this->name,
            'permissions' => $this->permissions->pluck('name'),
            'users_count' => $this->users_count,
            'is_core_role' => in_array($this->name, ['admin', 'manager', 'bookkeeper', 'teller']),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}