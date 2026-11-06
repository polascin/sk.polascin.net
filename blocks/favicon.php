<?php
$skFavDir = __DIR__ . '/../favicon';
$skIcoV = (int) @filemtime(__DIR__ . '/../favicon.ico');
$skAppleV = (int) @filemtime($skFavDir . '/apple-touch-icon.png');
$skIcon32V = (int) @filemtime($skFavDir . '/favicon-32x32.png');
$skIcon16V = (int) @filemtime($skFavDir . '/favicon-16x16.png');
$skManifestV = (int) @filemtime($skFavDir . '/site.webmanifest.php');
$skChrome192V = (int) @filemtime($skFavDir . '/android-chrome-192x192.png');
$skChrome512V = (int) @filemtime($skFavDir . '/android-chrome-512x512.png');
?>
<meta name="color-scheme" content="light">
<meta name="application-name" content="Ľubomír Polaščín">
<meta name="format-detection" content="telephone=no">
<meta name="msapplication-TileColor" content="#f5fffa">
<meta name="msapplication-TileImage" content="/favicon/android-chrome-192x192.png?v=<?= $skChrome192V ?>">
<meta name="msapplication-config" content="none">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-title" content="Polaščín">
<meta name="apple-mobile-web-app-status-bar-style" content="default">
<link rel="apple-touch-icon" sizes="180x180" href="/favicon/apple-touch-icon.png?v=<?= $skAppleV ?>">
<link rel="icon" type="image/png" sizes="32x32" href="/favicon/favicon-32x32.png?v=<?= $skIcon32V ?>">
<link rel="icon" type="image/png" sizes="16x16" href="/favicon/favicon-16x16.png?v=<?= $skIcon16V ?>">
<link rel="icon" type="image/png" sizes="192x192" href="/favicon/android-chrome-192x192.png?v=<?= $skChrome192V ?>">
<link rel="icon" type="image/png" sizes="512x512" href="/favicon/android-chrome-512x512.png?v=<?= $skChrome512V ?>">
<link rel="icon" href="/favicon.ico?v=<?= $skIcoV ?>" sizes="any">
<link rel="manifest" href="/favicon/site.webmanifest.php?v=<?= $skManifestV ?>">
