<?php

namespace App\Exports;

use App\Models\Users;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;

class ExportUser implements FromCollection, WithHeadings
{

    public function collection()
    {
        return Users::select('id', 'user_name', 'first_name', 'last_name', 'email', 'role', 'status', 'created_at', 'updated_at')->where('role', 'user')->get();
    }
    public function headings(): array
    {
        return [
            'ID',
            'User Name',
            'First Name',
            'Last Name',
            'Email',
            'Role',
            'Status',
            'Created At',
            'Updated At',
        ];
    }
    /**
    * @return \Illuminate\Support\Collection
    */

}
