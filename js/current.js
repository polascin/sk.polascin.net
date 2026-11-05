// sk.polascin.net - datum, cas, ISO tyzden a Swatch Internet Time.
// Vynate z inline <script> v blocks/current.sk.php kvoli Content-Security-Policy
// (script-src 'self' bez 'unsafe-inline'). Nacitava sa s atributom defer.

function getDayOfYear(date) {
	const start = new Date(date.getFullYear(), 0, 0);
	const diff = date - start;
	const oneDay = 1000 * 60 * 60 * 24;
	return Math.floor(diff / oneDay);
}

function getISOWeekNumber(date) {
	// Local calendar (Mon=0); UTC getters mis-count ISO weeks near Bratislava midnight.
	const d = new Date(date.getFullYear(), date.getMonth(), date.getDate());
	const dayNumber = (d.getDay() + 6) % 7;
	d.setDate(d.getDate() - dayNumber + 3);
	const firstThursday = d.valueOf();
	d.setMonth(0, 1);
	if (d.getDay() !== 4) {
		d.setMonth(0, 1 + ((4 - d.getDay()) + 7) % 7);
	}
	return 1 + Math.round((firstThursday - d.valueOf()) / (7 * 24 * 60 * 60 * 1000));
}

function getTimeZoneName(date) {
	const parts = new Intl.DateTimeFormat('sk-SK', { timeZoneName: 'long' }).formatToParts(date);
	const zone = parts.find(function (part) { return part.type === 'timeZoneName'; });
	return zone ? zone.value : '';
}

function getInternetTime(date) {
	const timezoneOffset = date.getTimezoneOffset() * 60000;
	const bielTime = new Date(date.getTime() + timezoneOffset + 3600000); // Biel Mean Time UTC+1
	const beats = Math.floor(
		(bielTime.getUTCHours() * 3600 + bielTime.getUTCMinutes() * 60 + bielTime.getUTCSeconds()) / 86.4
	) % 1000;
	return '@' + beats.toString().padStart(3, '0');
}

function setText(id, value) {
	const el = document.getElementById(id);
	if (el) {
		el.textContent = value;
	}
}

function updateDateTime() {
	const now = new Date();
	setText('current', now.toLocaleString('sk-SK', { dateStyle: 'full', timeStyle: 'long' }));
	setText('internettime', getInternetTime(now));
	// Refresh calendar fields every tick so a tab left open past midnight stays correct.
	setText('daynumber', String(getDayOfYear(now)));
	setText('weeknumber', String(getISOWeekNumber(now)));
	setText('yearnumber', String(now.getFullYear()));
	setText('timezone', getTimeZoneName(now));
}

updateDateTime();
setInterval(updateDateTime, 1000);
