<?php

namespace Database\Seeders;

use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Illuminate\Database\Seeder;

class RolePermissionSeeder extends Seeder
{
    public function run()
    {
        $rolePermissions = [
            'admin' => Permission::all()->pluck('name')->toArray(),
            'user' => [
                'view categories',
                'view customers'
            ],
        ];

        foreach ($rolePermissions as $roleName => $permissions) {
            $role = Role::findByName($roleName);
            $role->syncPermissions($permissions);
        }
    }
}