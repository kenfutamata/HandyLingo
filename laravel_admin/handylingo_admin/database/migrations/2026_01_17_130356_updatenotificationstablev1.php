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
        Schema::table('notifications', function (Blueprint $table) {
            // We have to drop and recreate the columns because 
            // changing types from bigint to uuid requires a cast in Postgres
            $table->dropColumn(['notifiable_id', 'notifiable_type']);
        });

        Schema::table('notifications', function (Blueprint $table) {
            $table->uuidMorphs('notifiable');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        //
    }
};
