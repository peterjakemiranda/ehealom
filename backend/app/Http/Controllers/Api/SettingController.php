<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use App\Models\Company;
use Illuminate\Http\Request;
use App\Services\SettingsService;

class SettingController extends Controller
{
    public function index(Request $request)
    {
        return response()->json(SettingsService::getAllSettings());
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'site_name' => 'required|string|max:255',
            'site_logo' => 'nullable|string',
            'business_name' => 'required|string|max:255',
            'business_address' => 'required|string',
        ]);
        foreach ($validated as $key => $value) {
            SettingsService::set($key, $value);
        }

        return response()->json([
            'message' => 'Settings updated successfully',
            'settings' => SettingsService::getAllSettings()
        ]);
    }
}
