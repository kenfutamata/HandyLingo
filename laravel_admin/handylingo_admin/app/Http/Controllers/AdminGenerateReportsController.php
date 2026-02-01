<?php

namespace App\Http\Controllers;

use App\Models\Feedbacks;
use App\Models\Users;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Http;

class AdminGenerateReportsController extends Controller
{
    public function index(Request $request)
    {
        $user = Auth::guard('admin')->user();
        $notifications = $user->notifications ?? collect();
        $unreadNotifications = $user->unreadNotifications ?? collect();

        $selectedMonth = $request->input('month', Carbon::now()->format('Y-m'));
        $date = Carbon::parse($selectedMonth . '-01');

        $ratingsChartData = null;
        $usersChartData = null;
        $errorMessage = null;

        try {
            $ratingCounts = Feedbacks::whereYear('created_at', $date->year)
                ->whereMonth('created_at', $date->month)
                ->whereNotNull('rating')
                ->select('rating', DB::raw('count(*) as count'))
                ->groupBy('rating')
                ->pluck('count', 'rating');

            if ($ratingCounts->isNotEmpty()) {
                $ratingsChartData = [
                    'labels' => [1, 2, 3, 4, 5],
                    'values' => [
                        (int)$ratingCounts->get(1, 0),
                        (int)$ratingCounts->get(2, 0),
                        (int)$ratingCounts->get(3, 0),
                        (int)$ratingCounts->get(4, 0),
                        (int)$ratingCounts->get(5, 0),
                    ],
                ];
            }

            $userCounts = Users::where(DB::raw('LOWER(role)'), 'user')
                ->whereYear('created_at', $date->year)
                ->whereMonth('created_at', $date->month)
                ->select('status', DB::raw('count(*) as count'))
                ->groupBy('status')
                ->pluck('count', 'status');

            if ($userCounts->isNotEmpty()) {
                $usersChartData = [
                    'labels' => $userCounts->keys()->map(fn($s) => ucfirst($s))->toArray(),
                    'values' => $userCounts->values()->map(fn($v) => (int)$v)->toArray(),
                ];
            }
        } catch (Exception $e) {
            Log::error('Dashboard Error: ' . $e->getMessage());
            $errorMessage = 'Error loading chart data.';
        }

        $feedbackCount = Feedbacks::whereYear('created_at', $date->year)
            ->whereMonth('created_at', $date->month)->count();

        $userCount = Users::where('role', 'user')
            ->whereYear('created_at', $date->year)
            ->whereMonth('created_at', $date->month)->count();

        return response()->view('admin.admin_generate_reports', compact(
            'user', 'ratingsChartData', 'usersChartData', 'notifications', 
            'unreadNotifications', 'selectedMonth', 'errorMessage', 'feedbackCount', 'userCount'
        ));
    }

    public function download(Request $request)
    {
        $user = Auth::guard('admin')->user();
        $reportData = $this->getReportData($request);

        if (!empty($reportData['errorMessage'])) {
            return redirect()->back()->with('error', $reportData['errorMessage']);
        }

        $date = Carbon::parse($reportData['selectedMonth'] . '-01');
        $fileName = 'Admin-Report-' . $date->format('F-Y') . '.pdf';

        // Force Laravel to use /tmp for PDF generation to avoid "Read-only file system"
        $pdf = Pdf::loadView('admin.admin_download_report', array_merge(['user' => $user], $reportData));
        $pdf->setPaper('a4', 'portrait');
        $pdf->setOptions([
            'isHtml5ParserEnabled' => true,
            'enable_gd' => false, // DISABLING GD COMPLETELY
        ]);

        return $pdf->download($fileName);
    }

    private function getReportData(Request $request): array
    {
        $selectedMonth = $request->input('month', Carbon::now()->format('Y-m'));
        $date = Carbon::parse($selectedMonth . '-01');

        try {
            $feedbackCount = Feedbacks::whereYear('created_at', $date->year)
                ->whereMonth('created_at', $date->month)->count();

            $userCount = Users::where('role', 'user')
                ->whereYear('created_at', $date->year)
                ->whereMonth('created_at', $date->month)->count();

            // Get the raw counts for the CSS chart
            $ratingCounts = Feedbacks::whereYear('created_at', $date->year)
                ->whereMonth('created_at', $date->month)
                ->select('rating', DB::raw('count(*) as count'))
                ->groupBy('rating')->pluck('count', 'rating')->toArray();

            // Ensure all ratings 1-5 exist in the array
            $chartData = [];
            $maxVal = 0;
            for ($i = 1; $i <= 5; $i++) {
                $count = $ratingCounts[$i] ?? 0;
                $chartData[$i] = $count;
                if ($count > $maxVal) $maxVal = $count;
            }

            return [
                'selectedMonth' => $selectedMonth,
                'feedbackCount' => $feedbackCount,
                'userCount' => $userCount,
                'chartData' => $chartData, // RAW NUMBERS
                'maxVal' => $maxVal > 0 ? $maxVal : 1, // Avoid division by zero
                'errorMessage' => null
            ];
        } catch (Exception $e) {
            return ['errorMessage' => 'Server Error: ' . $e->getMessage()];
        }
    }
}