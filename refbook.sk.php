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

?>
<!DOCTYPE html>

<html lang="sk">


<head>

	<meta charset="utf-8">

  <?php require "./blocks/favicon.php"; ?>

  <meta name="date" content="2024-03-14T17:11:36+0100" >
	<meta name="description" content="Ľubomír Polaščín - kniha, z ktorej je citát, stránka v slovenskom jazyku">
  <meta name="copyright" content="Ľubomír Polaščín">
	<meta name="keywords" content="Ľubomír Polaščín,Ľubomír,Polaščín,polascin,lubomir,kniha,citát,citat,citácia,citacia">
  <meta name="publisher" content="Lubomir Polascin">
	<meta name="author" content="Ľubomír Polaščín" >
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <title>Kniha, z ktorej je citát (sk.polascin.net)</title>

  <?php require "./blocks/styles.sk.css.php"; ?>

</head>


<body>

<hr>

<?php require "./blocks/intersection.sk.php"; ?>

<hr>

<?php require "./blocks/current.sk.php"; ?>

<hr>

<br><br><br>

<?php require "./blocks/pixbanner.php"; ?>

<br><br>

<a href="https://sk.polascin.net/" target="_self" style="text-decoration: none; color: black;">

<div style="display: inline-table; border: solid thin grey; padding: 3em; background-color: ghostwhite; width: 80%;">

<?php if ($record === null) { ?>

	<div><em>Citát sa nenašiel.</em></div>
	<br>
	<div><em>Záznam s takýmto číslom neexistuje alebo momentálne nie je dostupný.</em></div>

<?php } else { ?>

	<div><em>Citát</em></div>
	<br>
	<div class="quote"><cite><?= $esc($record['quote']) ?></cite></div>
	<div class="author"><?= $esc($record['author']) ?></div>
	<div class="source"><?= $esc($record['source']) ?></div>
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

</a>

<br><br>

<?php require "./blocks/pixbanner.php"; ?>

<br><br><br><br>

<?php require "./blocks/footer.sk.php"; ?>

</body>


</html>
