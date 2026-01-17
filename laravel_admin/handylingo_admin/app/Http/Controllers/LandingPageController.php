<?php

namespace App\Http\Controllers;

use App\Models\Feedbacks;
use App\Models\Users;
use App\Notifications\NotifyFeedbackDetail;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Notification;

class LandingPageController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        return view('admin.landing_page');
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        //
    }

    //Feedback Store Function
    public function storeFeedback(Request $request) 
    {
        $validateInformation = $request->validate([
            'first_name' => 'required|string|max:255',
            'last_name' => 'required|string|max:255',
            'email' => 'required|email|max:255',
            'feedback_type' => 'required|in:App Feedback,Issue Report',
            'message' => 'required|string',
            'rating'=> 'nullable|integer|min:1|max:5',
        ]);

        $validateInformation['status'] = 'New'; 

        try{
            Feedbacks::create($validateInformation);
            $user = Users::all(); 
            Notification::send($user, new NotifyFeedbackDetail());
            return back()->with('Success', 'Thank you for your feedback! We appreciate your input.');
        }catch(Exception $e){
            Log::error('Error storing feedback: ' . $e->getMessage());
            return back()->with('Error', 'There was an error submitting your feedback. Please try again later.');   
        }
    }
    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        //
    }
}
