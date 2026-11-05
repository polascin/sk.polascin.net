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
}

const today = new Date();
setText('daynumber', String(getDayOfYear(today)));
setText('weeknumber', String(getISOWeekNumber(today)));
setText('yearnumber', String(today.getFullYear()));
setText('timezone', getTimeZoneName(today));
updateDateTime();
setInterval(updateDateTime, 1000);
