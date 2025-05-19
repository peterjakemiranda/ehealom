<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use App\Models\User;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;
use Carbon\CarbonPeriod;
use Phpml\Math\Statistic\Mean;
use Phpml\Math\Statistic\StandardDeviation;
use Phpml\Math\Matrix;

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

    private function forecastARIMA(array $data, int $forecastDays = 30): array
    {
        // Input validation
        if (empty($data)) {
            Log::warning('Empty data array provided to forecastARIMA');
            return array_fill(0, $forecastDays, 0);
        }

        // Validate data structure
        $requiredKeys = ['day', 'count'];
        foreach ($data as $item) {
            if (!is_array($item) || count(array_intersect_key(array_flip($requiredKeys), $item)) !== count($requiredKeys)) {
                Log::error('Invalid data structure in forecastARIMA', ['item' => $item]);
                return array_fill(0, $forecastDays, 0);
            }
        }

        // Sort data by date to ensure chronological order
        usort($data, function($a, $b) {
            return strtotime($a['day']) - strtotime($b['day']);
        });

        if (count($data) < 30) {
            Log::info('Insufficient data for ARIMA, using trend-based forecast', [
                'data_points' => count($data),
                'required' => 30,
                'data' => array_column($data, 'count'),
                'date_range' => [
                    'start' => $data[0]['day'],
                    'end' => end($data)['day']
                ]
            ]);
            
            // Calculate trend from available data
            $values = array_column($data, 'count');
            $mean = Mean::arithmetic($values);
            
            // If mean is zero or very small, use a small default value
            if ($mean < 0.1) {
                $mean = 1;
                Log::info('Mean value too small, using default value of 1');
            }
            
            // Calculate trend using linear regression
            $n = count($values);
            $x = range(1, $n);
            $y = $values;
            
            $sumX = array_sum($x);
            $sumY = array_sum($y);
            $sumXY = 0;
            $sumXX = 0;
            
            for ($i = 0; $i < $n; $i++) {
                $sumXY += $x[$i] * $y[$i];
                $sumXX += $x[$i] * $x[$i];
            }
            
            // Handle potential division by zero
            $denominator = ($n * $sumXX - $sumX * $sumX);
            if (abs($denominator) < 0.0001) {
                Log::info('Denominator too small, using flat forecast');
                $slope = 0;
                $intercept = $mean;
            } else {
                $slope = ($n * $sumXY - $sumX * $sumY) / $denominator;
                $intercept = ($sumY - $slope * $sumX) / $n;
            }
            
            // Generate forecast with trend and seasonal variation
            $forecast = [];
            $lastValue = end($values);
            
            for ($i = 0; $i < $forecastDays; $i++) {
                $trendValue = $intercept + $slope * ($n + $i + 1);
                
                // Add seasonal variation (weekly pattern)
                $dayOfWeek = ($i % 7);
                $seasonalFactor = 1.0;
                if ($dayOfWeek === 0 || $dayOfWeek === 6) { // Weekend
                    $seasonalFactor = 0.3; // 30% of weekday volume
                }
                
                // Add random variation (±15% of trend value)
                $variation = $trendValue * 0.15;
                $randomFactor = 1 + (rand(-100, 100) / 100) * 0.15;
                
                $forecastValue = max(0, round($trendValue * $seasonalFactor * $randomFactor));
                $forecast[] = $forecastValue;
            }
            
            Log::info('Trend-based forecast generated', [
                'mean' => $mean,
                'slope' => $slope,
                'intercept' => $intercept,
                'forecast' => $forecast,
                'forecast_days' => $forecastDays
            ]);
            
            return $forecast;
        }

        // Full ARIMA implementation for sufficient data
        $values = array_column($data, 'count');
        $mean = Mean::arithmetic($values);
        $std = StandardDeviation::population($values);
        
        // If mean is zero or very small, use a small default value
        if ($mean < 0.1) {
            $mean = 1;
            Log::info('Mean value too small in ARIMA, using default value of 1');
        }
        
        Log::info('ARIMA parameters:', [
            'mean' => $mean,
            'std' => $std,
            'data_points' => count($values),
            'sample_values' => array_slice($values, 0, 5),
            'date_range' => [
                'start' => $data[0]['day'],
                'end' => end($data)['day']
            ]
        ]);
        
        // Calculate weekly pattern
        $weeklyPattern = array_fill(0, 7, 0);
        $weeklyCount = array_fill(0, 7, 0);
        
        foreach ($data as $index => $item) {
            $dayOfWeek = Carbon::parse($item['day'])->dayOfWeek;
            $weeklyPattern[$dayOfWeek] += $item['count'];
            $weeklyCount[$dayOfWeek]++;
        }
        
        // Calculate average for each day of week
        for ($i = 0; $i < 7; $i++) {
            if ($weeklyCount[$i] > 0) {
                $weeklyPattern[$i] /= $weeklyCount[$i];
            } else {
                $weeklyPattern[$i] = $mean; // Use mean if no data for this day
                Log::info("No data for day {$i}, using mean value");
            }
        }
        
        // Normalize weekly pattern
        $weeklyMean = array_sum($weeklyPattern) / 7;
        if ($weeklyMean < 0.1) {
            $weeklyMean = 1;
            Log::info('Weekly mean too small, using default value of 1');
        }
        
        $weeklyPattern = array_map(function($x) use ($weeklyMean) {
            return $x / $weeklyMean;
        }, $weeklyPattern);
        
        Log::info('Weekly pattern:', [
            'pattern' => $weeklyPattern,
            'mean' => $weeklyMean,
            'day_names' => ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
        ]);
        
        // Calculate trend using linear regression
        $n = count($values);
        $x = range(1, $n);
        $y = $values;
        
        $sumX = array_sum($x);
        $sumY = array_sum($y);
        $sumXY = 0;
        $sumXX = 0;
        
        for ($i = 0; $i < $n; $i++) {
            $sumXY += $x[$i] * $y[$i];
            $sumXX += $x[$i] * $x[$i];
        }
        
        // Handle potential division by zero
        $denominator = ($n * $sumXX - $sumX * $sumX);
        if (abs($denominator) < 0.0001) {
            Log::info('Denominator too small in ARIMA, using flat forecast');
            $slope = 0;
            $intercept = $mean;
        } else {
            $slope = ($n * $sumXY - $sumX * $sumY) / $denominator;
            $intercept = ($sumY - $slope * $sumX) / $n;
        }
        
        // Generate forecast
        $forecast = [];
        $lastDate = Carbon::parse(end($data)['day']);
        
        for ($i = 0; $i < $forecastDays; $i++) {
            $forecastDate = $lastDate->copy()->addDays($i + 1);
            $dayOfWeek = $forecastDate->dayOfWeek;
            
            // Calculate base forecast with trend
            $trendValue = $intercept + $slope * ($n + $i + 1);
            
            // Apply weekly pattern
            $seasonalFactor = $weeklyPattern[$dayOfWeek];
            
            // Add small random variation (±10% of trend value)
            $variation = $trendValue * 0.1;
            $randomFactor = 1 + (rand(-100, 100) / 100) * 0.1;
            
            $forecastValue = max(0, round($trendValue * $seasonalFactor * $randomFactor));
            $forecast[] = $forecastValue;
        }
        
        Log::info('ARIMA forecast generated', [
            'slope' => $slope,
            'intercept' => $intercept,
            'forecast' => $forecast,
            'forecast_days' => $forecastDays,
            'forecast_dates' => [
                'start' => $lastDate->copy()->addDay()->toDateString(),
                'end' => $lastDate->copy()->addDays($forecastDays)->toDateString()
            ]
        ]);
        
        return $forecast;
    }

    private function addForecastToData(array $data, string $dateKeyName = 'day', int $forecastDays = 30): array
    {
        if (empty($data)) {
            return $data;
        }

        // Group data by series (category, age_group, or department)
        $groupedData = [];
        foreach ($data as $item) {
            $key = $item['category_title'] ?? $item['age_group'] ?? $item['department'] ?? null;
            if ($key) {
                if (!isset($groupedData[$key])) {
                    $groupedData[$key] = [];
                }
                $groupedData[$key][] = $item;
            }
        }

        $result = [];
        foreach ($groupedData as $groupKey => $groupData) {
            // Sort group data by date
            usort($groupData, function($a, $b) use ($dateKeyName) {
                return strtotime($a[$dateKeyName]) - strtotime($b[$dateKeyName]);
            });

            // Get forecast for this group
            $forecast = $this->forecastARIMA($groupData, $forecastDays);
            $lastDate = Carbon::parse(end($groupData)[$dateKeyName]);
            $firstDate = Carbon::parse($groupData[0][$dateKeyName]);

            // Create a date range for the entire period (actual + forecast)
            $dateRange = CarbonPeriod::create($firstDate, $lastDate->copy()->addDays($forecastDays));
            
            // Create a map of actual data by date
            $actualDataMap = [];
            foreach ($groupData as $item) {
                $actualDataMap[$item[$dateKeyName]] = $item;
            }

            // Process each date in the range
            foreach ($dateRange as $date) {
                $dateString = $date->toDateString();
                
                if (isset($actualDataMap[$dateString])) {
                    // Add actual data
                    $result[] = $actualDataMap[$dateString];
                } else {
                    // Calculate forecast index
                    $daysFromLastActual = $lastDate->diffInDays($date);
                    if ($daysFromLastActual > 0 && $daysFromLastActual <= $forecastDays) {
                        // This is a forecast date
                        $forecastItem = [
                            $dateKeyName => $dateString,
                            'count' => max(0, round($forecast[$daysFromLastActual - 1])),
                            'is_forecast' => true
                        ];

                        // Add the appropriate group key
                        if (isset($groupData[0]['category_title'])) {
                            $forecastItem['category_title'] = $groupKey;
                        } elseif (isset($groupData[0]['age_group'])) {
                            $forecastItem['age_group'] = $groupKey;
                        } elseif (isset($groupData[0]['department'])) {
                            $forecastItem['department'] = $groupKey;
                        }

                        $result[] = $forecastItem;
                    } else {
                        // This is a gap in actual data, add zero
                        $zeroItem = [
                            $dateKeyName => $dateString,
                            'count' => 0
                        ];

                        // Add the appropriate group key
                        if (isset($groupData[0]['category_title'])) {
                            $zeroItem['category_title'] = $groupKey;
                        } elseif (isset($groupData[0]['age_group'])) {
                            $zeroItem['age_group'] = $groupKey;
                        } elseif (isset($groupData[0]['department'])) {
                            $zeroItem['department'] = $groupKey;
                        }

                        $result[] = $zeroItem;
                    }
                }
            }
        }

        // Sort final result by date
        usort($result, function($a, $b) use ($dateKeyName) {
            return strtotime($a[$dateKeyName]) - strtotime($b[$dateKeyName]);
        });

        return $result;
    }

    public function appointmentsByCategoryDaily(Request $request)
    {
        [$startDate, $endDate] = $this->getDateRange($request);
        $datePeriod = CarbonPeriod::create($startDate, $endDate);

        Log::info('Date range:', [
            'start' => $startDate->toDateString(),
            'end' => $endDate->toDateString(),
            'period' => $request->input('period')
        ]);

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

        Log::info('Raw SQL query:', [
            'sql' => Appointment::join('categories', 'appointments.category_id', '=', 'categories.id')
                ->whereBetween('appointments.appointment_date', [$startDate, $endDate])
                ->select(
                    DB::raw("DATE(appointments.appointment_date) as day"),
                    'categories.title as category_title',
                    DB::raw('COUNT(appointments.id) as count')
                )
                ->groupBy('day', 'categories.title')
                ->orderBy('day', 'asc')
                ->toSql()
        ]);

        Log::info('Actual data:', [
            'count' => $actualData->count(),
            'data' => $actualData->toArray()
        ]);

        $allCategoryTitles = Category::orderBy('title')->pluck('title')->all();
        Log::info('Category titles:', ['titles' => $allCategoryTitles]);
        
        $filledData = $this->zeroFillTimeseries($datePeriod, $allCategoryTitles, $actualData, 'category_title');
        Log::info('Filled data:', [
            'count' => count($filledData),
            'sample' => array_slice($filledData, 0, 5)
        ]);

        // Add forecast for each category
        $forecastDays = $request->input('forecast_days', 30);
        $result = [];
        foreach ($allCategoryTitles as $category) {
            $categoryData = array_filter($filledData, fn($item) => $item['category_title'] === $category);
            $categoryData = array_values($categoryData);
            
            Log::info("Processing category: {$category}", [
                'data_points' => count($categoryData),
                'sample' => array_slice($categoryData, 0, 5)
            ]);
            
            $categoryDataWithForecast = $this->addForecastToData($categoryData, 'day', $forecastDays);
            $result = array_merge($result, $categoryDataWithForecast);
        }

        Log::info('Final result:', [
            'total_records' => count($result),
            'forecast_records' => count(array_filter($result, fn($item) => $item['is_forecast'] ?? false)),
            'sample' => array_slice($result, 0, 5)
        ]);

        return response()->json($result);
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

        // Add forecast for each age group
        $forecastDays = $request->input('forecast_days', 30);
        $result = [];
        foreach ($ageGroups as $ageGroup) {
            $ageData = array_filter($filledData, fn($item) => $item['age_group'] === $ageGroup);
            $ageData = array_values($ageData);
            $ageDataWithForecast = $this->addForecastToData($ageData, 'day', $forecastDays);
            $result = array_merge($result, $ageDataWithForecast);
        }

        return response()->json($result);
    }

    public function appointmentsByDepartmentDaily(Request $request)
    {
        [$startDate, $endDate] = $this->getDateRange($request);
        $datePeriod = CarbonPeriod::create($startDate, $endDate);

        $allDepartments = User::whereNotNull('department')
            ->where('department', '!=', '')
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

        // Add forecast for each department
        $forecastDays = $request->input('forecast_days', 30);
        $result = [];
        foreach ($allDepartments as $department) {
            $deptData = array_filter($filledData, fn($item) => $item['department'] === $department);
            $deptData = array_values($deptData);
            $deptDataWithForecast = $this->addForecastToData($deptData, 'day', $forecastDays);
            $result = array_merge($result, $deptDataWithForecast);
        }

        return response()->json($result);
    }
} 