<?php

/**
 * Pripojenie k databáze citátov pre sk.polascin.net.
 *
 * Prihlasovacie údaje sa načítavajú zo súboru `db.config.php`, ktorý nie je
 * súčasťou repozitára. Hľadá sa najprv mimo document root (bezpečnejšie),
 * potom priamo v koreňovom adresári webu.
 *
 * Vracia `null`, ak konfigurácia chýba alebo sa pripojenie nepodarí — volajúci
 * kód musí tento stav ošetriť a zobraziť náhradný obsah. Podrobnosti o chybe sa
 * zapisujú do chybového protokolu servera, nikdy sa nevypisujú návštevníkovi.
 */

declare(strict_types=1);

if (!function_exists('sk_db')) {

    function sk_db(): ?mysqli
    {
        static $db = null;
        static $attempted = false;

        if ($attempted) {
            return $db;
        }
        $attempted = true;

        $config = null;
        $candidates = [
            dirname(__DIR__, 2) . '/db.config.php', // mimo document root
            dirname(__DIR__) . '/db.config.php',    // koreň webu
        ];

        foreach ($candidates as $path) {
            if (is_readable($path)) {
                $loaded = require $path;
                if (is_array($loaded)) {
                    $config = $loaded;
                }
                break;
            }
        }

        if ($config === null) {
            error_log('sk.polascin.net: chýba alebo je neplatný súbor db.config.php');

            return null;
        }

        mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

        try {
            $connection = new mysqli(
                (string) $config['host'],
                (string) $config['user'],
                (string) $config['pass'],
                (string) $config['name'],
                (int) $config['port']
            );
            $connection->set_charset('utf8mb4');
            $db = $connection;
        } catch (Throwable $e) {
            error_log('sk.polascin.net: pripojenie k databáze zlyhalo: ' . $e->getMessage());
            $db = null;
        }

        return $db;
    }

}
