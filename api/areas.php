<?php
require_once __DIR__ . '/config.php';

$stmt = $pdo->query("SELECT id, nama, alamat, kena_ppn FROM area ORDER BY nama ASC");
$areas = $stmt->fetchAll();

$data = array_map(function($a) {
    return [
        'id' => (int)$a['id'],
        'nama' => $a['nama'],
        'alamat' => $a['alamat'],
        'kena_ppn' => (bool)$a['kena_ppn']
    ];
}, $areas);

json_response(['data' => $data]);
