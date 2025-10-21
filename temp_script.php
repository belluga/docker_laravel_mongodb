<?php
require 'laravel-app/vendor/autoload.php';
$tenant = \App\Models\Landlord\Tenant::query()->first();
if ($tenant) {
    $tenant->makeCurrent();
}
$hash = hash('sha256', 'integration-device');
$user = \App\Models\Tenants\AccountUser::query()->where('fingerprints.hash', $hash)->first();
if ($user) {
    echo $user->_id, "\n";
    var_export($user->fingerprints);
} else {
    echo "no user";
}
