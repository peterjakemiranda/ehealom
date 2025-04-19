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

    public function termsAndConditions()
    {
        $terms = SettingsService::get('terms_and_conditions');
        return response()->json([
            'terms_and_conditions' => $terms
        ]);
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'terms_and_conditions' => 'required|string',
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
