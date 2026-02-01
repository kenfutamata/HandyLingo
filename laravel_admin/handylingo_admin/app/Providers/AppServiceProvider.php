<?php

namespace App\Providers;

use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;
use Kreait\Firebase\Factory;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        // $this->app->singleton(FirebaseFirestore::class, function ($app) {
        //     $projectId = 'handylingoai';
        //     $fileName = 'handylingoai-firebase-adminsdk-fbsvc-c1283b6cd0.json';
        //     $credentialsPath = storage_path('app/' . $fileName);

        //     if (!file_exists($credentialsPath)) {
        //         throw new \Exception("Firebase JSON file missing at: " . $credentialsPath);
        //     }

        //     // We MUST return the result of the entire chain.
        //     // If you call withFirestoreClientConfig on a separate line 
        //     // without assigning it back to $factory, it does nothing.
        //     return (new Factory)
        //         ->withServiceAccount($credentialsPath)
        //         ->withFirestoreClientConfig([
        //             'projectId' => $projectId,
        //             'transport' => 'rest',
        //         ])
        //         ->createFirestore();
        // });

        if (config('app.env') === 'production' && isset($_SERVER['VERCEL_URL'])) {
            $this->app->useStoragePath('/tmp');
        }
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Global fallback
        if (env('APP_ENV') !== 'local') {
            URL::forceScheme('https');
        }
        putenv('GOOGLE_CLOUD_PHP_FIRESTORE_REST=true');
    }
}
