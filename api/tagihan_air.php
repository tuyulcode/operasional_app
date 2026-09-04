<?php
require_once __DIR__ . '/config.php';

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';
$id = $_GET['id'] ?? null;

// Helpers
function format_tagihan_item($pdo, $t, $baseUrl) {
    $monthsId = [
        '01' => 'Januari', '02' => 'Februari', '03' => 'Maret', '04' => 'April',
        '05' => 'Mei', '06' => 'Juni', '07' => 'Juli', '08' => 'Agustus',
        '09' => 'September', '10' => 'Oktober', '11' => 'November', '12' => 'Desember'
    ];
    $dt = strtotime($t['periode']);
    $m = date('m', $dt);
    $y = date('Y', $dt);
    $periodeLabel = ($monthsId[$m] ?? '') . ' ' . $y;

    // Get fotos
    $stmt = $pdo->prepare("SELECT id, path_foto FROM tagihan_air_foto WHERE tagihan_air_id = ?");
    $stmt->execute([$t['id']]);
    $fotosRaw = $stmt->fetchAll();

    $wwwRoot = dirname(__DIR__, 2); // .../www (parent kedua)
    $laravelStorage = $wwwRoot . '/operasional/storage/app/public';

    // Base URL untuk serve_foto — gunakan absolute URL supaya
    // Flutter Image.network() bisa langsung load tanpa masalah CORS.
    // $baseUrl = http://localhost/operasional_app/api
    $serveBase = rtrim($baseUrl, '/') . '/tagihan_air.php?action=serve_foto&path=';

    $fotos = [];
    foreach ($fotosRaw as $f) {
        $path = $f['path_foto'];

        $laravelFile = $laravelStorage . '/' . $path;
        $url = null;
        $photoStatus = 'not_found';

        if (file_exists($laravelFile)) {
            // Gunakan relative URL supaya always same-origin.
            // Flutter Web akan resolve relative terhadap base URL API.
            $url = $serveBase . rawurlencode($path);
            $photoStatus = 'ok';
        } else {
            error_log("[tagihan_air] Foto tidak ditemukan di storage: path_foto={$path}, dicek di: {$laravelFile}");
        }

        $fotos[] = [
            'id' => (int)$f['id'],
            'url' => $url,
            'photo_status' => $photoStatus,
        ];
    }

    return [
        'id' => (int)$t['id'],
        'titik_meter_id' => (int)$t['titik_meter_id'],
        'titik_meter_nama' => $t['titik_meter_nama'] ?? '-',
        'area_id' => $t['area_id'] ? (int)$t['area_id'] : null,
        'area_nama' => $t['area_nama'] ?? '-',
        'lokasi_flow_meter' => $t['lokasi_flow_meter'] ?? null,
        'periode' => date('Y-m', $dt),
        'periode_label' => $periodeLabel,
        'meter_lalu' => (float)$t['meter_lalu'],
        'meter_ini' => (float)$t['meter_ini'],
        'meter_faktor' => (float)$t['meter_faktor'],
        'tarif' => (float)$t['tarif'],
        'pemakaian' => (float)$t['pemakaian'],
        'ppn_persentase' => (float)($t['ppn_persentase'] ?? 0),
        'ppn_nominal' => (float)($t['ppn_nominal'] ?? 0),
        'jumlah' => (float)$t['jumlah'],
        'fotos' => $fotos,
        'created_at' => $t['created_at'] ? date('c', strtotime($t['created_at'])) : null,
        'updated_at' => $t['updated_at'] ? date('c', strtotime($t['updated_at'])) : null,
    ];
}

$baseUrl = get_base_url();

