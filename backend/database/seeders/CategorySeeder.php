<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Category;

class CategorySeeder extends Seeder
{
    public function run()
    {
        $categories = [
            [
                'title' => 'Mental Health',
                'description' => 'Resources for mental health and well-being'
            ],
            [
                'title' => 'Academic Support',
                'description' => 'Resources for academic success and study skills'
            ],
            [
                'title' => 'Career Development',
                'description' => 'Resources for career planning and professional growth'
            ],
            [
                'title' => 'Personal Development',
                'description' => 'Resources for personal growth and life skills'
            ],
            [
                'title' => 'Stress Management',
                'description' => 'Resources for managing stress and anxiety'
            ]
        ];

        foreach ($categories as $category) {
            Category::create($category);
        }
    }
} 