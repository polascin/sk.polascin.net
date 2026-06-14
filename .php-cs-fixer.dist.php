<?php

declare(strict_types=1);

/**
 * Konfigurácia PHP-CS-Fixer.
 *
 * Zámerne KONZERVATÍVNA sada — len nízkorizikové pravidlá, aby sa pri prvom
 * spustení neprepísal celý existujúci kód. Po ustálení môžeš pridať '@PSR12'.
 *
 * Spustenie:
 *   php tools/php-cs-fixer.phar fix --dry-run --diff   (len ukáže zmeny)
 *   php tools/php-cs-fixer.phar fix                     (aplikuje zmeny)
 */

$finder = PhpCsFixer\Finder::create()
    ->in(__DIR__)
    ->exclude(['vendor', 'node_modules', 'tools']);

return (new PhpCsFixer\Config())
    ->setRiskyAllowed(false)
    ->setRules([
        'array_syntax' => ['syntax' => 'short'],
        'no_unused_imports' => true,
        'ordered_imports' => ['sort_algorithm' => 'alpha'],
        'no_trailing_whitespace' => true,
        'no_whitespace_in_blank_line' => true,
        'single_blank_line_at_eof' => true,
        'blank_line_after_opening_tag' => true,
        'trailing_comma_in_multiline' => true,
        'no_empty_statement' => true,
        'no_extra_blank_lines' => true,
    ])
    ->setFinder($finder);
