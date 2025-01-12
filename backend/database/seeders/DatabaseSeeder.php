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

            User::updateOrCreate(['email' => 'admin@example.com'], [
                'name' => 'Admin',
                'email' => 'admin@example.com',
                'password' => Hash::make('123456'),
            ]);

            $this->call([
                RoleSeeder::class,
                PermissionSeeder::class,
                RolePermissionSeeder::class,
            ]);
    }
}
