<?php
require_once __DIR__ . '/config.php';

// Endpoint baca-saja: expose persentase PPN yang sedang aktif, dipakai
// mobile app untuk menghitung ESTIMASI PPN di layar input (step2/step3)
// sebelum data benar-benar disimpan. Perhitungan final & otoritatif tetap
// dilakukan di backend (tagihan_air.php) saat submit, supaya konsisten
// dengan web meski nilai di sini sempat stale karena caching di app.

$stmt = $pdo->query("SELECT persentase FROM ppn WHERE status = 'aktif' LIMIT 1");
$row = $stmt->fetch();

json_response([
    'data' => [
        'persentase' => $row ? (float)$row['persentase'] : 0,
    ],
]);