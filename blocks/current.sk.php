<div style="border: solid thin silver; display: inline-table; background-color: whitesmoke; padding-left: 1em; padding-right: 1em;">
	<a href="https://en.wikipedia.org/wiki/Swatch_Internet_Time" target="_blank" rel="noopener noreferrer">
		<span id="internettime" style="font-weight: bold; "></span>
	</a>
	<br>
	<a href="https://time.is/" target="_blank" rel="noopener noreferrer">
		<span>Deň:&nbsp;</span><span id="daynumber" style="font-weight: bold; "></span>
		<span>&nbsp;&nbsp;&nbsp;Rok:&nbsp;</span><span id="yearnumber" style="font-weight: bolder; "></span>
		<span>&nbsp;&nbsp;&nbsp;Týždeň:&nbsp;</span><span id="weeknumber" style="font-weight: bold; "></span>
		<span>&nbsp;&nbsp;&nbsp;Dnes je&nbsp;</span><span id="current" style="font-weight: bold; "></span>
		<br>
		<span style="font-style: italic; font-variant: small-caps; font-size: smaller;"><span>(</span><span id="timezone"></span><span>)</span></span>
	</a>
</div>

<script src="/js/current.js?v=<?php echo @filemtime(__DIR__ . '/../js/current.js'); ?>" defer></script>

