<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use Illuminate\Http\Request;
use App\Http\Resources\AppointmentResource;
use Carbon\Carbon;
use Illuminate\Support\Str;

class AppointmentController extends Controller
{
    // Time slot interval in minutes (can be moved to settings later)
    const TIME_SLOT_INTERVAL = 30;
    const START_TIME = '09:00';
    const END_TIME = '17:00';

    public function index(Request $request)
    {
        $query = Appointment::query()
            ->with(['student', 'counselor']);

        if ($request->user()->hasRole('student')) {
            $query->where('student_id', $request->user()->id);
        } elseif ($request->user()->hasRole('counselor')) {
            $query->where('counselor_id', $request->user()->id);
        }

        if ($request->has('status') && $request->get('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('date') && $request->get('date')) {
            $query->whereDate('appointment_date', $request->date);
        }

        $appointments = $query->orderBy('appointment_date', 'desc')
            ->paginate($request->input('per_page', 10));

        return AppointmentResource::collection($appointments);
    }

    public function availableSlots(Request $request)
    {
        $validated = $request->validate([
            'counselor_id' => 'required|exists:users,id',
            'date' => 'required|date|after_or_equal:today',
            'current_appointment_id' => 'nullable|exists:appointments,id'
        ]);

        // Parse date in UTC
        $date = Carbon::parse($validated['date'])->startOfDay()->utc();
        $startTime = Carbon::parse($date->format('Y-m-d') . ' ' . self::START_TIME)->utc();
        $endTime = Carbon::parse($date->format('Y-m-d') . ' ' . self::END_TIME)->utc();

        // Get booked appointments for the date
        $query = Appointment::where('counselor_id', $validated['counselor_id'])
            ->whereDate('appointment_date', $date)
            ->whereIn('status', ['pending', 'confirmed']);

        if (!empty($validated['current_appointment_id'])) {
            $query->where('id', '!=', $validated['current_appointment_id']);
        }

        $bookedSlots = $query->pluck('appointment_date')
            ->map(function($slot) {
                return Carbon::parse($slot)->utc()->format('H:i');
            })
            ->toArray();

        // Generate available time slots
        $slots = [];
        $current = clone $startTime;

        while ($current <= $endTime) {
            $timeSlot = $current->format('H:i');
            $isBooked = in_array($timeSlot, $bookedSlots);

            $slots[] = [
                'time' => $timeSlot,
                'display_time' => $current->copy()->setTimezone($request->header('Time-Zone', 'UTC'))->format('g:i A'),
                'available' => !$isBooked
            ];

            $current->addMinutes(self::TIME_SLOT_INTERVAL);
        }

        return response()->json([
            'data' => [
                'slots' => $slots,
                'date' => $date->format('Y-m-d'),
                'counselor_id' => $validated['counselor_id']
            ]
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'counselor_id' => 'required|exists:users,id',
            'appointment_date' => 'required|date|after:now',
            'reason' => 'required|string',
        ]);

        // Parse appointment date as UTC
        $appointmentDate = Carbon::parse($validated['appointment_date'])->utc();
        
        // Check if slot is still available
        $isSlotTaken = Appointment::where('counselor_id', $validated['counselor_id'])
            ->whereDate('appointment_date', $appointmentDate)
            ->whereTime('appointment_date', $appointmentDate->format('H:i:s'))
            ->whereIn('status', ['pending', 'confirmed'])
            ->exists();

        if ($isSlotTaken) {
            return response()->json([
                'message' => 'This time slot is no longer available'
            ], 422);
        }

        $appointment = Appointment::create([
            'uuid' => Str::uuid(),
            'student_id' => $request->user()->id,
            'counselor_id' => $validated['counselor_id'],
            'appointment_date' => $appointmentDate,
            'reason' => $validated['reason'],
            'status' => 'pending'
        ]);

        return new AppointmentResource($appointment->load(['student', 'counselor']));
    }

    public function update(Request $request, Appointment $appointment)
    {
        // Validate user can update this appointment
        if ($request->user()->hasRole('student') && $appointment->student_id !== $request->user()->id) {
            abort(403, 'Unauthorized to update this appointment');
        }
        if ($request->user()->hasRole('counselor') && $appointment->counselor_id !== $request->user()->id) {
            abort(403, 'Unauthorized to update this appointment');
        }

        $validated = $request->validate([
            'counselor_id' => 'sometimes|exists:users,id',
            'appointment_date' => 'sometimes|date|after:now',
            'reason' => 'sometimes|string',
            'status' => [
                'sometimes',
                'string',
                function ($attribute, $value, $fail) use ($request, $appointment) {
                    // Status transition rules
                    $allowedTransitions = [
                        'student' => [
                            'pending' => ['cancelled'],
                            'confirmed' => ['cancelled']
                        ],
                        'counselor' => [
                            'pending' => ['pending', 'confirmed', 'cancelled'],
                            'confirmed' => ['confirmed', 'completed', 'cancelled']
                        ]
                    ];

                    $userType = $request->user()->hasRole('student') ? 'student' : 'counselor';
                    $currentStatus = $appointment->status;

                    if (!isset($allowedTransitions[$userType][$currentStatus]) ||
                        !in_array($value, $allowedTransitions[$userType][$currentStatus])) {
                        $fail('Invalid status transition.');
                    }
                }
            ],
            'notes' => 'nullable|string',
        ]);

        // Check if slot is still available when changing appointment date
        if (isset($validated['appointment_date'])) {
            $appointmentDate = Carbon::parse($validated['appointment_date']);
            $validated['appointment_date'] = $appointmentDate;
            
            if ($appointmentDate->format('Y-m-d H:i') !== Carbon::parse($appointment->appointment_date)->format('Y-m-d H:i')) {
                $isSlotTaken = Appointment::where('counselor_id', $validated['counselor_id'] ?? $appointment->counselor_id)
                    ->whereDate('appointment_date', $appointmentDate)
                    ->whereTime('appointment_date', $appointmentDate->format('H:i:s'))
                    ->whereIn('status', ['pending', 'confirmed'])
                    ->where('id', '!=', $appointment->id)
                    ->exists();

                if ($isSlotTaken) {
                    return response()->json([
                        'message' => 'This time slot is no longer available'
                    ], 422);
                }
            }
        }

        $appointment->update($validated);

        return new AppointmentResource($appointment->load(['student', 'counselor']));
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
} 