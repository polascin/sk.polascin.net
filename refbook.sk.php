<?php

declare(strict_types=1);

require_once __DIR__ . '/blocks/db.sk.php';

// Vstup z URL musí byť kladné celé číslo; čokoľvek iné sa zahodí.
$quoteId = filter_input(
    INPUT_GET,
    'data',
    FILTER_VALIDATE_INT,
    ['options' => ['min_range' => 1]]
);

$record = null;

if ($quoteId !== false && $quoteId !== null) {
    $db = sk_db();

    if ($db !== null) {
        try {
            $stmt = $db->prepare(
                'SELECT sk.quote_id, sk.quote, sk.author, sk.source, sk.bookpage,
                        books.title, books.authors, books.lang, books.translation,
                        books.copyright, books.edition, books.notation, books.isbn
                   FROM sk
              LEFT JOIN books ON sk.book = books.book_id
                  WHERE sk.quote_id = ?
                  LIMIT 1'
            );
            $stmt->bind_param('i', $quoteId);
            $stmt->execute();
            $result = $stmt->get_result();
            $record = $result ? $result->fetch_assoc() : null;
            $stmt->close();
        } catch (Throwable $exception) {
            error_log('sk.polascin.net: načítanie záznamu zlyhalo: ' . $exception->getMessage());
            $record = null;
        }
    }
}

if ($record === null) {
    http_response_code(404);
}

$esc = static fn (mixed $value): string => htmlspecialchars((string) $value, ENT_QUOTES, 'UTF-8');

/**
 * Bibliografické polia (preklad, copyright, vydanie, tiráž) majú v databáze
 * uložené jednoduché formátovanie. Ponecháme len bezpečné značky a zo všetkých
 * odstránime atribúty, takže sa nedá prepašovať `onclick`, `javascript:` a pod.
 * Značky `<a>` sa odstránia, ich text (spravidla adresa webu) zostane viditeľný.
 */
$richText = static function (mixed $value): string {
    $allowed = strip_tags((string) $value, '<em><i><strong><b><br>');

    return preg_replace('#<\s*(/?)\s*(em|i|strong|b|br)\b[^>]*>#i', '<$1$2>', $allowed) ?? '';
};

$pageTitle = 'Kniha, z ktorej je citát (sk.polascin.net)';
$pageDescription = 'Ľubomír Polaščín: kniha, z ktorej je citát, stránka v slovenskom jazyku.';
if (is_array($record)) {
    $authorName = trim((string) ($record['author'] ?? ''));
    $quoteText = preg_replace('/\s+/u', ' ', trim((string) ($record['quote'] ?? ''))) ?? '';
    $snippet = function_exists('mb_substr')
        ? mb_substr($quoteText, 0, 90, 'UTF-8')
        : substr($quoteText, 0, 90);
    if ($snippet !== $quoteText) {
        $snippet .= '…';
    }
    if ($snippet !== '') {
        $pageTitle = ($authorName !== '' ? $authorName . ': ' : 'Citát: ') . $snippet;
    }
    $pageDescription = $authorName !== ''
        ? 'Citát od autora ' . $authorName . ' a bibliografický odkaz na knihu (sk.polascin.net).'
        : 'Citát a bibliografický odkaz na knihu (sk.polascin.net).';
}

?>
<!DOCTYPE html>

<html lang="sk">


<head>

	<meta charset="utf-8">

  <?php require "./blocks/favicon.php"; ?>

  <meta name="date" content="2026-11-05T23:55:00+0100" >
	<meta name="description" content="<?= $esc($pageDescription) ?>">
  <meta name="copyright" content="Ľubomír Polaščín">
	<meta name="keywords" content="Ľubomír Polaščín,Ľubomír,Polaščín,polascin,lubomir,kniha,citát,citat,citácia,citacia">
  <meta name="publisher" content="Lubomir Polascin">
	<meta name="author" content="Ľubomír Polaščín" >
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="theme-color" content="#f5fffa">
  <meta name="robots" content="noindex, follow">

  <title><?= $esc($pageTitle) ?></title>
