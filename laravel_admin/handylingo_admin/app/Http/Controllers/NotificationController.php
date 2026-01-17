<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Notifications\DatabaseNotification;

class NotificationController extends Controller
{
    public function destroy(string $id){
        $notification = DatabaseNotification::findOrFail($id); 
        $notification->delete(); 
        return redirect()->back()->with('Success', 'Notification Deleted Successfully');
    }
}
