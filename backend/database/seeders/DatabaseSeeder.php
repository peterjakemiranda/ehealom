<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Create default admin user if it doesn't exist
        $admin = User::firstOrCreate(
            ['email' => 'admin@user.com'],
            [
                'name' => 'Admin',
                'password' => Hash::make('123456'),
                'email_verified_at' => now(),
            ]
        );

        // Run the consolidated roles and permissions seeder
        $this->call([
            RolesAndPermissionsSeeder::class,
            CategorySeeder::class,
            SettingsTableSeeder::class,
        ]);

        // Ensure admin has admin role
        $admin->syncRoles(['admin']);
    }
}
