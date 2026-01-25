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

class AdminGenerateReportsController extends Controller
{
    /**
     * Display a listing of the resource.
     */
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
            // 1. APPLICATION FEEDBACK DATA
            $ratingCounts = Feedbacks::query()
                ->select('rating', DB::raw('COUNT(*) as count'))
                ->whereYear('created_at', $date->year)
                ->whereMonth('created_at', $date->month)
                ->whereNotNull('rating')
                ->groupBy('rating')
                ->pluck('count', 'rating');

            if ($ratingCounts->isNotEmpty()) {
                $ratingsChartData = [
                    'labels' => [1, 2, 3, 4, 5],
                    'values' => [
                        (int) $ratingCounts->get(1, 0),
                        (int) $ratingCounts->get(2, 0),
                        (int) $ratingCounts->get(3, 0),
                        (int) $ratingCounts->get(4, 0),
                        (int) $ratingCounts->get(5, 0),
                    ],
                ];
            }

            // 2. USER REGISTRATION DATA 
            $userCounts = Users::query()
                ->select('status', DB::raw('COUNT(*) as count'))
                ->where(DB::raw('LOWER(role)'), 'user')
                ->whereYear('created_at', $date->year)
                ->whereMonth('created_at', $date->month)
                ->groupBy('status')
                ->pluck('count', 'status');

            if ($userCounts->isNotEmpty()) {
                $usersChartData = [
                    'labels' => $userCounts->keys()->map(fn($status) => ucfirst($status))->toArray(),
                    'values' => $userCounts->values()->map(fn($val) => (int)$val)->toArray(),
                ];
            }
        } catch (Exception $e) {
            Log::error('Chart data generation failed: ' . $e->getMessage());
            $errorMessage = 'The Server encountered an error while processing your report.';
        }

        $feedbackCount = Feedbacks::where('status', 'New')->count();
        $userCount = Users::where('role', 'user')->where('status', 'active')->count();

        return response()->view('admin.admin_generate_reports', compact(
            'user',
            'ratingsChartData',
            'usersChartData',
            'notifications',
            'unreadNotifications',
            'selectedMonth',
            'errorMessage',
            'feedbackCount',
            'userCount'
        ));
    }

    public function download(Request $request)
    {
        $user = Auth::guard('admin')->user();
        $reportData = $this->getReportData($request);

        if (!empty($reportData['errorMessage'])) {
            return redirect()->route('admin.generate.reports')->with('error', $reportData['errorMessage']);
        }

        $date = Carbon::parse($reportData['selectedMonth']);
        $fileName = 'Admin-Report-' . $date->format('F-Y') . '.pdf';

        // Configure PDF to allow remote images just in case, 
        // though Base64 is our primary fix here.
        $pdf = Pdf::loadView('admin.admin_download_report', array_merge(['user' => $user], $reportData))
            ->setPaper('a4', 'portrait')
            ->setOptions([
                'isRemoteEnabled' => true,
                'isHtml5ParserEnabled' => true,
            ]);

        return $pdf->download($fileName);
    }

    private function getReportData(Request $request): array
    {
        $selectedMonth = $request->input('month', Carbon::now()->format('Y-m'));
        $date = Carbon::parse($selectedMonth . '-01');

        $ratingsChartImageUrl = null;
        $errorMessage = null;

        try {
            // Summary Totals
            $feedbackCount = Feedbacks::whereYear('created_at', $date->year)
                ->whereMonth('created_at', $date->month)
                ->count();

            $userCount = Users::where('role', 'user')
                ->whereYear('created_at', $date->year)
                ->whereMonth('created_at', $date->month)
                ->count();

            // Ratings Data
            $ratingCounts = Feedbacks::whereYear('created_at', $date->year)
                ->whereMonth('created_at', $date->month)
                ->select('rating', DB::raw('count(*) as count'))
                ->groupBy('rating')
                ->pluck('count', 'rating');

            if ($ratingCounts->isNotEmpty()) {
                $vals = [
                    (int)$ratingCounts->get(1, 0),
                    (int)$ratingCounts->get(2, 0),
                    (int)$ratingCounts->get(3, 0),
                    (int)$ratingCounts->get(4, 0),
                    (int)$ratingCounts->get(5, 0)
                ];

                $chartConfig = [
                    'type' => 'bar',
                    'data' => [
                        'labels' => ['1 Star', '2 Star', '3 Star', '4 Star', '5 Star'],
                        'datasets' => [[
                            'label' => 'Reviews',
                            'data' => $vals,
                            'backgroundColor' => '#6366f1'
                        ]]
                    ],
                    'options' => [
                        'title' => ['display' => true, 'text' => 'User Satisfaction (Stars)']
                    ]
                ];

                $url = $this->makeQuickChartUrl($chartConfig);

                // --- FIX STARTS HERE: Convert URL to Base64 ---
                try {
                    $imageData = file_get_contents($url);
                    if ($imageData !== false) {
                        $base64 = base64_encode($imageData);
                        $ratingsChartImageUrl = 'data:image/png;base64,' . $base64;
                    }
                } catch (Exception $e) {
                    Log::error("Failed to fetch chart image: " . $e->getMessage());
                    // Fallback to URL if file_get_contents fails
                    $ratingsChartImageUrl = $url;
                }
                // --- FIX ENDS ---
            }

            return [
                'selectedMonth' => $selectedMonth,
                'feedbackCount' => $feedbackCount,
                'userCount' => $userCount,
                'ratingsChartImageUrl' => $ratingsChartImageUrl,
                'errorMessage' => null
            ];
        } catch (Exception $e) {
            return ['errorMessage' => 'Server Error: ' . $e->getMessage()];
        }
    }

    private function makeQuickChartUrl(array $config)
    {
        return 'https://quickchart.io/chart?c=' . urlencode(json_encode($config));
    }

    // ... keeping the rest of the empty resource methods (create, store, etc.)
    public function create() {}
    public function store(Request $request) {}
    public function show(string $id) {}
    public function edit(string $id) {}
    public function update(Request $request, string $id) {}
    public function destroy(string $id) {}
}
