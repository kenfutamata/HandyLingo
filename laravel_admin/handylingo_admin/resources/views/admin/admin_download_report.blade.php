<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: sans-serif; color: #334155; }
        .header { border-bottom: 2px solid #113882; padding-bottom: 10px; margin-bottom: 20px; }
        
        /* Summary Boxes */
        .summary-table { width: 100%; margin-bottom: 30px; }
        .card { border: 1px solid #e2e8f0; padding: 15px; text-align: center; width: 48%; }
        .card-label { font-size: 10px; color: #94a3b8; text-transform: uppercase; }
        .card-value { font-size: 24px; font-weight: bold; }

        /* CSS BAR CHART */
        .chart-container { margin-top: 30px; width: 100%; }
        .bar-row { margin-bottom: 10px; clear: both; height: 30px; }
        .bar-label { float: left; width: 40px; line-height: 30px; font-size: 14px; }
        .bar-track { float: left; width: 450px; background: #f1f5f9; height: 20px; margin-top: 5px; border-radius: 4px; }
        .bar-fill { height: 100%; background: #6366f1; border-radius: 4px; }
        .bar-count { float: left; margin-left: 10px; line-height: 30px; font-size: 14px; color: #64748b; }
    </style>
</head>
<body>

    <div class="header">
        <h1>Monthly Performance Report</h1>
        <p>HandyLingo — {{ \Carbon\Carbon::parse($selectedMonth)->format('F Y') }}</p>
    </div>

    <h3>Summary</h3>
    <table class="summary-table">
        <tr>
            <td class="card">
                <div class="card-label">Total Users</div>
                <div class="card-value">{{ $userCount }}</div>
            </td>
            <td width="4%"></td>
            <td class="card">
                <div class="card-label">Feedback Received</div>
                <div class="card-value">{{ $feedbackCount }}</div>
            </td>
        </tr>
    </table>

    <h3>User Satisfaction (Rating Distribution)</h3>
    <div class="chart-container">
        @foreach($chartData as $rating => $count)
            @php
                // Calculate width as percentage of the max value
                $width = ($count / $maxVal) * 100;
            @endphp
            <div class="bar-row">
                <div class="bar-label">{{ $rating }}</div>
                <div class="bar-track">
                    <div class="bar-fill" style="width: {{ $width }}%;"></div>
                </div>
                <div class="bar-count">{{ $count }} reviews</div>
            </div>
        @endforeach
    </div>

</body>
</html>