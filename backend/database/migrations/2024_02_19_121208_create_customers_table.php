<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('customers', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique()->nullable(false);
            $table->string('first_name');
            $table->string('last_name');
            $table->string('address');
            $table->string('id_type')->nullable();
            $table->string('id_number')->unique()->nullable();
            $table->string('phone_number')->nullable();
            $table->string('email')->nullable();
            $table->string('preferred_communication_channel')->default('mobile');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('customers');
    }
};
