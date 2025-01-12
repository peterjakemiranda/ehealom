<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CategoryResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'uuid' => $this->uuid,
            'name' => $this->name,
            'description' => $this->description,
            'interest_rate' => $this->interest_rate,
            'penalty_rate' => $this->penalty_rate,
            'loan_period' => $this->loan_period,
            'loan_period_type' => $this->loan_period_type,
            'grace_period' => $this->grace_period,
        ];
    }
}
