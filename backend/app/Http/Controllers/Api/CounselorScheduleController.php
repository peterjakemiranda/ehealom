<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CounselorSchedule;
use App\Models\CounselorExcludedDate;
use Illuminate\Http\Request;
use Carbon\Carbon;

class CounselorScheduleController extends Controller
{
    protected $defaultSchedule = [
        'monday' => ['is_available' => true],
        'tuesday' => ['is_available' => true],
        'wednesday' => ['is_available' => true],
        'thursday' => ['is_available' => true],
        'friday' => ['is_available' => true],
        'saturday' => ['is_available' => false],
        'sunday' => ['is_available' => false],
    ];

    protected $defaultTimes = [
        'start_time' => '09:00',
        'end_time' => '17:00',
        'break_start' => '12:00',
        'break_end' => '13:00'
    ];

    public function getSchedule(Request $request)
    {
        $user = $request->user();
        $savedSchedule = CounselorSchedule::where('user_id', $user->id)->get();
        
        // If no schedule exists, return default schedule
        if ($savedSchedule->isEmpty()) {
            $schedule = collect($this->defaultSchedule)->map(function ($settings, $day) {
                return array_merge(
                    ['day' => $day],
                    $settings,
                    $this->defaultTimes
                );
            })->values();
        } else {
            $schedule = $savedSchedule->map(function ($day) {
                return [
                    'day' => $day->day,
                    'is_available' => (bool) $day->is_available,
                    'start_time' => Carbon::parse($day->start_time)->format('H:i'),
                    'end_time' => Carbon::parse($day->end_time)->format('H:i'),
                    'break_start' => $day->break_start ? Carbon::parse($day->break_start)->format('H:i') : null,
                    'break_end' => $day->break_end ? Carbon::parse($day->break_end)->format('H:i') : null,
                ];
            });
        }

        $excludedDates = CounselorExcludedDate::where('user_id', $user->id)
            ->where('excluded_date', '>=', now())
            ->get();

        return response()->json([
            'schedule' => $schedule,
            'excluded_dates' => $excludedDates
        ]);
    }

    public function updateSchedule(Request $request)
    {
        $validated = $request->validate([
            'schedule' => 'required|array',
            'schedule.*.day' => 'required|in:monday,tuesday,wednesday,thursday,friday,saturday,sunday',
            'schedule.*.start_time' => 'required|date_format:H:i',
            'schedule.*.end_time' => 'required|date_format:H:i|after:schedule.*.start_time',
            'schedule.*.break_start' => 'nullable|date_format:H:i',
            'schedule.*.break_end' => 'nullable|date_format:H:i|after:schedule.*.break_start',
            'schedule.*.is_available' => 'required|boolean'
        ]);

        $user = $request->user();
        
        // Delete existing schedule
        CounselorSchedule::where('user_id', $user->id)->delete();
        
        // Create new schedule
        foreach ($validated['schedule'] as $day) {
            CounselorSchedule::create([
                'user_id' => $user->id,
                'day' => $day['day'],
                'start_time' => Carbon::createFromFormat('H:i', $day['start_time'])->format('H:i:s'),
                'end_time' => Carbon::createFromFormat('H:i', $day['end_time'])->format('H:i:s'),
                'break_start' => $day['break_start'] ? Carbon::createFromFormat('H:i', $day['break_start'])->format('H:i:s') : null,
                'break_end' => $day['break_end'] ? Carbon::createFromFormat('H:i', $day['break_end'])->format('H:i:s') : null,
                'is_available' => $day['is_available']
            ]);
        }

        return response()->json(['message' => 'Schedule updated successfully']);
    }

    public function updateExcludedDates(Request $request)
    {
        $validated = $request->validate([
            'dates' => 'required|array',
            'dates.*.date' => 'required|date|after_or_equal:today',
            'dates.*.reason' => 'nullable|string'
        ]);

        $user = $request->user();
        
        // Create new excluded dates without deleting existing ones
        foreach ($validated['dates'] as $date) {
            CounselorExcludedDate::create([
                'user_id' => $user->id,
                'excluded_date' => $date['date'],
                'reason' => $date['reason'] ?? null
            ]);
        }

        return response()->json(['message' => 'Excluded dates updated successfully']);
    }

    public function deleteExcludedDate($id)
    {
        $user = request()->user();
        $excludedDate = CounselorExcludedDate::where('user_id', $user->id)
            ->where('id', $id)
            ->firstOrFail();
        
        $excludedDate->delete();
        
        return response()->json(['message' => 'Date removed successfully']);
    }
} 