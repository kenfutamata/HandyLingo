<?php

namespace App\Http\Controllers;

use App\Models\Feedbacks;
use App\Models\Users;
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
        // 1. Corrected Variable names (using $user consistently)
        $user = Auth::guard('admin')->user();
        $notifications = $user->notifications ?? collect();
        $unreadNotifications = $user->unreadNotifications ?? collect();

        $selectedMonth = $request->input('month', Carbon::now()->format('Y-m'));
        $date = Carbon::parse($selectedMonth . '-01');

        $ratingsChartData = null;
        $usersChartData = null;
        $errorMessage = null;

        try {
            // 2. APPLICATION FEEDBACK DATA
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

            // 3. USER REGISTRATION DATA 
            // Filtering for 'user' role and grouping by 'status'
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

        return response()->view('admin.admin_generate_reports', compact(
            'user',
            'ratingsChartData',
            'usersChartData',
            'notifications',
            'unreadNotifications',
            'selectedMonth',
            'errorMessage'
        ));
    }
    private function getReportData(Request $request, bool $forPdf = false): array
    {
        $ratingsChartData = null;
        $trendsChartData = null;
        $errorMessage = null;
        $selectedMonth = $request->input('month', Carbon::now()->format('Y-m'));
        $ratingChartImageUrl = null;
        $trendsChartImageUrl = null;

        try {
            $date = Carbon::parse($selectedMonth . '-01');
            $ratingCounts = Feedbacks::query()
                ->select('rating', DB::raw('COUNT(*) as count'))
                ->whereYear('created_at', $date->year)
                ->whereMonth('created_at', $date->month)
                ->whereNotNull('rating')
                ->groupBy('rating')
                ->pluck('count', 'rating');
            if ($ratingCounts->isNotEmpty()) {
                $ratingsChartData = [
                    'values' => [
                        (int) $ratingCounts->get(1, 0), // Count for ★ 1
                        (int) $ratingCounts->get(2, 0), // Count for ★ 2
                        (int) $ratingCounts->get(3, 0), // Count for ★ 3
                        (int) $ratingCounts->get(4, 0), // Count for ★ 4
                        (int) $ratingCounts->get(5, 0), // Count for ★ 5
                    ],
                ];

                // 3. Generate the QuickChart URL
                $ratingsChartImageUrl = $this->makeQuickChartUrl([
                    'type' => 'bar',
                    'data' => [
                        'labels' => ['★ 1', '★ 2', '★ 3', '★ 4', '★ 5'],
                        'datasets' => [[
                            'label' => 'Number of Reviews',
                            'data' => $ratingsChartData['values'],
                            'backgroundColor' => 'rgba(54, 162, 235, 0.6)', // Light Blue
                            'borderColor' => 'rgb(54, 162, 235)',
                            'borderWidth' => 1
                        ]]
                    ],
                    'options' => [
                        'legend' => ['display' => false],
                        'title' => [
                            'display' => true,
                            'text' => 'Overall User Ratings'
                        ],
                        'scales' => [
                            'yAxes' => [[
                                'ticks' => [
                                    'beginAtZero' => true,
                                    'stepSize' => 1,
                                    'precision' => 0 // Ensures no decimal points on the Y-axis
                                ]
                            ]]
                        ]
                    ]
                ]);
            }

            $userCounts = Users::query()
                ->select('role', DB::raw('COUNT(*) as count'))
                ->whereYear('created_at', $date->year)
                ->whereMonth('created_at', $date->month)
                ->groupBy('role')
                ->pluck('count', 'role');

            if ($userCounts->isNotEmpty()) {
                $usersChartData = [
                    // Capitalize roles for better display (e.g., "Admin", "User")
                    'labels' => $userCounts->keys()->map(fn($role) => ucfirst($role))->toArray(),
                    'values' => $userCounts->values()->toArray(),
                ];
            }
        } catch (Exception $e) {
            Log::error('Chart data generation failed: ' . $e->getMessage());
            $errorMessage = 'The Server encountered an error while processing your report.';
        }
        return [
            'ratingsChartData' => $ratingsChartData,
            'errorMessage' => $errorMessage,
            'ratingsChartImageUrl' => $ratingChartImageUrl,
            'selectedMont' => $selectedMonth
        ];
    }

    private function makeQuickChartUrl(array $config)
    {
        return 'https://quickchart.io/chart?c=' . urlencode(json_encode($config));
    }

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
