<?php
require_once __DIR__ . '/config.php';

$area_id = $_GET['area_id'] ?? null;

if (!empty($area_id)) {
    $stmt = $pdo->prepare("
        SELECT tm.*, a.nama AS area_nama 
        FROM titik_meter tm 
        LEFT JOIN area a ON tm.area_id = a.id 
        WHERE tm.status = 'aktif' AND tm.area_id = ? 
        ORDER BY tm.nama ASC
    ");
    $stmt->execute([$area_id]);
} else {
    $stmt = $pdo->query("
        SELECT tm.*, a.nama AS area_nama 
        FROM titik_meter tm 
        LEFT JOIN area a ON tm.area_id = a.id 
        WHERE tm.status = 'aktif' 
        ORDER BY tm.nama ASC
    ");
}

$rows = $stmt->fetchAll();
$data = array_map(function($tm) {
    return [
        'id' => (int)$tm['id'],
        'area_id' => (int)$tm['area_id'],
        'nama' => $tm['nama'],
        'lokasi_flow_meter' => $tm['lokasi_flow_meter'] ?? null,
        'meter_faktor' => (float)$tm['meter_faktor'],
        'tarif_harga' => (float)$tm['tarif_harga'],
        'status' => $tm['status'],
        'area_nama' => $tm['area_nama'] ?? '-'
    ];
}, $rows);

json_response(['data' => $data]);