<?php if (is_array($record) && is_int($quoteId)) { ?>
  <link rel="canonical" href="https://sk.polascin.net/refbook.sk.php?data=<?= $quoteId ?>">
<?php } ?>

  <meta property="og:type" content="website">
  <meta property="og:locale" content="sk_SK">
  <meta property="og:site_name" content="sk.polascin.net">
  <meta property="og:title" content="<?= $esc($pageTitle) ?>">
  <meta property="og:description" content="<?= $esc($pageDescription) ?>">
<?php if (is_array($record) && is_int($quoteId)) { ?>
  <meta property="og:url" content="https://sk.polascin.net/refbook.sk.php?data=<?= $quoteId ?>">
<?php } ?>
  <meta property="og:image" content="https://sk.polascin.net/pix/lpsk2.jpg">
  <meta property="og:image:width" content="400">
  <meta property="og:image:height" content="400">
  <meta property="og:image:alt" content="Fotografia Ľubomíra Polaščína">
  <meta name="twitter:card" content="summary">
  <meta name="twitter:title" content="<?= $esc($pageTitle) ?>">
  <meta name="twitter:description" content="<?= $esc($pageDescription) ?>">
  <meta name="twitter:image" content="https://sk.polascin.net/pix/lpsk2.jpg">
  <meta name="twitter:image:alt" content="Fotografia Ľubomíra Polaščína">

  <link rel="stylesheet" href="/styles.css?v=<?php echo (int) @filemtime(__DIR__ . '/styles.css'); ?>">

</head>


<body>

<a class="skip-link" href="#obsah">Preskočiť na obsah</a>

<hr>

<?php require "./blocks/intersection.sk.php"; ?>

<hr>

<main id="obsah" tabindex="-1">

<?php require "./blocks/current.sk.php"; ?>

<hr>

<br><br><br>

<?php require "./blocks/pixbanner.php"; ?>

<br><br>

<div class="refbook-card" style="display: inline-table; border: solid thin grey; padding: 3em; background-color: ghostwhite; width: 80%; text-align: left;">

<?php if ($record === null) { ?>

	<div><em>Citát sa nenašiel.</em></div>
	<br>
	<div><em>Záznam s takýmto číslom neexistuje alebo momentálne nie je dostupný.</em></div>

<?php } else { ?>

	<div><em>Citát</em></div>
	<br>
	<blockquote class="quotebox" style="display: block; width: auto; margin: 0; text-align: left;">
		<p class="quote" style="margin: 0;"><?= $esc($record['quote']) ?></p>
		<footer>
			<div class="author"><?= $esc($record['author']) ?></div>
			<div class="source"><cite><?= $esc($record['source']) ?></cite></div>
		</footer>
	</blockquote>
	<br>

	<?php if ($record['title'] !== null) { ?>

		<div>
			<em>Našiel som na strane <strong><?= $esc($record['bookpage']) ?></strong> v knihe</em>
		</div>
		<br>
		<h1><cite><?= $esc($record['title']) ?></cite></h1>
		<h2><?= $esc($record['authors']) ?></h2>
		<div>Jazyk textu knihy: <?= $esc($record['lang']) ?></div>
		<div><?= $richText($record['translation']) ?></div>
		<div><?= $richText($record['copyright']) ?></div>
		<div><?= $richText($record['edition']) ?></div>
		<div><?= $richText($record['notation']) ?></div>
		<div><?= $esc($record['isbn']) ?></div>

	<?php } else { ?>

		<div>
			<em>
				Neviem, kde som našiel.
				<br>
				K citátu nie je priradená žiadna kniha ani iný zdroj, kde by som ten citát našiel.
			</em>
		</div>

	<?php } ?>

<?php } ?>

</div>

<p style="margin-top: 1.5em;">
	<a href="/" target="_self" title="Späť na úvodnú stránku sk.polascin.net">Späť na úvod</a>
</p>

<br><br>

</main>

<?php require "./blocks/footer.sk.php"; ?>

</body>


</html>
