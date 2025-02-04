<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('appointments', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('student_id')->constrained('users');
            $table->foreignId('counselor_id')->constrained('users');
            $table->dateTime('appointment_date');
            $table->string('status')->default('pending'); // pending, confirmed, cancelled, completed
            $table->string('location_type')->default('online'); // online, on-site
            $table->string('location')->nullable(); // specific location for on-site
            $table->text('reason')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('appointments');
    }
}; 