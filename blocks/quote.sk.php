<?php

declare(strict_types=1);

require_once __DIR__ . '/db.sk.php';

$db = sk_db();

if ($db === null) {
    echo "<div class='quotebox'><div class='source'>Citát momentálne nie je dostupný.</div></div>";

    return;
}

try {
    // Náhodný citát aj s jeho skutočným identifikátorom, aby odkaz na
    // refbook.sk.php smeroval na ten istý záznam, ktorý sa práve zobrazuje.
    $stmt = $db->prepare(
        'SELECT quote_id, quote, author, source
           FROM sk
       ORDER BY RAND()
          LIMIT 1'
    );
    $stmt->execute();
    $result = $stmt->get_result();
    $row = $result ? $result->fetch_assoc() : null;
    $stmt->close();
} catch (Throwable $exception) {
    error_log('sk.polascin.net: načítanie citátu zlyhalo: ' . $exception->getMessage());
    $row = null;
}

if ($row === null) {
    echo "<div class='quotebox'><div class='source'>Citát momentálne nie je dostupný.</div></div>";

    return;
}

$url = 'https://sk.polascin.net/refbook.sk.php?data=' . urlencode((string) $row['quote_id']);

$esc = static fn (mixed $value): string => htmlspecialchars((string) $value, ENT_QUOTES, 'UTF-8');

?>
<a href="<?= $esc($url) ?>" target="_self" title="Citát a odkaz na knihu">
	<div class="quotebox">
		<div class="quote"><cite><?= $esc($row['quote']) ?></cite></div>
		<div class="author"><?= $esc($row['author']) ?></div>
		<div class="source"><?= $esc($row['source']) ?></div>
	</div>
</a>
