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

class AppointmentController extends Controller
{
    protected $scheduleService;

    public function __construct(AppointmentScheduleService $scheduleService)
    {
        $this->scheduleService = $scheduleService;
    }

    // Time slot interval in minutes (can be moved to settings later)
    const TIME_SLOT_INTERVAL = 30;
    const START_TIME = '09:00';
    const END_TIME = '17:00';

    public function index(Request $request)
    {
        $query = Appointment::query()
            ->with(['student', 'counselor']);

        // Filter by user role
        if ($request->user()->hasRole('student')) {
            $query->where('student_id', $request->user()->id);
        } elseif ($request->user()->hasRole('counselor')) {
            $query->where('counselor_id', $request->user()->id);
        }

        // Apply status/date filters
        $now = now();
        switch ($request->get('status')) {
            case 'upcoming':
                $query->where('status', 'confirmed')
                    ->whereDate('appointment_date', '>=', $now);
                break;
            case 'pending':
                $query->where('status', 'pending');
                break;
            case 'past':
                $query->where('status', 'completed')
                ->orWhere(function($q) use ($now) {
                    $q->whereDate('appointment_date', '<', $now)
                        ->where('status', 'confirmed');
                });
                break;
            case 'cancelled':
                $query->where('status', 'cancelled');
                break;
        }

        $appointments = $query->orderBy('appointment_date', 'desc')
            ->paginate($request->input('per_page', 10));

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
        \Log::info('Appointment creation attempt', [
            'user' => auth()->user(),
            'roles' => auth()->user()->roles->pluck('name'),
            'data' => $request->all()
        ]);

        $validated = $request->validate([
            'counselor_id' => 'required|exists:users,id',
            'appointment_date' => 'required|date|after:now',
            'reason' => 'required|string',
            'location_type' => 'required|in:online,on-site',
        ]);

        // Check if user is a student
        if (!auth()->user()->hasRole('student')) {
            return response()->json([
                'message' => 'Only students can book appointments'
            ], 403);
        }

        // Check if slot is available
        $appointmentDate = Carbon::parse($validated['appointment_date']);
        $existingAppointment = Appointment::where('counselor_id', $validated['counselor_id'])
            ->whereDate('appointment_date', $appointmentDate->toDateString())
            ->whereTime('appointment_date', $appointmentDate->format('H:i:s'))
            ->first();

        if ($existingAppointment) {
            return response()->json([
                'message' => 'This time slot is no longer available'
            ], 422);
        }

        // Create appointment
        $appointment = Appointment::create([
            'student_id' => auth()->id(),
            'counselor_id' => $validated['counselor_id'],
            'appointment_date' => $validated['appointment_date'],
            'reason' => $validated['reason'],
            'location_type' => $validated['location_type'],
            'location' => $validated['location'] ?? '',
            'status' => 'pending',
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
        if ($user->hasRole('student')) {
            $query->where('student_id', $user->id);
        } elseif ($user->hasRole('counselor')) {
            $query->where('counselor_id', $user->id);
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
            'past' => (clone $query)
                ->where(function($q) use ($now) {
                    $q->where('status', 'completed')
                        ->orWhere(function($q) use ($now) {
                            $q->whereDate('appointment_date', '<', $now)
                                ->where('status', 'confirmed');
                        });
                })
                ->count(),
            'cancelled' => (clone $query)
                ->where('status', 'cancelled')
                ->count(),
        ];

        return response()->json($counts);
    }
} 