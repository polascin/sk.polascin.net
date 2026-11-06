<?php
declare(strict_types=1);

$dir = __DIR__;
$v192 = (int) @filemtime($dir . '/android-chrome-192x192.png');
$v512 = (int) @filemtime($dir . '/android-chrome-512x512.png');

header('Content-Type: application/manifest+json; charset=utf-8');
header('Cache-Control: public, max-age=86400, must-revalidate');

$manifest = [
    'name' => 'Ľubomír Polaščín',
    'short_name' => 'Polaščín',
    'description' => 'Webové sídlo MUDr. Ľubomíra Polaščína, nefrológa a internistu.',
    'lang' => 'sk',
    'start_url' => '/',
    'id' => '/',
    'scope' => '/',
    'icons' => [
        [
            'src' => '/favicon/android-chrome-192x192.png?v=' . $v192,
            'sizes' => '192x192',
            'type' => 'image/png',
            'purpose' => 'any',
        ],
        [
            'src' => '/favicon/android-chrome-512x512.png?v=' . $v512,
            'sizes' => '512x512',
            'type' => 'image/png',
            'purpose' => 'any',
        ],
    ],
    'theme_color' => '#f5fffa',
    'background_color' => '#f5fffa',
    'display' => 'standalone',
];

echo json_encode($manifest, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT), "\n";
