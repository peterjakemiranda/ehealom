<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;
use Illuminate\Http\Request;
use App\Http\Resources\RoleResource;
use Illuminate\Validation\Rule;
use App\Models\User;
use App\Http\Resources\UserResource;

class RoleController extends Controller
{
    public function __construct()
    {
        // $this->middleware(['permission:manage users']);
    }

    public function index()
    {
        $roles = Role::with('permissions')->get();
        return RoleResource::collection($roles);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'unique:roles,name'],
            'permissions' => ['required', 'array'],
            'permissions.*' => ['exists:permissions,name']
        ]);

        $role = Role::create(['name' => $validated['name']]);
        $role->syncPermissions($validated['permissions']);

        return new RoleResource($role->load('permissions'));
    }

    public function show(Role $role)
    {
        return new RoleResource($role->load(['permissions', 'users']));
    }

    public function update(Request $request, Role $role)
    {

        $validated = $request->validate([
            'name' => ['required', 'string', Rule::unique('roles')->ignore($role->id)],
            'permissions' => ['required', 'array'],
            'permissions.*' => ['exists:permissions,name']
        ]);

        $role->update(['name' => $validated['name']]);
        $role->syncPermissions($validated['permissions']);

        return new RoleResource($role->load('permissions'));
    }

    public function destroy(Role $role)
    {
        // Prevent deletion of core roles
        if (in_array($role->name, ['admin', 'manager', 'bookkeeper', 'teller'])) {
            return response()->json([
                'message' => 'Cannot delete core system roles'
            ], 403);
        }

        $role->delete();
        return response()->json(null, 204);
    }

    public function permissions()
    {
        $permissions = Permission::all();
        return response()->json($permissions);
    }

    public function assignRole(Request $request)
    {
        $validated = $request->validate([
            'user_uuid' => ['required', 'exists:users,uuid'],  // Changed from user_id
            'roles' => ['required', 'array'],
            'roles.*' => ['exists:roles,name']
        ]);

        $user = User::where('uuid', $validated['user_uuid'])->firstOrFail();
        $user->syncRoles($validated['roles']);

        return new UserResource($user->load('roles'));
    }
}