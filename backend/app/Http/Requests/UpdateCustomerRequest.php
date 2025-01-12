<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateCustomerRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'first_name' => 'sometimes|required|string|max:255',
            'last_name' => 'sometimes|required|string|max:255',
            'phone_number' => 'sometimes|required|string|max:20',
            'email' => 'nullable|email|max:255',
            'address' => 'sometimes|required|string|max:500',
            'remarks' => 'nullable|string',
            'id_type' => 'nullable|string|max:255',
            'id_number' => 'nullable|string|max:255',
        ];
    }
}
