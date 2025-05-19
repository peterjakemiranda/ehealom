<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Appointment;
use App\Models\User;
use App\Models\Category;
use Carbon\Carbon;
use Illuminate\Support\Str;

class DummyAppointmentsSeeder extends Seeder
{
    public function run()
    {
        // Get all categories
        $categories = Category::all();
        
        // Get some students and counselors
        $students = User::where('is_active', 1)->take(20)->get();
        $counselors = User::where('is_active', 1)->take(3)->get();
        
        if ($students->isEmpty() || $counselors->isEmpty()) {
            $this->command->error('No students or counselors found. Please seed users first.');
            return;
        }

        // Generate appointments for April and May
        $startDate = Carbon::create(2025, 4, 1)->startOfDay();
        $endDate = Carbon::create(2025, 5, 31)->endOfDay();
        
        // Create appointments with realistic patterns
        $currentDate = $startDate->copy();
        while ($currentDate <= $endDate) {
            // Skip weekends
            if ($currentDate->isWeekend()) {
                $currentDate->addDay();
                continue;
            }

            // Generate 3-8 appointments per day
            $appointmentsPerDay = rand(3, 8);
            
            for ($i = 0; $i < $appointmentsPerDay; $i++) {
                // Create appointment between 9 AM and 5 PM
                $appointmentTime = $currentDate->copy()->setHour(rand(9, 16))->setMinute(rand(0, 3) * 20);
                
                // Randomly select student and counselor
                $student = $students->random();
                $counselor = $counselors->random();
                $category = $categories->random();
                
                // Generate appointment with realistic status distribution
                $status = $this->getRandomStatus();
                
                // Create the appointment
                Appointment::create([
                    'uuid' => Str::uuid(),
                    'student_id' => $student->id,
                    'counselor_id' => $counselor->id,
                    'category_id' => $category->id,
                    'appointment_date' => $appointmentTime,
                    'status' => $status,
                    'location_type' => rand(0, 1) ? 'online' : 'in-person',
                    'location' => rand(0, 1) ? 'Room ' . rand(101, 305) : null,
                    'reason' => $this->getRandomReason($category->title),
                    'notes' => rand(0, 1) ? $this->getRandomNotes() : null,
                    'created_at' => $appointmentTime->copy()->subDays(rand(1, 7)),
                    'updated_at' => $appointmentTime->copy()->subDays(rand(0, 3)),
                ]);
            }
            
            $currentDate->addDay();
        }
    }

    private function getRandomStatus()
    {
        $statuses = [
            'completed' => 60,  // 60% completed
            'scheduled' => 25,  // 25% scheduled
            'cancelled' => 10,  // 10% cancelled
            'no-show' => 5      // 5% no-show
        ];
        
        $rand = rand(1, 100);
        $cumulative = 0;
        
        foreach ($statuses as $status => $probability) {
            $cumulative += $probability;
            if ($rand <= $cumulative) {
                return $status;
            }
        }
        
        return 'scheduled';
    }

    private function getRandomReason($category)
    {
        $reasons = [
            'Mental Health' => [
                'Feeling overwhelmed with academic pressure',
                'Difficulty managing stress and anxiety',
                'Need support with emotional well-being',
                'Struggling with sleep issues',
                'Wanting to improve mental health'
            ],
            'Academic Support' => [
                'Need help with study strategies',
                'Difficulty with time management',
                'Wanting to improve academic performance',
                'Need guidance on course selection',
                'Struggling with specific subjects'
            ],
            'Career Development' => [
                'Career path exploration',
                'Resume and interview preparation',
                'Internship opportunities',
                'Professional development planning',
                'Industry insights and networking'
            ],
            'Personal Development' => [
                'Building self-confidence',
                'Improving communication skills',
                'Personal goal setting',
                'Work-life balance',
                'Personal growth strategies'
            ],
            'Stress Management' => [
                'Coping with academic pressure',
                'Managing deadlines and workload',
                'Balancing multiple responsibilities',
                'Dealing with exam stress',
                'Learning relaxation techniques'
            ]
        ];

        $categoryReasons = $reasons[$category] ?? $reasons['Mental Health'];
        return $categoryReasons[array_rand($categoryReasons)];
    }

    private function getRandomNotes()
    {
        $notes = [
            'Student requested follow-up session',
            'Recommended additional resources',
            'Discussed coping strategies',
            'Planned next steps for improvement',
            'Addressed immediate concerns',
            'Set goals for next session',
            'Provided additional reading materials',
            'Scheduled follow-up appointment'
        ];

        return $notes[array_rand($notes)];
    }
} 