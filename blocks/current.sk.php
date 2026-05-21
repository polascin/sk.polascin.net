<div style="border: solid thin silver; display: inline-table; background-color: whitesmoke; padding-left: 1em; padding-right: 1em;">
	<a href="https://en.wikipedia.org/wiki/Swatch_Internet_Time" target="_blank">
		<span id="internettime" style="font-weight: bold; "></span>
	</a>
	<br>
	<a href="https://time.is/" target="_blank">
		<span>Deň:&nbsp;</span><span id="daynumber" style="font-weight: bold; "></span>
		<span>&nbsp;&nbsp;&nbsp;Rok:&nbsp;</span><span id="yearnumber" style="font-weight: bolder; "></span>
		<span>&nbsp;&nbsp;&nbsp;Týždeň:&nbsp;</span><span id="weeknumber" style="font-weight: bold; "></span>
		<span>&nbsp;&nbsp;&nbsp;Dnes je&nbsp;</span><span id="current" style="font-weight: bold; "></span>
		<br>
		<span style="font-style: italic; font-variant: small-caps; font-size: smaller;"><span>(</span><span id="timezone"></span><span>)</span></span>
	</a>
</div>

<script>
	function getDayOfYear(date) {
		const start = new Date(date.getFullYear(), 0, 0);
		const diff = date - start;
		const oneDay = 1000 * 60 * 60 * 24;
		return Math.floor(diff / oneDay);
	}
	function getWeekNumber(date) {
		const firstDayOfYear = new Date(date.getFullYear(), 0, 1);
		const pastDaysOfYear = (date - firstDayOfYear) / 86400000;
		return Math.ceil((pastDaysOfYear + firstDayOfYear.getDay() + 1) / 7);
	}
	function getISOWeekNumber(date) {
		const tempDate = new Date(date.valueOf());
		const dayNumber = (date.getUTCDay() + 6) % 7;
		tempDate.setUTCDate(tempDate.getUTCDate() - dayNumber + 3);
		const firstThursday = tempDate.valueOf();
		tempDate.setUTCMonth(0, 1);
		if (tempDate.getUTCDay() !== 4) {
			tempDate.setUTCMonth(0, 1 + ((4 - tempDate.getUTCDay()) + 7) % 7);
   		}
		return 1 + Math.ceil((firstThursday - tempDate) / (7 * 24 * 60 * 60 * 1000));
	}
	const today = new Date();
	const currentYear = new Date().getFullYear();
	const timeZone = new Intl.DateTimeFormat('sk-SK', { timeZoneName: 'long' } ).format(new Date());
	document.querySelector('#daynumber').textContent = getDayOfYear(today);
	document.querySelector('#weeknumber').textContent = getISOWeekNumber(today);
	document.querySelector('#yearnumber').textContent = currentYear;
	document.querySelector('#timezone').textContent = timeZone;
	function updateDateTime() {
		const now = new Date();
		const options = {
			dateStyle: 'full',
			timeStyle: 'long'
		};
		const currentDateTime = now.toLocaleString("sk-SK", options);
		document.querySelector('#current').textContent = currentDateTime;
		function getInternetTime() {
			const now = new Date();
			const timezoneOffset = now.getTimezoneOffset() * 60000; // Offset in milliseconds
			const bielTime = new Date(now.getTime() + timezoneOffset + 3600000); // Biel is UTC+1
			const beats = Math.floor((bielTime.getUTCHours() * 3600 + bielTime.getUTCMinutes() * 60 + bielTime.getUTCSeconds()) / 86.4) % 1000;
			return `@${beats.toString().padStart(3, '0')}`;
		}
		document.querySelector('#internettime').textContent = getInternetTime();
	}
	setInterval(updateDateTime, 1000);
</script>

