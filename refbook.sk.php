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



<?php

$data = $_GET["data"];
$quote_number = $data;

@$db = mysqli_connect("mariadb105.r1.websupport.sk", "polascinquotes", "Murianka7", "quotes", 3315);

$db->select_db("quotes");

$query = "SELECT sk.quote_id, sk.quote, sk.author, sk.source, sk.book, sk.bookpage, books.book_id, books.title, books.authors, books.lang, books.translation, books.copyright, books.edition, books.notation, books.isbn
						FROM sk, books
						WHERE sk.quote_id = $quote_number AND sk.book = books.book_id";

$stmt = $db->prepare($query);
$stmt->execute();
$stmt->store_result();
$stmt->bind_result($quote_id, $quote, $author, $source, $book, $bookpage, $book_id, $title, $authors, $lang, $translation, $copyright, $edition, $notation, $isbn);

$stmt->fetch();

echo '';
echo "<div><em>Citát</em></div>";
echo "<br>";
echo "<div class='quote'><cite>".$quote."</cite></div>";
echo "<div class='author'>".$author."</div>";
echo "<div class='source'>".$source."</div>";
echo "<br>";
if ($book) {
	echo "<div><em>Som našiel na strane <strong>".$bookpage."</strong> v knihe</em></div>";
	echo "<br>";
	echo "<h1><cite>".$title."</cite></h1>";
	echo "<h2>".$authors."</h2>";
	echo "<div>Jazyk textu knihy: ".$lang."</div>";
	echo "<div>".$translation."</div>";
	echo "<div>".$copyright."</div>";
	echo "<div>".$edition."</div>";
	echo "<div>".$notation."</div>";
	echo "<div>".$isbn."</div>";
} else {
	echo "<div><em>Neviem, kde som našiel. <br>K citátu nie je priradená žiadna kniha ani iný zdroj, kde by som ten citát našiel.</em></div>";
}
echo '';

$db->close();

?>



</div>

</a>

<br><br>

<?php require "./blocks/pixbanner.php"; ?>

<br><br><br><br>

<?php require "./blocks/footer.sk.php"; ?>

</body>


</html>
