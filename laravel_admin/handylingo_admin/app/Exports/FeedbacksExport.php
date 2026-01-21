<?php

namespace App\Exports;

use App\Models\Feedbacks;
use Maatwebsite\Excel\Concerns\FromCollection;

class FeedbacksExport implements FromCollection
{
    /**
    * @return \Illuminate\Support\Collection
    */
    public function collection()
    {
        return Feedbacks::all();
    }
}
