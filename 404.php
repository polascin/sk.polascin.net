<?php
declare(strict_types=1);

// Vždy 404: aj pri priamom /404.php, aj cez ErrorDocument.
http_response_code(404);
header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>

<html lang="sk">


<head>

	<meta charset="utf-8">

  <?php require "./blocks/favicon.php"; ?>

  <meta name="description" content="Požadovaná stránka na sk.polascin.net neexistuje.">
  <meta name="copyright" content="Ľubomír Polaščín">
  <meta name="publisher" content="Lubomir Polascin">
	<meta name="author" content="Ľubomír Polaščín">
  <meta name="robots" content="noindex, follow">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="theme-color" content="#f5fffa">

  <title>Stránka sa nenašla (sk.polascin.net)</title>

  <meta property="og:type" content="website">
  <meta property="og:locale" content="sk_SK">
  <meta property="og:site_name" content="sk.polascin.net">
  <meta property="og:title" content="Stránka sa nenašla (sk.polascin.net)">
  <meta property="og:description" content="Požadovaná stránka na sk.polascin.net neexistuje.">
  <meta property="og:image" content="https://sk.polascin.net/pix/lpsk2.jpg">
  <meta property="og:image:type" content="image/jpeg">
  <meta property="og:image:width" content="400">
  <meta property="og:image:height" content="400">
  <meta property="og:image:alt" content="Fotografia Ľubomíra Polaščína">
  <meta name="twitter:card" content="summary">
  <meta name="twitter:title" content="Stránka sa nenašla (sk.polascin.net)">
  <meta name="twitter:description" content="Požadovaná stránka na sk.polascin.net neexistuje.">
  <meta name="twitter:image" content="https://sk.polascin.net/pix/lpsk2.jpg">
  <meta name="twitter:image:alt" content="Fotografia Ľubomíra Polaščína">

  <link rel="stylesheet" href="/styles.css?v=<?php echo (int) @filemtime(__DIR__ . '/styles.css'); ?>">

</head>


<body>

<a class="skip-link" href="#obsah">Preskočiť na obsah</a>

<hr>

<?php require "./blocks/intersection.sk.php"; ?>

<hr>

<br>

<main id="obsah" class="info legal" tabindex="-1" aria-label="Hlavný obsah">

	<h1>Stránka sa nenašla</h1>

	<p>
		Požadovaná adresa na tomto webovom sídle neexistuje alebo už nie je dostupná.
	</p>

	<p>
		<a href="/" target="_self" title="Úvodná stránka sk.polascin.net">Späť na úvodnú stránku</a>
	</p>

</main>

<br>

<?php require "./blocks/footer.sk.php"; ?>

</body>


</html>
