<?php
namespace App\Services;

use App\Models\Setting;
use Illuminate\Support\Facades\Cache;

class SettingsService
{
    public static function get($key, $default = null)
    {
        return Cache::remember("setting_{$key}", now()->addHours(24), function () use ($key, $default) {
            return Setting::where('key', $key)->first()?->value ?? $default;
        });
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
            'site_name' => self::get('site_name', config('app.name')),
            'site_logo' => self::get('site_logo'),
            'business_name' => self::get('business_name'),
            'business_address' => self::get('business_address'),
            'pawn_ticket_header' => self::get('pawn_ticket_header', "Chelzy Pawnshop\nMagosilom, Cantilan, Surigao del Sur\nAnane B. Bolontiao, Cantilan, Proprietor\nNON VAT REG.TIN: 319-510-469-000")
        ];
    }
}