<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Users;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // User::factory(10)->create();

        Users::create([
            'id' => Str::uuid(),
            'user_name' => 'adminuser',
            'first_name' => 'Admin',
            'last_name' => 'User',
            'email' => 'admin@handylingo.com',
            'password' => bcrypt('password'),
            'role'=>'admin', 
            'status'=>'active',
        ]); 
    }
}
