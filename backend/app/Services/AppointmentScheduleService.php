<?php

namespace App\Services;

use App\Models\CounselorSchedule;
use App\Models\CounselorExcludedDate;
use App\Models\Appointment;
use Carbon\Carbon;

class AppointmentScheduleService
{
    public function getAvailableSlots($counselorId, $date)
    {
        $dayOfWeek = strtolower(Carbon::parse($date)->format('l'));
        
        // Get counselor's schedule for the day
        $schedule = CounselorSchedule::where('user_id', $counselorId)
            ->where('day', $dayOfWeek)
            ->where('is_available', true)
            ->first();

        // Check if day is available
        if (!$schedule) {
            return [
                'slots' => [],
                'is_excluded' => false,
                'reason' => 'No schedule available for this day'
            ];
        }

        // Check if date is excluded
        $excludedDate = CounselorExcludedDate::where('user_id', $counselorId)
            ->whereDate('excluded_date', $date)
            ->first();

        if ($excludedDate) {
            return [
                'slots' => [],
                'is_excluded' => true,
                'reason' => $excludedDate->reason ?? 'This date is excluded from appointments'
            ];
        }

        // Get all slots for the day
        $slots = $this->generateTimeSlots(
            $schedule->start_time,
            $schedule->end_time,
            $schedule->break_start,
            $schedule->break_end
        );

        // Get booked appointments
        $bookedSlots = Appointment::where('counselor_id', $counselorId)
            ->whereDate('appointment_date', $date)
            ->whereIn('status', ['pending', 'confirmed'])
            ->get()
            ->map(function ($appointment) {
                return Carbon::parse($appointment->appointment_date)->format('H:i');
            })
            ->toArray();

        // Remove booked slots
        return [
            'slots' => array_values(array_diff($slots, $bookedSlots)),
            'is_excluded' => false,
            'reason' => null
        ];
    }

    private function generateTimeSlots($startTime, $endTime, $breakStart, $breakEnd, $duration = 60)
    {
        $slots = [];
        $current = Carbon::parse($startTime);
        $end = Carbon::parse($endTime);
        $breakStartTime = $breakStart ? Carbon::parse($breakStart) : null;
        $breakEndTime = $breakEnd ? Carbon::parse($breakEnd) : null;

        while ($current < $end) {
            // Skip break time
            if ($breakStartTime && $breakEndTime) {
                if ($current >= $breakStartTime && $current < $breakEndTime) {
                    $current = $breakEndTime->copy();
                    continue;
                }
            }

            // Add slot if there's enough time before end or break
            $slotEnd = $current->copy()->addMinutes($duration);
            if ($slotEnd <= $end && 
                (!$breakStartTime || $slotEnd <= $breakStartTime || $current >= $breakEndTime)) {
                $slots[] = $current->format('H:i');
            }

            $current->addMinutes($duration);
        }

        return $slots;
    }
} 