<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AlertResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'content' => $this->content,
            'type' => $this->type,
            'notification_type' => $this->notification_type,
            'department' => $this->department,
            'reported_by' => $this->reporter ? [
                'id' => $this->reporter->id,
                'name' => $this->reporter->name,
            ] : null,
            'is_active' => $this->is_active,
            'sent_at' => $this->sent_at,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
} 