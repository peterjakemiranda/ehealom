<?php
namespace App\Services;

use App\Models\Setting;
use Illuminate\Support\Facades\Cache;

class SettingsService
{
    public static function get($key, $default = null)
    {
        return Setting::where('key', $key)->first()?->value ?? $default;
    }

    public static function set($key, $value, $type = 'string', $description = null)
    {
        $setting = Setting::updateOrCreate(
            ['key' => $key],
            [
                'value' => $type === 'json' ? json_encode($value) : $value,
                'type' => $type,
                'description' => $description
            ]
        );

        // Clear cache
        Cache::forget("setting_{$key}");

        return $setting;
    }

    public static function getAllSettings()
    {
        return [
            'terms_and_conditions' => self::get('terms_and_conditions', 'Default Terms and Conditions'),
        ];
    }
}