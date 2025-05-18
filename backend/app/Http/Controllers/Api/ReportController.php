<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use App\Models\User;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;
use Carbon\CarbonPeriod;

class ReportController extends Controller
{
    private function getDateRange(Request $request): array
    {
        $endDate = Carbon::now()->endOfDay();
        $startDate = Carbon::now()->startOfDay(); // Default to today

        if ($request->filled('start_date') && $request->filled('end_date')) {
            $startDate = Carbon::parse($request->input('start_date'))->startOfDay();
            $endDate = Carbon::parse($request->input('end_date'))->endOfDay();
        } elseif ($request->filled('period')) {
            $period = $request->input('period');
            // endDate is already today for period-based filters
            switch ($period) {
                case 'today':
                    // startDate is already today
                    break;
                case 'last_7_days':
                    $startDate = Carbon::now()->subDays(6)->startOfDay();
                    break;
                case 'last_30_days':
                    $startDate = Carbon::now()->subDays(29)->startOfDay();
                    break;
                case 'last_90_days':
                    $startDate = Carbon::now()->subDays(89)->startOfDay();
                    break;
                case 'last_365_days':
                    $startDate = Carbon::now()->subDays(364)->startOfDay();
                    break;
                default:
                    $startDate = Carbon::now()->subDays(29)->startOfDay(); // Default fallback
                    break;
            }
        } else {
            // Default to last 30 days if no period or dates specified
            $startDate = Carbon::now()->subDays(29)->startOfDay();
        }
        return [$startDate, $endDate];
    }

    private function zeroFillTimeseries(
        CarbonPeriod $datePeriod,
        array $seriesNames,
        iterable $actualData,
        string $seriesKeyName,
        string $countKeyName = 'count',
        string $dateKeyName = 'day'
    ): array {
        $results = [];
        $actualDataMap = collect($actualData)->groupBy($dateKeyName)->map(function ($dayData) use ($seriesKeyName, $countKeyName) {
            return collect($dayData)->keyBy($seriesKeyName)->map(fn($item) => $item[$countKeyName]);
        });

        foreach ($datePeriod as $date) {
            $currentDateString = $date->toDateString();
            foreach ($seriesNames as $seriesName) {
                $count = $actualDataMap->get($currentDateString)?->get($seriesName) ?? 0;
                $results[] = [
                    $dateKeyName => $currentDateString,
                    $seriesKeyName => $seriesName,
                    $countKeyName => $count
                ];
            }
        }
        return $results;
    }

    public function appointmentsByCategoryDaily(Request $request)
    {
        [$startDate, $endDate] = $this->getDateRange($request);
        $datePeriod = CarbonPeriod::create($startDate, $endDate);

        $actualData = Appointment::join('categories', 'appointments.category_id', '=', 'categories.id')
            ->whereBetween('appointments.appointment_date', [$startDate, $endDate])
            ->select(
                DB::raw("DATE(appointments.appointment_date) as day"),
                'categories.title as category_title',
                DB::raw('COUNT(appointments.id) as count')
            )
            ->groupBy('day', 'categories.title')
            ->orderBy('day', 'asc')
            ->get();

        $allCategoryTitles = Category::orderBy('title')->pluck('title')->all();
        
        $filledData = $this->zeroFillTimeseries($datePeriod, $allCategoryTitles, $actualData, 'category_title');

        return response()->json($filledData);
    }

    public function appointmentsByAgeDaily(Request $request)
    {
        [$startDate, $endDate] = $this->getDateRange($request);
        $datePeriod = CarbonPeriod::create($startDate, $endDate);
        
        $ageGroups = ['Under 18', '18-22', '23-27', '28-35', 'Over 35', 'Unknown'];

        $actualData = Appointment::join('users', 'appointments.student_id', '=', 'users.id')
            ->whereBetween('appointments.appointment_date', [$startDate, $endDate])
            ->whereNotNull('users.age')
            ->select(
                DB::raw("DATE(appointments.appointment_date) as day"),
                DB::raw("CASE 
                            WHEN users.age < 18 THEN 'Under 18'
                            WHEN users.age BETWEEN 18 AND 22 THEN '18-22'
                            WHEN users.age BETWEEN 23 AND 27 THEN '23-27'
                            WHEN users.age BETWEEN 28 AND 35 THEN '28-35'
                            WHEN users.age > 35 THEN 'Over 35'
                            ELSE 'Unknown'
                         END as age_group"),
                DB::raw('COUNT(appointments.id) as count')
            )
            ->groupBy('day', 'age_group')
            ->orderBy('day', 'asc')
            ->get();
        
        $filledData = $this->zeroFillTimeseries($datePeriod, $ageGroups, $actualData, 'age_group');

        return response()->json($filledData);
    }

    public function appointmentsByDepartmentDaily(Request $request)
    {
        [$startDate, $endDate] = $this->getDateRange($request);
        $datePeriod = CarbonPeriod::create($startDate, $endDate);

        $allDepartments = User::whereNotNull('department')
            ->where('department', '!=', '') // Ensure not empty string
            ->distinct()
            ->orderBy('department')
            ->pluck('department')
            ->all();

        $actualData = Appointment::join('users', 'appointments.student_id', '=', 'users.id')
            ->whereBetween('appointments.appointment_date', [$startDate, $endDate])
            ->whereNotNull('users.department')
            ->where('users.department', '!=', '')
            ->select(
                DB::raw("DATE(appointments.appointment_date) as day"),
                'users.department',
                DB::raw('COUNT(appointments.id) as count')
            )
            ->groupBy('day', 'users.department')
            ->orderBy('day', 'asc')
            ->get();
            
        $filledData = $this->zeroFillTimeseries($datePeriod, $allDepartments, $actualData, 'department');

        return response()->json($filledData);
    }
} 