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
$quoteLang = '';
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
    // Only ISO-like codes belong in lang= / JSON-LD inLanguage (not free-text "slovenčina").
    // Map common country-code mistakes (cz/ua/…) to ISO 639-1 language codes.
    $rawLang = trim((string) ($record['lang'] ?? ''));
    if (preg_match('/^[a-z]{2}(?:-[A-Za-z0-9]{2,8})?$/i', $rawLang) === 1) {
        $quoteLang = strtolower($rawLang);
        $langAliases = [
            'cz' => 'cs',
            'ua' => 'uk',
            'gr' => 'el',
            'jp' => 'ja',
            'cn' => 'zh',
        ];
        $parts = explode('-', $quoteLang, 2);
        if (isset($langAliases[$parts[0]])) {
            $quoteLang = $langAliases[$parts[0]] . (isset($parts[1]) ? '-' . $parts[1] : '');
        }
    }
}

?>
<!DOCTYPE html>

<html lang="sk">


<head>

	<meta charset="utf-8">

  <?php require "./blocks/favicon.php"; ?>

  <meta name="date" content="2026-11-06T00:20:00+0100" >
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
<?php if (is_array($record) && is_int($quoteId)) {
    $quotationLd = [
        '@context' => 'https://schema.org',
        '@type' => 'Quotation',
        'text' => (string) ($record['quote'] ?? ''),
        'url' => 'https://sk.polascin.net/refbook.sk.php?data=' . $quoteId,
    ];
    $authorNameLd = trim((string) ($record['author'] ?? ''));
    if ($authorNameLd !== '') {
        $quotationLd['author'] = [
            '@type' => 'Person',
            'name' => $authorNameLd,
        ];
    }
    $bookTitleLd = trim((string) ($record['title'] ?? ''));
    if ($bookTitleLd !== '') {
        $bookLd = [
            '@type' => 'Book',
            'name' => $bookTitleLd,
        ];
        // Schema.org isbn: strip DB "ISBN " label; emit only valid ISBN-10/13.
        // Code-side only (DB row stays user-gated): if digits are 14 and the first
        // 13 pass the ISBN-13 check digit (doubled check digit typo, e.g.
        // 978-80-7370-542-88 → 978-80-7370-542-8), use the first 13.
        $isbnRaw = trim((string) preg_replace(
            '/^ISBN[\s:]*/i',
            '',
            trim((string) ($record['isbn'] ?? ''))
        ));
        $isbnDigits = strtoupper((string) preg_replace('/[^0-9Xx]/', '', $isbnRaw));
        $isbn13Check = static function (string $d): bool {
            if (preg_match('/^\d{13}$/', $d) !== 1) {
                return false;
            }
            $sum = 0;
            for ($i = 0; $i < 12; $i++) {
                $n = (int) $d[$i];
                $sum += ($i % 2 === 0) ? $n : $n * 3;
            }

            return ((10 - ($sum % 10)) % 10) === (int) $d[12];
        };
        $isbn10Check = static function (string $d): bool {
            if (preg_match('/^\d{9}[\dX]$/', $d) !== 1) {
                return false;
            }
            $sum = 0;
            for ($i = 0; $i < 9; $i++) {
                $sum += ((int) $d[$i]) * (10 - $i);
            }
            $check = (11 - ($sum % 11)) % 11;
            $expected = $check === 10 ? 'X' : (string) $check;

            return $d[9] === $expected;
        };
        if (strlen($isbnDigits) === 14 && $isbn13Check(substr($isbnDigits, 0, 13))) {
            $isbnDigits = substr($isbnDigits, 0, 13);
            // Keep hyphenation when trimming one trailing digit restores ISBN-13.
            if (preg_match('/\d$/', $isbnRaw) === 1) {
                $trimmed = substr($isbnRaw, 0, -1);
                if ((string) preg_replace('/[^0-9]/', '', $trimmed) === $isbnDigits) {
                    $isbnRaw = $trimmed;
                }
            }
        }
        $isbnLd = '';
        if (strlen($isbnDigits) === 13 && $isbn13Check($isbnDigits)) {
            $isbnLd = (str_contains($isbnRaw, '-')
                && (string) preg_replace('/[^0-9]/', '', $isbnRaw) === $isbnDigits)
                ? $isbnRaw
                : $isbnDigits;
        } elseif (strlen($isbnDigits) === 10 && $isbn10Check($isbnDigits)) {
            $isbnLd = $isbnDigits;
        }
        if ($isbnLd !== '') {
            $bookLd['isbn'] = $isbnLd;
        }
        if ($quoteLang !== '') {
            $bookLd['inLanguage'] = $quoteLang;
        }
        $quotationLd['isPartOf'] = $bookLd;
    }
    if ($quoteLang !== '') {
        $quotationLd['inLanguage'] = $quoteLang;
    }
    $quotationJson = json_encode(
        $quotationLd,
        JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS
    );
    if (is_string($quotationJson)) {
        echo "\n  <script type=\"application/ld+json\">" . $quotationJson . "</script>\n";
    }
} ?>

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
	<blockquote class="quotebox" style="display: block; width: auto; margin: 0; text-align: left;"<?= $quoteLang !== '' ? ' lang="' . $esc($quoteLang) . '"' : '' ?>>
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
