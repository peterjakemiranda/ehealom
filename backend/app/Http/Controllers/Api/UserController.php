<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Http\Resources\UserResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;
use Spatie\Permission\Models\Role;
use Illuminate\Validation\Rule;
use Spatie\QueryBuilder\QueryBuilder;
use Spatie\QueryBuilder\AllowedFilter;

class UserController extends Controller
{
    public function __construct()
    {
        // $this->middleware(['permission:manage users|view users']);
    }

    public function index(Request $request)
    {
        $query = User::with('roles');

        // Handle search
        if ($request->has('search')) {
            $searchTerm = $request->input('search');
            $query->where(function($q) use ($searchTerm) {
                $q->where('name', 'like', "%{$searchTerm}%")
                  ->orWhere('email', 'like', "%{$searchTerm}%");
            });
        }

        // Handle user type filter
        if ($request->has('user_type')) {
            $userType = $request->input('user_type');
            
            $query->whereHas('roles', function($q) use ($userType) {
                $q->where('name', $userType);
            });
        }

        // Handle status filter
        if ($request->has('status')) {
            $query->where('status', $request->input('status'));
        }

        // Sort by created date descending by default
        $query->orderBy('created_at', 'desc');

        $users = $query->paginate($request->input('per_page', 10));
        
        return UserResource::collection($users);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users'],
            'password' => ['required', Password::defaults()],
            'roles' => ['required', 'array'],
            'roles.*' => ['exists:roles,name'],
            'status' => ['sometimes', 'boolean']
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'status' => $validated['status'] ?? true
        ]);

        $user->assignRole($validated['roles']);

        return new UserResource($user->load('roles'));
    }

    public function update(Request $request, User $user)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', Rule::unique('users')->ignore($user->id)],
            'password' => ['sometimes', Password::defaults()],
            'roles' => ['sometimes', 'array'],
            'roles.*' => ['exists:roles,name'],
            'status' => ['sometimes', 'boolean']
        ]);

        $userData = [
            'name' => $validated['name'],
            'email' => $validated['email'],
            'status' => $validated['status'] ?? $user->status
        ];

        if (isset($validated['password'])) {
            $userData['password'] = Hash::make($validated['password']);
        }

        $user->update($userData);
        $user->syncRoles($validated['roles']);

        return new UserResource($user->load('roles'));
    }

    public function destroy(User $user)
    {
        // Prevent self-deletion
        if ($user->id === auth()->id()) {
            return response()->json(['message' => 'Cannot delete your own account'], 403);
        }

        $user->delete();
        return response()->json(null, 204);
    }

    public function toggleStatus(User $user)
    {
        // Prevent toggling own status
        if ($user->id === auth()->id()) {
            return response()->json(['message' => 'Cannot toggle your own status'], 403);
        }

        $user->update(['status' => !$user->status]);
        return new UserResource($user->load('roles'));
    }
}