<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateCategoryRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:255',
            'loan_period_type' => 'required|string|max:255',
            'loan_period' => 'required|integer',
            'loan_period_expiry' => 'required|integer',
            'penalty_rate' => 'required|numeric',
            'interest_rate' => 'required|numeric',
            'is_renewable' => 'nullable|boolean',
        ];
    }
}
