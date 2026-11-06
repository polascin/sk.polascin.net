<?php
declare(strict_types=1);

/**
 * RFC 9116 security.txt.
 * Kanonická URL: /.well-known/security.txt (RewriteRule v .htaccess).
 * Fyzický remote adresár .well-known/ na Websupport OpenResty vracal 403,
 * preto sa telo posiela z tohto PHP (zhoda s .well-known/security.txt v gite).
 */
header('Content-Type: text/plain; charset=utf-8');
header('X-Robots-Tag: noindex');

echo "Contact: mailto:lubomir@polascin.net\n";
echo "Expires: 2027-11-06T00:00:00.000Z\n";
echo "Preferred-Languages: sk, en\n";
echo "Canonical: https://sk.polascin.net/.well-known/security.txt\n";