// ── SERVE FOTO ────────────────────────────────────────────────────
// Melayani foto dari operasional/storage/app/public/ dengan CORS header.
// Flutter Web butuh foto served dari origin yang sama supaya tidak
// diblokir CORS. Dengan ini, URL foto = same-origin (api/tagihan_air.php).
if ($action === 'serve_foto' && $method === 'GET') {
    $path = $_GET['path'] ?? '';
    if ($path === '' || str_contains($path, '..')) {
        http_response_code(400);
        exit;
    }

    $wwwRoot = dirname(__DIR__, 2);
    $file = $wwwRoot . '/operasional/storage/app/public/' . $path;

    if (!file_exists($file) || !is_file($file)) {
        http_response_code(404);
        exit;
    }

    $ext = strtolower(pathinfo($file, PATHINFO_EXTENSION));
    $mimeMap = [
        'jpg'  => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'png'  => 'image/png',
        'gif'  => 'image/gif',
        'webp' => 'image/webp',
    ];
    $mime = $mimeMap[$ext] ?? 'application/octet-stream';

    header('Content-Type: ' . $mime);
    header('Cache-Control: public, max-age=86400');
    readfile($file);
    exit;
}

// ── GET ──
if ($method === 'GET') {
    if (!empty($id)) {
        $stmt = $pdo->prepare("
            SELECT ta.*, tm.nama as titik_meter_nama, tm.area_id, tm.lokasi_flow_meter, a.nama as area_nama
            FROM tagihan_air ta
            LEFT JOIN titik_meter tm ON ta.titik_meter_id = tm.id
            LEFT JOIN area a ON tm.area_id = a.id
            WHERE ta.id = ?
            LIMIT 1
        ");
        $stmt->execute([$id]);
        $row = $stmt->fetch();
        if (!$row) json_response(["message" => "Data tidak ditemukan"], 404);

        json_response(['data' => format_tagihan_item($pdo, $row, $baseUrl)]);
    }

    $where = [];
    $params = [];

    if (!empty($_GET['area_id'])) {
        $where[] = "tm.area_id = ?";
        $params[] = $_GET['area_id'];
    }

    if (!empty($_GET['bulan']) && preg_match('/^\d{4}-\d{2}$/', $_GET['bulan'])) {
        [$y, $m] = explode('-', $_GET['bulan']);
        $where[] = "YEAR(ta.periode) = ? AND MONTH(ta.periode) = ?";
        $params[] = $y;
        $params[] = $m;
    }

    if (!empty($_GET['search'])) {
        $where[] = "tm.nama LIKE ?";
        $params[] = "%" . $_GET['search'] . "%";
    }

    $sql = "
        SELECT ta.*, tm.nama as titik_meter_nama, tm.area_id, tm.lokasi_flow_meter, a.nama as area_nama
        FROM tagihan_air ta
        LEFT JOIN titik_meter tm ON ta.titik_meter_id = tm.id
        LEFT JOIN area a ON tm.area_id = a.id
    ";
    if (!empty($where)) {
        $sql .= " WHERE " . implode(" AND ", $where);
    }
    $sql .= " ORDER BY ta.periode DESC, ta.id DESC";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll();

    $data = array_map(fn($r) => format_tagihan_item($pdo, $r, $baseUrl), $rows);
    json_response(['data' => $data]);
}

// ── POST (STORE / UPDATE) ──
if ($method === 'POST') {
    $titik_meter_id = $_POST['titik_meter_id'] ?? null;
    $periode = $_POST['periode'] ?? null;
    $meter_ini = (float)($_POST['meter_ini'] ?? 0);
    $meter_faktor = (float)($_POST['meter_faktor'] ?? 1);
    $tarif = (float)($_POST['tarif'] ?? 0);
    $meter_lalu = isset($_POST['meter_lalu']) && $_POST['meter_lalu'] !== '' ? (float)$_POST['meter_lalu'] : null;

    if (!$titik_meter_id || !$periode) {
        json_response(["message" => "titik_meter_id dan periode wajib diisi."], 422);
    }

    $periodeDate = date('Y-m-01', strtotime($periode . '-01'));

    if ($meter_lalu === null) {
        // Find previous
        $prevStmt = $pdo->prepare("SELECT meter_ini FROM tagihan_air WHERE titik_meter_id = ? AND periode < ? ORDER BY periode DESC, id DESC LIMIT 1");
        $prevStmt->execute([$titik_meter_id, $periodeDate]);
        $prev = $prevStmt->fetch();
        if ($prev !== false && $prev['meter_ini'] !== null) {
            $meter_lalu = (float)$prev['meter_ini'];
        } else {
            json_response([
                "message" => "Belum ada histori periode sebelumnya. Isi meter_lalu secara manual.",
                "errors" => ["meter_lalu" => ["Wajib diisi."]]
            ], 422);
        }
    }

    $pemakaian = ($meter_ini - $meter_lalu) * $meter_faktor;
    $jumlahSebelumPpn = $pemakaian * $tarif;

    // ── PPN ──────────────────────────────────────────────────────
    // Samakan persis dengan formula di web (TagihanAirController):
    //   ppn_persentase = area.kena_ppn ? ppn_aktif.persentase : 0
    //   ppn_nominal     = round(jumlah_sebelum_ppn * ppn_persentase / 100, 2)
    //   jumlah          = jumlah_sebelum_ppn + ppn_nominal
    $areaStmt = $pdo->prepare("
        SELECT a.kena_ppn
        FROM titik_meter tm
        LEFT JOIN area a ON tm.area_id = a.id
        WHERE tm.id = ?
        LIMIT 1
    ");
    $areaStmt->execute([$titik_meter_id]);
    $areaRow = $areaStmt->fetch();
    $kenaPpn = $areaRow ? (bool)$areaRow['kena_ppn'] : false;

    $ppn_persentase = 0;
    if ($kenaPpn) {
        $ppnStmt = $pdo->query("SELECT persentase FROM ppn WHERE status = 'aktif' LIMIT 1");
        $ppnAktif = $ppnStmt->fetch();
        $ppn_persentase = $ppnAktif ? (float)$ppnAktif['persentase'] : 0;
    }
    $ppn_nominal = round($jumlahSebelumPpn * $ppn_persentase / 100, 2);
    $jumlah = $jumlahSebelumPpn + $ppn_nominal;

    $now = date('Y-m-d H:i:s');

    if (!empty($id)) {
        // UPDATE — mengubah data yang sudah ada, dipilih lewat ?id= eksplisit
        $updateStmt = $pdo->prepare("
            UPDATE tagihan_air 
            SET titik_meter_id = ?, periode = ?, meter_lalu = ?, meter_ini = ?, meter_faktor = ?, tarif = ?, pemakaian = ?, ppn_persentase = ?, ppn_nominal = ?, jumlah = ?, updated_at = ?
            WHERE id = ?
        ");
        $updateStmt->execute([$titik_meter_id, $periodeDate, $meter_lalu, $meter_ini, $meter_faktor, $tarif, $pemakaian, $ppn_persentase, $ppn_nominal, $jumlah, $now, $id]);
        $tagihanId = $id;
        $msg = "Tagihan air berhasil diperbarui.";
    } else {
        // INSERT — selalu membuat baris baru, meski titik meter & periode
        // sama dengan data yang sudah ada (satu meter boleh punya lebih
        // dari satu tagihan di bulan yang sama).
        $insertStmt = $pdo->prepare("
            INSERT INTO tagihan_air (titik_meter_id, periode, meter_lalu, meter_ini, meter_faktor, tarif, pemakaian, ppn_persentase, ppn_nominal, jumlah, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ");
        $insertStmt->execute([$titik_meter_id, $periodeDate, $meter_lalu, $meter_ini, $meter_faktor, $tarif, $pemakaian, $ppn_persentase, $ppn_nominal, $jumlah, $now, $now]);
        $tagihanId = $pdo->lastInsertId();
        $msg = "Tagihan air berhasil ditambahkan.";
    }

    // Handle Uploaded Fotos
    if (!empty($_FILES['foto_meter'])) {
        $apiDir = __DIR__;
        $wwwRoot = dirname($apiDir, 2);

        // Semua foto disimpan ke operasional/storage/app/public/foto-meter/
        // supaya bisa dilayani langsung via public/storage junction + CORS .htaccess
        $laravelStorageDir = $wwwRoot . '/operasional/storage/app/public/foto-meter/';

        // Pastikan Laravel storage directory tersedia
        if (!is_dir($laravelStorageDir)) {
            $laravelBase = $wwwRoot . '/operasional/storage/app/public';
            if (!is_dir($laravelBase)) {
                error_log("[tagihan_air] CRITICAL: Laravel storage base tidak ditemukan: {$laravelBase}. Upload dibatalkan.");
                json_response(["message" => "Server storage tidak tersedia. Hubungi admin."], 500);
            } else {
                if (!mkdir($laravelStorageDir, 0777, true)) {
                    error_log("[tagihan_air] CRITICAL: Gagal membuat folder Laravel storage: {$laravelStorageDir}. Upload dibatalkan.");
                    json_response(["message" => "Server storage tidak tersedia. Hubungi admin."], 500);
                }
            }
        }

        $files = $_FILES['foto_meter'];
        $count = is_array($files['name']) ? count($files['name']) : 1;

        for ($i = 0; $i < $count; $i++) {
            $tmpName = is_array($files['tmp_name']) ? $files['tmp_name'][$i] : $files['tmp_name'];
            $origName = is_array($files['name']) ? $files['name'][$i] : $files['name'];
            $error = is_array($files['error']) ? $files['error'][$i] : $files['error'];

            if ($error === UPLOAD_ERR_OK && is_uploaded_file($tmpName)) {
                $ext = pathinfo($origName, PATHINFO_EXTENSION) ?: 'jpg';
                $newFilename = uniqid('foto_') . '.' . $ext;
                $relPath = 'foto-meter/' . $newFilename;

                // Simpan langsung ke Laravel storage (satu lokasi saja)
                $destPath = $laravelStorageDir . $newFilename;
                if (!move_uploaded_file($tmpName, $destPath)) {
                    error_log("[tagihan_air] Gagal move_uploaded_file: {$tmpName} -> {$destPath}");
                    continue; // skip file ini, jangan insert ke DB
                }

                $fotoStmt = $pdo->prepare("INSERT INTO tagihan_air_foto (tagihan_air_id, path_foto, created_at, updated_at) VALUES (?, ?, ?, ?)");
                $fotoStmt->execute([$tagihanId, $relPath, $now, $now]);
            } elseif ($error !== UPLOAD_ERR_OK) {
                error_log("[tagihan_air] Upload error pada file ke-{$i}: error_code={$error}, origName={$origName}");
            }
        }
    }

    // Return saved object
    $stmt = $pdo->prepare("
        SELECT ta.*, tm.nama as titik_meter_nama, tm.area_id, tm.lokasi_flow_meter, a.nama as area_nama
        FROM tagihan_air ta
        LEFT JOIN titik_meter tm ON ta.titik_meter_id = tm.id
        LEFT JOIN area a ON tm.area_id = a.id
        WHERE ta.id = ?
        LIMIT 1
    ");
    $stmt->execute([$tagihanId]);
    $saved = $stmt->fetch();

    json_response([
        "message" => $msg,
        "data" => format_tagihan_item($pdo, $saved, $baseUrl)
    ], 201);
}

// ── DELETE ──
if ($method === 'DELETE') {
    if (!empty($id)) {
        // Delete fotos files & db
        $fStmt = $pdo->prepare("SELECT path_foto FROM tagihan_air_foto WHERE tagihan_air_id = ?");
        $fStmt->execute([$id]);
        $fotos = $fStmt->fetchAll();
        $wwwRoot = dirname(__DIR__, 2);
        $laravelStorageBase = $wwwRoot . '/operasional/storage/app/public';
        foreach ($fotos as $f) {
            $fp = $f['path_foto'];
            @unlink($laravelStorageBase . '/' . $fp);
        }
        $pdo->prepare("DELETE FROM tagihan_air_foto WHERE tagihan_air_id = ?")->execute([$id]);
        $pdo->prepare("DELETE FROM tagihan_air WHERE id = ?")->execute([$id]);

        json_response(["message" => "Tagihan air berhasil dihapus."]);
    }
    json_response(["message" => "ID tidak ditemukan."], 400);
}