<?php
declare(strict_types=1);

/**
 * RFC 9116 security.txt.
 * Kanonická URL: /.well-known/security.txt (RewriteRule v .htaccess).
 * Fyzický remote adresár .well-known/ na Websupport OpenResty vracal 403,
 * preto sa telo posiela z tohto PHP. Jediný zdroj textu: .well-known/security.txt.
 */
$path = __DIR__ . '/.well-known/security.txt';
if (!is_readable($path)) {
    http_response_code(500);
    header('Content-Type: text/plain; charset=utf-8');
    echo "security.txt source missing\n";
    exit;
}

$body = file_get_contents($path);
if ($body === false) {
    http_response_code(500);
    header('Content-Type: text/plain; charset=utf-8');
    echo "security.txt unreadable\n";
    exit;
}

header('Content-Type: text/plain; charset=utf-8');
header('X-Robots-Tag: noindex');
echo $body;
