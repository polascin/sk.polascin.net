<?php
/**
 * Visible breadcrumb matching JSON-LD BreadcrumbList (Domov → current).
 * Caller sets $skBcCurrentLabel (plain text, no HTML).
 */
$skBcLabel = isset($skBcCurrentLabel) ? (string) $skBcCurrentLabel : '';
if ($skBcLabel === '') {
    return;
}
$skBcEsc = static function (string $value): string {
    return htmlspecialchars($value, ENT_QUOTES, 'UTF-8');
};
?>
<nav class="breadcrumb" aria-label="Navigačná cesta">
	<ol>
		<li><a href="/" title="Úvodná stránka">Domov</a></li>
		<li aria-hidden="true">/</li>
		<li aria-current="page"><?= $skBcEsc($skBcLabel) ?></li>
	</ol>
</nav>
