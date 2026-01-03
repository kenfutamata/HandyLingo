<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class CheckDbConnection extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'db:check';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Checks the connection to the default database.';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info("Attempting to connect to database...");
        $this->comment("Driver: " . config('database.default'));
        $this->comment("Host:   " . config('database.connections.pgsql.host'));
        $this->comment("Port:   " . config('database.connections.pgsql.port'));
        $this->comment("DB:     " . config('database.connections.pgsql.database'));
        $this->comment("User:   " . config('database.connections.pgsql.username'));

        try {
            DB::connection()->getPdo();
            
            $this->info("✅ SUCCESS: Database connection is working.");
            return 0; // Success exit code

        } catch (\Exception $e) {
            $this->error("FAILED: Could not connect to the database.");
            $this->error("Error Message: " . $e->getMessage());
            return 1; // Failure exit code
        }
    }
}