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
        Schema::create('users', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('user_name')->unique()->value(100); 
            $table->string('first_name')->value(100);
            $table->string('last_name')->value(100);
            $table->string('email')->unique();
            $table->string('password');
            $table->enum('role',['user', 'admin']); 
            $table->enum('status', ['active', 'inactive']); 
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
