<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('user_type')->default('student'); // student, counselor, admin
            $table->string('student_id')->nullable();
            $table->string('department')->nullable();
            $table->string('course')->nullable();
            $table->string('year_level')->nullable();
            $table->string('phone')->nullable();
            $table->boolean('is_active')->default(true);
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'user_type',
                'student_id',
                'department',
                'course',
                'year_level',
                'phone',
                'is_active'
            ]);
        });
    }
}; 