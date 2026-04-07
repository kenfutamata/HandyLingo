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
        Schema::create('sign_language_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();
            
            // Use foreignUuid instead of foreignId to match the users table
            $table->foreignUuid('user_id')->constrained('users')->onDelete('cascade');
            
            $table->string('translated_output'); 
            $table->decimal('accuracy', 5, 2);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('sign_language_logs');
    }
};