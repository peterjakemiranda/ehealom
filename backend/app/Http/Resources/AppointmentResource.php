<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AppointmentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'uuid' => $this->uuid,
            'student_id' => $this->student_id,
            'counselor_id' => $this->counselor_id,
            'appointment_date' => $this->appointment_date->toIso8601String(),
            'status' => $this->status,
            'reason' => $this->reason,
            'notes' => $this->notes,
            'student' => new UserResource($this->whenLoaded('student')),
            'counselor' => new UserResource($this->whenLoaded('counselor')),
            'location_type' => $this->location_type,
            'location' => $this->location,
            'user_type' => $this->student?->roles?->contains('name', 'student') ? 'student' : 'personnel',
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at
        ];
    }
} 