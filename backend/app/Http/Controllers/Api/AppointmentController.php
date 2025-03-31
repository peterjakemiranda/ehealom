<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use Illuminate\Http\Request;
use App\Http\Resources\AppointmentResource;
use Carbon\Carbon;
use Illuminate\Support\Str;
use App\Services\AppointmentScheduleService;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;

class AppointmentController extends Controller
{
    protected $scheduleService;

    public function __construct(AppointmentScheduleService $scheduleService)
    {
        $this->scheduleService = $scheduleService;
    }

    // Time slot interval in minutes (can be moved to settings later)
    const TIME_SLOT_INTERVAL = 30;

    public function index(Request $request)
    {
        $query = Appointment::query()
            ->with(['student', 'counselor']);

        // Filter by user role first
        if ($request->user()->hasRole('student') || $request->user()->hasRole('personnel')) {
            $query->where('student_id', $request->user()->id);
        } elseif ($request->user()->hasRole('counselor')) {
            $query->where('counselor_id', $request->user()->id);
            
            if ($request->has('user_type') && $request->user_type !== 'all') {
                $role = $request->user_type === 'student' ? 'student' : 'personnel';
                Log::info('Role: ' . $role);
                $query->whereHas('student.roles', function($q) use ($role) {
                    $q->where('name', $role);
                });
            }

            // Add search by name functionality
            if ($request->has('search') && !empty($request->search)) {
                $search = $request->search;
                $query->whereHas('student', function($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%");
                });
            }
        }

        // Then apply status/date filters
        $now = now();
        switch ($request->get('status')) {
            case 'upcoming':
                $query->where('status', 'confirmed')
                    ->whereDate('appointment_date', '>=', $now);
                break;
            case 'pending':
                $query->where('status', 'pending');
                break;
            case 'history':
                $query->where(function($q) use ($now) {
                    $q->where('status', 'completed')
                        ->orWhere('status', 'cancelled')
                        ->orWhere(function($q) use ($now) {
                            $q->whereDate('appointment_date', '<', $now)
                                ->where(function($q) {
                                    $q->where('status', 'confirmed')
                                        ->orWhere('status', 'pending');
                                });
                        });
                });
                break;
        }

        // Custom sorting for appointments
        $query->orderByRaw('
            CASE 
                WHEN appointment_date >= ? THEN 0 
                ELSE 1 
            END,
            appointment_date ASC
        ', [$now]);

        $appointments = $query->paginate($request->input('per_page', 10));

        return AppointmentResource::collection($appointments);
    }

    public function availableSlots(Request $request)
    {
        $validated = $request->validate([
            'counselor_id' => 'required|exists:users,id',
            'date' => [
                'required',
                'date',
                'date_format:Y-m-d',
                function ($attribute, $value, $fail) {
                    $selectedDate = \Carbon\Carbon::parse($value)->startOfDay();
                    $today = now()->startOfDay();
                    
                    if ($selectedDate->lt($today)) {
                        $fail('The selected date must not be in the past.');
                    }
                },
            ],
        ]);

        $slots = $this->scheduleService->getAvailableSlots(
            $validated['counselor_id'],
            $validated['date']
        );

        return response()->json([
            'slots' => $slots
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'appointment_date' => 'required|date|after:now',
            'reason' => 'required|string',
            'location_type' => 'required|in:online,on-site',
            'category_id' => 'required|exists:categories,id',
            // For new students
            'student_name' => 'required_without:student_id|string',
            'student_id_number' => 'required_without:student_id|string',
            'student_email' => 'required_without:student_id|email',
            // For existing students
            'student_id' => 'required_without_all:student_name,student_id_number,student_email|exists:users,id',
        ]);

        // Get or create student
        if (!$request->has('student_id')) {
            // Create minimal user record for the student
            $student = User::create([
                'name' => $validated['student_name'],
                'email' => $validated['student_email'],
                'student_id' => $validated['student_id_number'],
                'password' => Hash::make(Str::random(12)), // Random password
                'status' => true,
            ]);
            $student->assignRole('student');
            $student_id = $student->id;
        } else {
            $student_id = $validated['student_id'];
        }

        // Determine counselor_id based on user role
        $counselor_id = null;
        if ($request->user()->hasRole('counselor')) {
            $counselor_id = $request->user()->id;
        } else {
            // Find the first available counselor
            $counselor = User::role('counselor')
                ->where('status', true)
                ->first();

            if (!$counselor) {
                return response()->json([
                    'message' => 'No counselors available at the moment'
                ], 422);
            }

            $counselor_id = $counselor->id;
        }

        $appointment = Appointment::create([
            'student_id' => $student_id,
            'counselor_id' => $counselor_id,
            'appointment_date' => $validated['appointment_date'],
            'reason' => $validated['reason'],
            'location_type' => $validated['location_type'],
            'status' => $request->user()->hasRole('counselor') ? 'confirmed' : 'pending',
            'category_id' => $validated['category_id'],
        ]);

        return new AppointmentResource($appointment);
    }

    /**
     * Update the specified appointment.
     */
    public function update(Request $request, Appointment $appointment)
    {
        // Log the appointment for debugging
        \Log::info('Updating appointment:', [
            'uuid' => $appointment->uuid,
            'data' => $request->all()
        ]);

        // Validate user can update this appointment
        if ($request->user()->hasRole('student') && $appointment->student_id !== $request->user()->id) {
            abort(403, 'Unauthorized to update this appointment');
        }
        if ($request->user()->hasRole('counselor') && $appointment->counselor_id !== $request->user()->id) {
            abort(403, 'Unauthorized to update this appointment');
        }

        $validated = $request->validate([
            'status' => ['sometimes', 'required', 'in:pending,confirmed,cancelled,completed'],
            'notes' => ['sometimes', 'nullable', 'string'],
        ]);

        $appointment->update($validated);

        return new AppointmentResource($appointment->fresh());
    }

    /**
     * Display the specified appointment.
     */
    public function show(Appointment $appointment)
    {
        // Check if user has permission to view this appointment
        $user = request()->user();
        if ($user->hasRole('student') && $appointment->student_id !== $user->id) {
            abort(403, 'Unauthorized access to appointment');
        }
        if ($user->hasRole('counselor') && $appointment->counselor_id !== $user->id) {
            abort(403, 'Unauthorized access to appointment');
        }

        return new AppointmentResource($appointment->load(['student', 'counselor']));
    }

    public function getCounts(Request $request)
    {
        $query = Appointment::query();
        $user = $request->user();

        // Filter by user role
        if ($user->hasRole('student') || $user->hasRole('personnel')) {
            $query->where('student_id', $user->id);
        } elseif ($user->hasRole('counselor')) {
            $query->where('counselor_id', $user->id);
            
            // Apply user type filter for counselors
            if ($request->has('user_type') && $request->user_type !== 'all') {
                $role = $request->user_type === 'student' ? 'student' : 'personnel';
                $query->whereHas('student.roles', function($q) use ($role) {
                    $q->where('name', $role);
                });
            }

            // Apply search filter for counselors
            if ($request->has('search') && !empty($request->search)) {
                $search = $request->search;
                $query->whereHas('student', function($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%");
                });
            }
        }

        $now = now();
        
        $counts = [
            'upcoming' => (clone $query)
                ->where('status', 'confirmed')
                ->whereDate('appointment_date', '>=', $now)
                ->count(),
            'pending' => (clone $query)
                ->where('status', 'pending')
                ->count(),
            'history' => (clone $query)
                ->where(function($q) use ($now) {
                    $q->where('status', 'completed')
                        ->orWhere('status', 'cancelled')
                        ->orWhere(function($q) use ($now) {
                            $q->whereDate('appointment_date', '<', $now)
                                ->where(function($q) {
                                    $q->where('status', 'confirmed')
                                        ->orWhere('status', 'pending');
                                });
                        });
                })
                ->count(),
        ];

        return response()->json($counts);
    }


    public function getAvailableSlots(Request $request)
    {
        $request->validate([
            'counselor_id' => 'required|exists:users,id',
            'date' => 'required|date|after_or_equal:today',
        ]);

        $counselor = User::findOrFail($request->counselor_id);
        if (!$counselor->hasRole('counselor')) {
            return response()->json([
                'message' => 'Selected user is not a counselor'
            ], 422);
        }

        // Use the schedule service to get available slots
        $result = $this->scheduleService->getAvailableSlots(
            $request->counselor_id,
            $request->date
        );

        return response()->json($result);
    }

    public function getDepartments()
    {
        // Add debug logging
        Log::info('Fetching departments');
        
        $departments = User::whereHas('roles', function($q) {
                $q->where('name', 'student');
            })
            ->whereNotNull('department')
            ->distinct()
            ->pluck('department')
            ->values();
        
        // Log the results
        Log::info('Found departments:', ['departments' => $departments]);

        return response()->json($departments);
    }

    /**
     * Remove the specified appointment.
     */
    public function destroy(Appointment $appointment)
    {
        // Check if user has permission to delete this appointment
        $user = request()->user();
        
        // Only admin can delete appointments
        if (!$user->hasRole('counselor')) {
            abort(403, 'Unauthorized to delete appointments');
        }

        // Delete the appointment
        $appointment->delete();

        return response()->json([
            'message' => 'Appointment deleted successfully'
        ]);
    }
} 