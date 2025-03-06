<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::table('users', function (Blueprint $table) {
            // Common fields for both types
            $table->integer('age')->nullable();
            $table->string('sex')->nullable();
            $table->string('marital_status')->nullable();
            
            // Student specific fields
            $table->string('major')->nullable();
            
            // Personnel specific fields
            $table->string('academic_rank')->nullable();
        });
    }

    public function down()
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'age',
                'sex',
                'marital_status',
                'major',
                'academic_rank'
            ]);
        });
    }
}; 