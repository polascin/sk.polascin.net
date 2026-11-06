<!DOCTYPE html>

<html lang="sk">


<head>

	<meta charset="utf-8">

  <?php require "./blocks/favicon.php"; ?>

  <meta name="date" content="<?php echo htmlspecialchars(date('c', (int) @filemtime(__FILE__)), ENT_QUOTES, 'UTF-8'); ?>">
	<meta name="description" content="MUDr. Ľubomír Polaščín, nefrológ a internista: slovenské webové sídlo, odborné texty o dialýze, transplantácii obličiek a nefrológii, kontakty a odkazy.">
  <meta name="copyright" content="Ľubomír Polaščín">
	<meta name="keywords" content="Ľubomír Polaščín,Ľubomír,Polaščín,nefrológ,internista,nefrológia,dialýza,interná medicína,medicína,vnútorné lekárstvo,lekárstvo">
  <meta name="publisher" content="Lubomir Polascin">
	<meta name="author" content="Ľubomír Polaščín" >
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="theme-color" content="#f5fffa">

  <title>Ľubomír Polaščín (webové sídlo)</title>

  <link rel="canonical" href="https://sk.polascin.net/">
  <link rel="alternate" hreflang="sk" href="https://sk.polascin.net/">
  <link rel="alternate" hreflang="x-default" href="https://sk.polascin.net/">
  <link rel="preload" as="image" href="/pix/lpsk2.jpg" fetchpriority="high">

  <meta property="og:type" content="website">
  <meta property="og:locale" content="sk_SK">
  <meta property="og:site_name" content="sk.polascin.net">
  <meta property="og:title" content="Ľubomír Polaščín (webové sídlo)">
  <meta property="og:description" content="MUDr. Ľubomír Polaščín, nefrológ a internista: odborné texty o dialýze, transplantácii obličiek a nefrológii.">
  <meta property="og:url" content="https://sk.polascin.net/">
  <meta property="og:image" content="https://sk.polascin.net/pix/lpsk2.jpg">
  <meta property="og:image:width" content="400">
  <meta property="og:image:height" content="400">
  <meta property="og:image:alt" content="Fotografia Ľubomíra Polaščína">
  <meta property="og:updated_time" content="<?php echo htmlspecialchars(date('c', (int) @filemtime(__FILE__)), ENT_QUOTES, 'UTF-8'); ?>">
  <meta name="twitter:card" content="summary">
  <meta name="twitter:title" content="Ľubomír Polaščín (webové sídlo)">
  <meta name="twitter:description" content="MUDr. Ľubomír Polaščín, nefrológ a internista: dialýza, transplantácia obličiek a nefrológia.">
  <meta name="twitter:image" content="https://sk.polascin.net/pix/lpsk2.jpg">
  <meta name="twitter:image:alt" content="Fotografia Ľubomíra Polaščína">

  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "WebSite",
        "@id": "https://sk.polascin.net/#website",
        "name": "sk.polascin.net",
        "url": "https://sk.polascin.net/",
        "inLanguage": "sk",
        "description": "MUDr. Ľubomír Polaščín, nefrológ a internista: slovenské webové sídlo, odborné texty o dialýze, transplantácii obličiek a nefrológii.",
        "publisher": { "@id": "https://sk.polascin.net/#person" }
      },
      {
        "@type": "WebPage",
        "@id": "https://sk.polascin.net/#webpage",
        "url": "https://sk.polascin.net/",
        "name": "Ľubomír Polaščín (webové sídlo)",
        "inLanguage": "sk",
        "dateModified": "<?php echo htmlspecialchars(gmdate('Y-m-d', (int) @filemtime(__FILE__)), ENT_QUOTES, 'UTF-8'); ?>",
        "isPartOf": { "@id": "https://sk.polascin.net/#website" },
        "about": { "@id": "https://sk.polascin.net/#person" },
        "mainEntity": { "@id": "https://sk.polascin.net/#person" }
      },
      {
        "@type": "Person",
        "@id": "https://sk.polascin.net/#person",
        "name": "Ľubomír Polaščín",
        "honorificPrefix": "MUDr.",
        "jobTitle": "Nefrológ a internista",
        "description": "MUDr. Ľubomír Polaščín, nefrológ a internista: odborné texty o dialýze, transplantácii obličiek a nefrológii.",
        "inLanguage": "sk",
        "url": "https://sk.polascin.net/",
        "image": "https://sk.polascin.net/pix/lpsk2.jpg",
        "email": "lubomir@polascin.net",
        "knowsAbout": ["Nefrológia", "Dialýza", "Transplantácia obličiek"],
        "sameAs": [
          "https://www.linkedin.com/in/lubomirpolascin/",
          "https://polascin.net/",
          "https://polascin.sk/",
          "https://nephrosite.polascin.net/",
          "https://books.polascin.net/"
        ]
      }
    ]
  }
  </script>

  <link rel="stylesheet" href="/styles.css?v=<?php echo (int) @filemtime(__DIR__ . '/styles.css'); ?>">

</head>


<body>

<a class="skip-link" href="#obsah">Preskočiť na obsah</a>

<hr>

<?php require "./blocks/intersection.sk.php"; ?>

<hr>

<main id="obsah" tabindex="-1" aria-label="Hlavný obsah">

<?php require "./blocks/current.sk.php"; ?>

<hr>

<?php require "./blocks/intro.sk.php"; ?>

<br>

<?php require "./blocks/pixbanner.php"; ?>

<br><br>

<?php require "./blocks/info.sk.php"; ?>

<hr>

<br><br><br><br>

<?php include "./blocks/promo.sk.php"; ?>

<br><br><br><br>

<?php include "./blocks/promotions.sk.php"; ?>

<br><br><br><br><br>

<?php require "./blocks/bio.sk.php"; ?>

<br>

<?php require "./blocks/pixbanner.php"; ?>

<br><br><br><br><br>

<?php include "./blocks/affiliate.sk.php"; ?>

</main>

<br><br>

<?php require "./blocks/footer.sk.php"; ?>

</body>


</html>
