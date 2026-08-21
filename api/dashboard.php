<?php
require_once __DIR__ . '/config.php';

$year = date('Y');
$month = date('m');

// Total tagihan bulan ini
$stmt = $pdo->prepare("SELECT COALESCE(SUM(jumlah), 0) as total FROM tagihan_air WHERE YEAR(periode) = ? AND MONTH(periode) = ?");
$stmt->execute([$year, $month]);
$totalTagihan = (float)$stmt->fetch()['total'];

// Total pemakaian bulan ini
$stmt = $pdo->prepare("SELECT COALESCE(SUM(pemakaian), 0) as total FROM tagihan_air WHERE YEAR(periode) = ? AND MONTH(periode) = ?");
$stmt->execute([$year, $month]);
$totalPemakaian = (float)$stmt->fetch()['total'];

// Total area
$stmt = $pdo->query("SELECT COUNT(*) as total FROM area");
$totalArea = (int)$stmt->fetch()['total'];

// Total titik meter aktif
$stmt = $pdo->query("SELECT COUNT(*) as total FROM titik_meter WHERE status = 'aktif'");
$totalTitikMeter = (int)$stmt->fetch()['total'];

// Progress input bulan berjalan
$stmt = $pdo->prepare("
    SELECT COUNT(DISTINCT ta.titik_meter_id) as total 
    FROM tagihan_air ta 
    JOIN titik_meter tm ON ta.titik_meter_id = tm.id 
    WHERE tm.status = 'aktif' AND YEAR(ta.periode) = ? AND MONTH(ta.periode) = ?
");
$stmt->execute([$year, $month]);
$sudahInput = (int)$stmt->fetch()['total'];

$persen = $totalTitikMeter > 0 ? round(($sudahInput / $totalTitikMeter) * 100) : 0;

// Aktivitas terakhir
$stmt = $pdo->query("
    SELECT ta.id, ta.periode, ta.jumlah, ta.updated_at, tm.nama as titik_meter, a.nama as area 
    FROM tagihan_air ta 
    LEFT JOIN titik_meter tm ON ta.titik_meter_id = tm.id 
    LEFT JOIN area a ON tm.area_id = a.id 
    ORDER BY ta.updated_at DESC 
    LIMIT 5
");
$recent = $stmt->fetchAll();

$monthsId = [
    '01' => 'Januari', '02' => 'Februari', '03' => 'Maret', '04' => 'April',
    '05' => 'Mei', '06' => 'Juni', '07' => 'Juli', '08' => 'Agustus',
    '09' => 'September', '10' => 'Oktober', '11' => 'November', '12' => 'Desember'
];
$periodeLabel = ($monthsId[$month] ?? '') . ' ' . $year;

$aktivitas = array_map(function($r) {
    return [
        'id' => (int)$r['id'],
        'titik_meter' => $r['titik_meter'] ?? '-',
        'area' => $r['area'] ?? '-',
        'periode' => date('Y-m', strtotime($r['periode'])),
        'jumlah' => (float)$r['jumlah'],
        'status' => 'Selesai',
        'updated_at' => $r['updated_at'] ? date('c', strtotime($r['updated_at'])) : date('c')
    ];
}, $recent);

json_response([
    'total_tagihan' => $totalTagihan,
    'total_pemakaian' => $totalPemakaian,
    'total_area' => $totalArea,
    'total_titik_meter' => $totalTitikMeter,
    'progress' => [
        'sudah_input' => $sudahInput,
        'total_target' => $totalTitikMeter,
        'persen' => $persen
    ],
    'periode_label' => $periodeLabel,
    'aktivitas_terakhir' => $aktivitas
]);
