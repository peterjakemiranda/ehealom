<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use App\Models\Company;
use Illuminate\Http\Request;

class SettingController extends Controller
{
    public function index(Request $request)
    {
        $companyId = $request->header('X-Company-Id');
        $settings = Setting::where('company_id', $companyId)->get()
            ->mapWithKeys(function ($setting) {
                return [$setting->key => $setting->value];
            });

        return response()->json($settings);
    }

    public function update(Request $request)
    {
        $companyId = $request->header('X-Company-Id');
        $company = Company::findOrFail($companyId);

        $validated = $request->validate([
            'site_name' => 'required|string|max:255',
            'site_logo' => 'nullable|string',
            'business_name' => 'required|string|max:255',
            'business_address' => 'required|string',
            'pawn_ticket_header' => 'nullable|string'
        ]);

        foreach ($validated as $key => $value) {
            Setting::updateOrCreate(
                [
                    'company_id' => $companyId,
                    'key' => $key
                ],
                [
                    'value' => $value,
                    'type' => 'string'
                ]
            );
        }

        return response()->json([
            'message' => 'Settings updated successfully',
            'settings' => $this->index($request)->original
        ]);
    }
}
