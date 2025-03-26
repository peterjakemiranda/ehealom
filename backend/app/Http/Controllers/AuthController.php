<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use Spatie\Permission\Models\Role;
use App\Http\Resources\UserResource;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        try {
            $validated = $request->validate([
                'name' => 'required|string|max:255',
                'email' => 'required|string|email|max:255|unique:users',
                'password' => 'required|string|min:8',
                'password_confirmation' => 'required|same:password',
                'user_type' => 'required|string|in:student,personnel',
                
                // Common fields
                'age' => 'required|integer|min:0',
                'sex' => 'required|string|in:male,female,other',
                'marital_status' => 'required|string',
                
                // Conditional validation
                'student_id' => 'required_if:user_type,student|nullable|string',
                'year_level' => 'required_if:user_type,student|nullable|string',
                'department' => 'required_if:user_type,student,personnel|nullable|string',
                'course' => 'required_if:user_type,student|nullable|string',
                'major' => 'nullable|string',
                'academic_rank' => 'required_if:user_type,personnel|nullable|string',
            ]);

            $user = User::create([
                'name' => $validated['name'],
                'username' => $validated['username'],
                'email' => $validated['email'],
                'password' => Hash::make($validated['password']),
                'age' => $validated['age'],
                'sex' => $validated['sex'],
                'marital_status' => $validated['marital_status'],
                'student_id' => $validated['student_id'] ?? null,
                'year_level' => $validated['year_level'] ?? null,
                'department' => $validated['department'] ?? null,
                'course' => $validated['course'] ?? null,
                'major' => $validated['major'] ?? null,
                'academic_rank' => $validated['academic_rank'] ?? null,
            ]);

            // Assign role based on user type
            $role = Role::where('name', $validated['user_type'])->first();
            if ($role) {
                $user->assignRole($role);
            }

            $token = $user->createToken('authToken')->plainTextToken;

            return response()->json([
                'user' => $user,
                'token' => $token,
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            \Log::error('Registration error: ' . $e->getMessage());
            return response()->json([
                'message' => 'Registration failed',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if (!Auth::attempt($request->only('email', 'password'))) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        $user = $request->user();
        $user->tokens()->delete(); // Optional: Delete existing tokens
        $token = $user->createToken('authToken')->plainTextToken;

        return response()->json([
            'user' => $user,
            'permissions' => $user->getAllPermissions()->pluck('name'),
            'roles' => $user->getRoleNames(),
            'token' => $token,
        ]);
    }

    public function me()
    {
        $user = auth()->user();
        return response()->json([
            'user' => $user,
            'permissions' => $user->getAllPermissions()->pluck('name'),
            'roles' => $user->getRoleNames()
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Logged out']);
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();
        
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email,' . $user->id,
            'username' => 'required|string|max:255|unique:users,username,' . $user->id,
            'current_password' => 'required_with:new_password',
            'new_password' => 'nullable|min:8',
            
            // Common fields
            'age' => 'nullable|integer|min:0',
            'sex' => 'nullable|string|in:male,female,other',
            'marital_status' => 'nullable|string',
            'department' => 'nullable|string',
            
            // Role-specific fields
            'student_id' => 'nullable|string',
            'year_level' => 'nullable|string',
            'course' => 'nullable|string',
            'major' => 'nullable|string',
            'academic_rank' => 'nullable|string',
        ]);

        if ($request->has('current_password')) {
            if (!Hash::check($request->current_password, $user->password)) {
                throw ValidationException::withMessages([
                    'current_password' => ['The provided password is incorrect.']
                ]);
            }
            
            $user->password = Hash::make($request->new_password);
        }

        // Update common fields
        $user->name = $validated['name'];
        $user->email = $validated['email'];
        $user->username = $validated['username'];
        $user->age = $validated['age'] ?? $user->age;
        $user->sex = $validated['sex'] ?? $user->sex;
        $user->marital_status = $validated['marital_status'] ?? $user->marital_status;
        $user->department = $validated['department'] ?? $user->department;

        // Update role-specific fields
        if ($user->hasRole('student')) {
            $user->student_id = $validated['student_id'] ?? $user->student_id;
            $user->year_level = $validated['year_level'] ?? $user->year_level;
            $user->course = $validated['course'] ?? $user->course;
            $user->major = $validated['major'] ?? $user->major;
        }

        if ($user->hasRole('personnel')) {
            $user->academic_rank = $validated['academic_rank'] ?? $user->academic_rank;
        }

        $user->save();

        return response()->json([
            'user' => $user,
            'permissions' => $user->getAllPermissions()->pluck('name'),
            'roles' => $user->getRoleNames(),
        ]);
    }
}
