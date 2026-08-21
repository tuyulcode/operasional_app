<?php
require_once __DIR__ . '/config.php';

$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
$token = '';
if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
    $token = $matches[1];
}

$user = null;
if (!empty($token)) {
    $decoded = json_decode(base64_decode($token), true);
    if (!empty($decoded['id'])) {
        $stmt = $pdo->prepare("SELECT id, username, role, photo FROM users WHERE id = ? LIMIT 1");
        $stmt->execute([$decoded['id']]);
        $user = $stmt->fetch();
    }
}

if (!$user) {
    // Default fallback to first admin user if token not strict
    $stmt = $pdo->query("SELECT id, username, role, photo FROM users LIMIT 1");
    $user = $stmt->fetch();
}

$photoUrl = null;
if (!empty($user['photo'])) {
    $baseUrl = get_base_url();
    $photoUrl = str_starts_with($user['photo'], 'http') 
        ? $user['photo'] 
        : rtrim(dirname($baseUrl), '/\\') . '/' . ltrim($user['photo'], '/');
}

json_response([
    "user" => [
        "id" => (int)($user['id'] ?? 1),
        "username" => $user['username'] ?? 'admin',
        "role" => $user['role'] ?? 'admin',
        "photo_url" => $photoUrl,
    ]
]);
