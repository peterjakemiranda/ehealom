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
    
    //show
    public function show(User $user)
    {
        return new UserResource($user->load('roles'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users'],
            'password' => ['required', Password::defaults()],
            'roles' => ['required', 'array'],
            'roles.*' => ['exists:roles,name'],
            'status' => ['sometimes', 'boolean'],
            
            // Common fields
            'age' => ['sometimes', 'integer', 'min:0'],
            'sex' => ['sometimes', 'string', 'in:male,female,other'],
            'marital_status' => ['sometimes', 'string'],
            
            // Conditional validation based on role
            'student_id' => ['required_if:roles.0,student', 'string', 'nullable'],
            'year_level' => ['required_if:roles.0,student', 'string', 'nullable'],
            'department' => ['required_if:roles.0,student,personnel', 'string', 'nullable'],
            'course' => ['required_if:roles.0,student', 'string', 'nullable'],
            'major' => ['sometimes', 'string', 'nullable'],
            'academic_rank' => ['required_if:roles.0,personnel', 'string', 'nullable'],
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'status' => $validated['status'] ?? true,
            'age' => $validated['age'] ?? null,
            'sex' => $validated['sex'] ?? null,
            'marital_status' => $validated['marital_status'] ?? null,
            'student_id' => $validated['student_id'] ?? null,
            'year_level' => $validated['year_level'] ?? null,
            'department' => $validated['department'] ?? null,
            'course' => $validated['course'] ?? null,
            'major' => $validated['major'] ?? null,
            'academic_rank' => $validated['academic_rank'] ?? null,
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
            'status' => ['sometimes', 'boolean'],
            
            // Common fields
            'age' => ['sometimes', 'integer', 'min:0'],
            'sex' => ['sometimes', 'string', 'in:male,female,other'],
            'marital_status' => ['sometimes', 'string'],
            
            // Role specific fields
            'student_id' => ['sometimes', 'string', 'nullable'],
            'year_level' => ['sometimes', 'string', 'nullable'],
            'department' => ['sometimes', 'string', 'nullable'],
            'course' => ['sometimes', 'string', 'nullable'],
            'major' => ['sometimes', 'string', 'nullable'],
            'academic_rank' => ['sometimes', 'string', 'nullable'],
        ]);

        $userData = array_merge(
            $validated,
            isset($validated['password']) ? ['password' => Hash::make($validated['password'])] : []
        );

        unset($userData['roles']);
        $user->update($userData);
        
        if (isset($validated['roles'])) {
            $user->syncRoles($validated['roles']);
        }

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

    public function searchStudents(Request $request)
    {
        $query = $request->get('query');
        
        $students = User::role('student')
            ->where(function($q) use ($query) {
                $q->where('name', 'like', "%{$query}%")
                  ->orWhere('email', 'like', "%{$query}%")
                  ->orWhere('student_id', 'like', "%{$query}%");
            })
            ->select('id', 'name', 'email', 'student_id')
            ->limit(10)
            ->get();

        return response()->json($students);
    }
}