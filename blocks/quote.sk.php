<?php

@$db = mysqli_connect("mariadb105.r1.websupport.sk", "polascinquotes", "Murianka7", "quotes", 3315);

$db->select_db("quotes");

$query = "SELECT quote, author, source, book, bookpage
						FROM sk";
$stmt = $db->prepare($query);
$stmt->execute();
$stmt->store_result();
$stmt->bind_result($quote, $author, $source, $book, $bookpage);

$max = $stmt->num_rows;
$min = 1;
$quote_number = rand($min, $max);

$record = $min;
while ($record <= $quote_number) {
	$stmt->fetch();
	$record++;
}

$data = $quote_number;
$url = "https://sk.polascin.net/refbook.sk.php?data=" . urlencode($data);

echo "<a href='$url' target='_self' title='Citát a odkaz na knihu'>";
echo "<div class='quotebox'>";
echo "<div class='quote'><cite>".$quote."</cite></div>";
echo "<div class='author'>".$author."</div>";
echo "<div class='source'>".$source."</div>";
echo "</div>";
echo "</a>";

$db->close();

?>
