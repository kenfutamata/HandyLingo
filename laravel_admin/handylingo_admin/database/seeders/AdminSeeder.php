<?php

namespace Database\Seeders;

use App\Models\Users;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class AdminSeeder extends Seeder
{
    /**
     * Run the database seeds.  
     */
    public function run(): void
    {
        Users::create([
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
