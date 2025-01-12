<?php

namespace Database\Seeders;

use Spatie\Permission\Models\Permission;
use Illuminate\Database\Seeder;

class PermissionSeeder extends Seeder
{
    public function run()
    {
        $permissions = [
            'users' => [
                'manage users',
                'view users'
            ],
            'categories' => [
                'manage categories',
                'view categories'
            ],
            'customers' => [
                'create customers',
                'edit customers',
                'view customers'
            ],
        ];

        foreach ($permissions as $group => $groupPermissions) {
            foreach ($groupPermissions as $permission) {
                Permission::create(['name' => $permission]);
            }
        }
    }
}