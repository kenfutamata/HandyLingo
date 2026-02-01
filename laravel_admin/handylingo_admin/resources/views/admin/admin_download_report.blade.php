<!DOCTYPE html>
<html lang="en">

<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>Monthly Performance Report</title>
    <style>
        body {
            font-family: sans-serif;
            color: #334155;
            margin: 0;
            padding: 20px;
        }

        .header {
            margin-bottom: 30px;
            border-bottom: 2px solid #113882;
            padding-bottom: 10px;
        }

        .title {
            color: #113882;
            font-size: 28px;
            font-weight: bold;
            margin: 0;
        }

        .subtitle {
            font-size: 18px;
            color: #64748b;
            margin: 5px 0;
        }

        /* Table used for layout instead of Grid */
        .summary-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }

        .card {
            background: #ffffff;
            border: 1px solid #e2e8f0;
            padding: 20px;
            text-align: center;
            width: 45%;
        }

        .card-label {
            font-size: 12px;
            text-transform: uppercase;
            color: #94a3b8;
            font-weight: bold;
        }

        .card-value {
            font-size: 32px;
            font-weight: bold;
            color: #1e293b;
            margin: 10px 0;
        }

        .chart-section {
            margin-top: 40px;
            text-align: center;
        }

        .chart-title {
            font-size: 20px;
            font-weight: bold;
            margin-bottom: 15px;
            text-align: left;
        }

        .chart-img {
            width: 100%;
            max-width: 500px;
            border: 1px solid #eee;
        }

        .no-data {
            padding: 50px;
            text-align: center;
            border: 2px dashed #cbd5e1;
            color: #94a3b8;
        }
    </style>
</head>

<body>

    <div class="header">
        <h1 class="title">Monthly Performance Report</h1>
        <p class="subtitle">HandyLingo — {{ \Carbon\Carbon::parse($selectedMonth)->format('F Y') }}</p>
    </div>

    <h2 style="font-size: 20px;">Summary</h2>
    <table class="summary-table">
        <tr>
            <td class="card" style="margin-right: 10px;">
                <div class="card-label">Total Users (This Month)</div>
                <div class="card-value">{{ number_format($userCount) }}</div>
            </td>
            <td width="5%"></td> <!-- Spacer -->
            <td class="card">
                <div class="card-label">Feedback Received</div>
                <div class="card-value">{{ number_format($feedbackCount) }}</div>
            </td>
        </tr>
    </table>

    <div class="chart-section">
        <h2 class="chart-title">User Satisfaction</h2>
        @if($ratingsChartImageUrl)
        <div style="text-align: center; margin-top: 20px;">
            <!-- You MUST provide width and height attributes -->
            <img src="{{ $ratingsChartImageUrl }}" width="500" height="250" style="width: 500px; height: 250px;">
        </div>
        @else
        <div class="no-data">
            <p>No rating data available for this period.</p>
        </div>
        @endif
    </div>

</body>

</html>