<?php

namespace App\Exports;

use App\Models\Feedbacks;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;

class FeedbacksExport implements FromCollection, WithHeadings
{
    public function collection()
    {
        return Feedbacks::select('id', 'user_id','first_name', 'last_name', 'email', 'feedback_type', 'message', 'status', 'created_at', 'updated_at')->whereIn('status', ['New', 'Completed'])->get();
    }
    public function headings(): array
    {
        return [
            'ID',
            'User ID',
            'First Name',
            'Last Name',
            'Email',
            'Feedback Type',
            'Message',
            'Status',
            'Created At',
            'Updated At',
        ];
    }
}
