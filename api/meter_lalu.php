<?php
require_once __DIR__ . '/config.php';

$titik_meter_id = $_GET['titik_meter_id'] ?? null;
$periode = $_GET['periode'] ?? null;

if (!$titik_meter_id || !$periode) {
    json_response(["message" => "titik_meter_id dan periode wajib diisi."], 422);
}

$periodeDate = date('Y-m-01', strtotime($periode . '-01'));

$stmt = $pdo->prepare("
    SELECT meter_ini 
    FROM tagihan_air 
    WHERE titik_meter_id = ? AND periode < ? 
    ORDER BY periode DESC 
    LIMIT 1
");
$stmt->execute([$titik_meter_id, $periodeDate]);
$row = $stmt->fetch();

if ($row !== false && $row['meter_ini'] !== null) {
    json_response([
        'meter_lalu' => (float)$row['meter_ini'],
        'auto_filled' => true
    ]);
} else {
    json_response([
        'meter_lalu' => null,
        'auto_filled' => false
    ]);
}
