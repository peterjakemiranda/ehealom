<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

class RolesAndPermissionsSeeder extends Seeder
{
    protected $permissions = [
        // User Management
        'manage users',
        'view users',
        
        // Role Management
        'manage roles',
        'view roles',
        
        // Appointment Permissions
        'view appointments',
        'manage appointments',
        'cancel appointments',
        
        // Resource Permissions
        'view resources',
        'manage resources',
        
        // Settings
        'manage settings',
        'view settings',
    ];

    protected $rolePermissions = [
        'admin' => [
            '*' // Wildcard for all permissions
        ],
        'student' => [
            'view appointments',
            'view resources',
        ],
        'counselor' => [
            'view appointments',
            'manage appointments',
            'cancel appointments',
            'view resources',
            'manage resources',
        ],
        'personnel' => [
            'view appointments',
            'view resources',
        ]
    ];

    public function run()
    {
        // Reset cached roles and permissions
        app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();

        // Create or update permissions
        foreach ($this->permissions as $permission) {
            Permission::findOrCreate($permission);
        }

        // Create or update roles and assign permissions
        foreach ($this->rolePermissions as $roleName => $permissions) {
            $role = Role::findOrCreate($roleName);
            
            // Handle wildcard permission for admin
            if (in_array('*', $permissions)) {
                $role->syncPermissions(Permission::all());
            } else {
                $role->syncPermissions($permissions);
            }
        }

        // Update DatabaseSeeder to only use this seeder
        $this->command->info('Roles and Permissions seeded successfully!');
    }
} 