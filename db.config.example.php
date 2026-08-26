<?php

/**
 * Vzor konfigurácie databázy pre sk.polascin.net.
 *
 * Skopírujte tento súbor ako `db.config.php` a doplňte skutočné údaje:
 *
 *     cp db.config.example.php db.config.php
 *
 * `db.config.php` je uvedený v .gitignore a NIKDY sa nesmie dostať do repozitára.
 * Ak to hosting umožňuje, umiestnite ho radšej o úroveň vyššie, mimo document root
 * — načítavací skript `blocks/db.sk.php` hľadá súbor najprv tam.
 */

declare(strict_types=1);

return [
    'host' => 'mariadb105.r1.websupport.sk',
    'user' => 'polascinquotes',
    'pass' => 'ZMENTE_MA',
    'name' => 'quotes',
    'port' => 3315,
];
