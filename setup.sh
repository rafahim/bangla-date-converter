#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
mkdir -p api tests .well-known

cat > "$ROOT/.gitignore" <<'__BANGLA_DATE__GITIGNORE__'
node_modules/
.DS_Store
Thumbs.db
*.log
.env
coverage/
bangla-date-converter.zip
__BANGLA_DATE__GITIGNORE__

cat > "$ROOT/.well-known/security.txt" <<'__BANGLA_DATE__WELL_KNOWN_SECURITY_TXT__'
Contact: mailto:dev@rafahim.com
Canonical: https://rafahim.com/.well-known/security.txt
Preferred-Languages: bn, en
Expires: 2027-10-09T00:00:00.000Z
Policy: https://rafahim.com/
__BANGLA_DATE__WELL_KNOWN_SECURITY_TXT__

cat > "$ROOT/LICENSE" <<'__BANGLA_DATE_LICENSE__'
MIT License

Copyright (c) 2026 RA Fahim

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
__BANGLA_DATE_LICENSE__

cat > "$ROOT/README.md" <<'__BANGLA_DATE_README_MD__'
# Bangla Date Converter

A Bengali-first, responsive Gregorian ↔ Bangla date converter following the Bangladesh Bangla Academy calendar revision introduced in 2019. The app runs in the browser without uploading dates or requiring an API. A lightweight optional Node.js server provides static hosting and JSON conversion endpoints.

## Features

- Gregorian-to-Bangla and Bangla-to-Gregorian conversion
- Today's Bangla date calculated in the Asia/Dhaka timezone
- Bengali weekday, month, year, season, and month length
- Countdown to the next Pohela Boishakh
- Completed age in Bangla calendar years
- Difference between two Gregorian dates
- A curated list of fixed-date Bangladesh national days and public observances
- Copy, native share, and print actions
- Light/dark themes with local preference storage
- Responsive Bengali UI, metadata, JSON-LD, Open Graph, Twitter Card, manifest, sitemap, and robots rules
- Unit tests for 1952, 1971, 2000, 2024, 2100, leap years, reverse conversion, and Pohela Boishakh boundaries

## Calendar algorithm

The converter uses the Bangladesh civil calendar adopted in the 2019 Bangla Academy revision. The new Bengali year begins on 14 April. Baishakh through Ashwin have 31 days each; Kartik through Magh have 30 days each; Falgun has 29 days in a common Gregorian year and 30 days when the Gregorian year containing February is a leap year; Choitro has 30 days. This distributes the extra Gregorian leap day inside Falgun and keeps the next Pohela Boishakh on 14 April.

For a Gregorian date, the algorithm selects the current year's 14 April if the date is on or after that boundary, otherwise it selects the previous year's 14 April. The Bangla year is the start Gregorian year minus 593. It calculates the day offset from that start and subtracts each month length until the date falls into a month. Reverse conversion adds each preceding month length to 14 April of the corresponding Gregorian start year. Date calculations use UTC-midnight calendar dates to avoid local daylight-saving offsets; the app obtains today's date explicitly in the `Asia/Dhaka` timezone.

Historical dates are converted by applying the current revised civil rules proleptically. The result is not a reconstruction of historical astronomical panjikas or the pre-2019 month-length system.

## Examples

| Gregorian date | Bangla result under the 2019 rules |
| --- | --- |
| 2024-02-21 | ৮ ফাল্গুন ১৪৩০ |
| 2024-03-14 | ৩০ ফাল্গুন ১৪৩০ |
| 2024-03-15 | ১ চৈত্র ১৪৩০ |
| 2024-04-13 | ৩০ চৈত্র ১৪৩০ |
| 2024-04-14 | ১ বৈশাখ ১৪৩১ |
| 2023-03-14 | ২৯ ফাল্গুন ১৪২৯ |

## Run locally

### Node.js server

Requires Node.js 18 or newer. No npm packages are required.

```bash
npm start
```

Open `http://127.0.0.1:4173`. The JSON API includes `GET /api/health`, `GET /api/convert?type=to-bangla&date=2024-04-14`, and `GET /api/convert?type=to-gregorian&year=1431&month=1&day=1`.

### Static hosting

Serve the project directory with any static web server. For ES module loading, do not open `index.html` directly as a `file://` URL. A quick option is `python -m http.server 8000`, then open `http://localhost:8000`.

### Tests

```bash
npm test
```

## Author

**RA Fahim** — Web Developer & Creator, Full-stack, 1 year. Based in Dhaka, Bangladesh.

- Website: https://rafahim.com
- GitHub: https://github.com/rafahim
- Email: dev@rafahim.com
- X/Twitter: https://twitter.com/rafahimn
- LinkedIn: https://linkedin.com/in/rafahimn

## SEO checklist

- [x] Required page title, description, keywords, and author metadata
- [x] Canonical URL: `https://rafahim.com/bangla-date/`
- [x] Open Graph and Twitter Card metadata
- [x] JSON-LD for `WebApplication`, `Person`, and `BreadcrumbList`
- [x] `robots.txt` and `sitemap.xml`
- [x] Responsive layout and semantic headings
- [x] SVG favicon and Open Graph artwork
- [x] Web app manifest and theme color
- [ ] Replace deployment-specific metadata or add a raster social preview if the hosting platform requires a PNG/JPEG Open Graph image
- [ ] Verify canonical, sitemap, and structured data after deployment

## Notes

The fixed-date list covers selected recurring dates and is not an exhaustive annual government holiday schedule. Religious holidays such as Eid depend on official announcements and lunar observations. The application makes calculations locally; loading the optional Google Fonts stylesheet requires a network connection, but date conversion itself does not.
__BANGLA_DATE_README_MD__

cat > "$ROOT/api/server.js" <<'__BANGLA_DATE_API_SERVER_JS__'
import http from 'node:http'
import { readFile } from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { gregorianToBangla, banglaToGregorian, toISODate } from '../calendar.js'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const port = Number(process.env.PORT || 4173)
const types = { '.html': 'text/html; charset=utf-8', '.css': 'text/css; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.json': 'application/json; charset=utf-8', '.svg': 'image/svg+xml', '.txt': 'text/plain; charset=utf-8', '.xml': 'application/xml; charset=utf-8', '.webmanifest': 'application/manifest+json; charset=utf-8' }

function send(response, status, body, contentType = 'application/json; charset=utf-8') {
  response.writeHead(status, { 'content-type': contentType, 'x-content-type-options': 'nosniff', 'referrer-policy': 'strict-origin-when-cross-origin', 'cache-control': 'no-store' })
  response.end(typeof body === 'string' ? body : JSON.stringify(body))
}

function handleApi(url, response) {
  if (url.pathname === '/api/health') return send(response, 200, { ok: true, name: 'Bangla Date Converter' })
  if (url.pathname !== '/api/convert') return send(response, 404, { error: 'API endpoint not found' })
  try {
    const type = url.searchParams.get('type') || 'to-bangla'
    if (type === 'to-bangla' || type === 'gregorian') {
      const date = url.searchParams.get('date')
      if (!date) return send(response, 400, { error: 'date=YYYY-MM-DD is required' })
      return send(response, 200, { gregorian: toISODate(date), bangla: gregorianToBangla(date) })
    }
    if (type === 'to-gregorian' || type === 'bangla') {
      const year = url.searchParams.get('year')
      const month = url.searchParams.get('month')
      const day = url.searchParams.get('day')
      if (!year || !month || !day) return send(response, 400, { error: 'year, month and day are required' })
      const gregorian = toISODate(banglaToGregorian(year, month, day))
      return send(response, 200, { gregorian, bangla: gregorianToBangla(gregorian) })
    }
    return send(response, 400, { error: 'type must be to-bangla or to-gregorian' })
  } catch (error) {
    return send(response, 400, { error: error.message || 'Unable to convert date' })
  }
}

const server = http.createServer(async (request, response) => {
  const url = new URL(request.url || '/', `http://${request.headers.host || 'localhost'}`)
  if (url.pathname.startsWith('/api/')) return handleApi(url, response)
  if (request.method !== 'GET' && request.method !== 'HEAD') return send(response, 405, { error: 'Method not allowed' })
  let pathname
  try { pathname = decodeURIComponent(url.pathname) } catch { return send(response, 400, { error: 'Invalid path' }) }
  if (pathname === '/') pathname = '/index.html'
  const filePath = path.resolve(root, `.${pathname}`)
  if (filePath !== root && !filePath.startsWith(`${root}${path.sep}`)) return send(response, 403, { error: 'Forbidden' })
  try {
    const body = await readFile(filePath)
    response.writeHead(200, { 'content-type': types[path.extname(filePath)] || 'application/octet-stream', 'x-content-type-options': 'nosniff', 'referrer-policy': 'strict-origin-when-cross-origin', 'cache-control': 'no-cache' })
    response.end(request.method === 'HEAD' ? undefined : body)
  } catch {
    send(response, 404, 'Not found', 'text/plain; charset=utf-8')
  }
})

server.listen(port, '127.0.0.1', () => process.stdout.write(`Bangla Date Converter running at http://127.0.0.1:${port}\n`))
__BANGLA_DATE_API_SERVER_JS__

cat > "$ROOT/calendar.js" <<'__BANGLA_DATE_CALENDAR_JS__'
export const BENGALI_MONTHS = Object.freeze(['বৈশাখ', 'জ্যৈষ্ঠ', 'আষাঢ়', 'শ্রাবণ', 'ভাদ্র', 'আশ্বিন', 'কার্তিক', 'অগ্রহায়ণ', 'পৌষ', 'মাঘ', 'ফাল্গুন', 'চৈত্র'])
export const BENGALI_WEEKDAYS = Object.freeze(['রবিবার', 'সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার', 'শনিবার'])
export const BENGALI_SEASONS = Object.freeze(['গ্রীষ্ম', 'বর্ষা', 'শরৎ', 'হেমন্ত', 'শীত', 'বসন্ত'])

const DAY_MS = 86400000
const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/

export function isGregorianLeapYear(year) {
  const value = Number(year)
  return Number.isInteger(value) && value % 4 === 0 && (value % 100 !== 0 || value % 400 === 0)
}

export function toGregorianDate(value) {
  let year
  let month
  let day
  if (value instanceof Date) {
    if (Number.isNaN(value.getTime())) throw new RangeError('Invalid Gregorian date')
    year = value.getFullYear()
    month = value.getMonth() + 1
    day = value.getDate()
  } else if (typeof value === 'string' && DATE_PATTERN.test(value)) {
    ;[year, month, day] = value.split('-').map(Number)
  } else {
    throw new TypeError('Use a valid Date or YYYY-MM-DD string')
  }
  const result = new Date(Date.UTC(year, month - 1, day))
  if (result.getUTCFullYear() !== year || result.getUTCMonth() !== month - 1 || result.getUTCDate() !== day) throw new RangeError('Invalid Gregorian date')
  return result
}

export function toISODate(value) {
  const date = toGregorianDate(value)
  return `${String(date.getUTCFullYear()).padStart(4, '0')}-${String(date.getUTCMonth() + 1).padStart(2, '0')}-${String(date.getUTCDate()).padStart(2, '0')}`
}

export function getBanglaMonthLength(month, falgunGregorianYear) {
  const monthNumber = typeof month === 'string' && !/^\d+$/.test(month) ? BENGALI_MONTHS.indexOf(month) + 1 : Number(month)
  if (!Number.isInteger(monthNumber) || monthNumber < 1 || monthNumber > 12) throw new RangeError('Bangla month must be between 1 and 12')
  if (!Number.isInteger(Number(falgunGregorianYear)) || Number(falgunGregorianYear) < 1) throw new RangeError('A valid Gregorian year is required')
  if (monthNumber <= 6) return 31
  if (monthNumber === 11) return isGregorianLeapYear(Number(falgunGregorianYear)) ? 30 : 29
  return 30
}

function getBanglaYearStart(gregorianYear) {
  return new Date(Date.UTC(gregorianYear, 3, 14))
}

function monthLengthsForBanglaYear(banglaYear) {
  const startGregorianYear = Number(banglaYear) + 593
  return BENGALI_MONTHS.map((_, index) => getBanglaMonthLength(index + 1, startGregorianYear + 1))
}

export function gregorianToBangla(value) {
  const date = toGregorianDate(value)
  const year = date.getUTCFullYear()
  const month = date.getUTCMonth()
  const day = date.getUTCDate()
  const startsThisYear = month > 3 || (month === 3 && day >= 14)
  const startGregorianYear = startsThisYear ? year : year - 1
  const banglaYear = startGregorianYear - 593
  let remainingDays = Math.floor((date.getTime() - getBanglaYearStart(startGregorianYear).getTime()) / DAY_MS)
  const lengths = monthLengthsForBanglaYear(banglaYear)
  let monthIndex = 0
  while (monthIndex < lengths.length - 1 && remainingDays >= lengths[monthIndex]) {
    remainingDays -= lengths[monthIndex]
    monthIndex += 1
  }
  return {
    year: banglaYear,
    month: monthIndex + 1,
    monthName: BENGALI_MONTHS[monthIndex],
    day: remainingDays + 1,
    weekday: BENGALI_WEEKDAYS[date.getUTCDay()],
    weekdayIndex: date.getUTCDay(),
    season: getBanglaSeason(monthIndex + 1),
    gregorianDate: toISODate(date),
    monthLength: lengths[monthIndex]
  }
}

export function banglaToGregorian(year, month, day) {
  const banglaYear = Number(year)
  const monthNumber = typeof month === 'string' && !/^\d+$/.test(month) ? BENGALI_MONTHS.indexOf(month) + 1 : Number(month)
  const dayNumber = Number(day)
  if (!Number.isInteger(banglaYear) || banglaYear < 1 || banglaYear > 9000) throw new RangeError('Invalid Bangla year')
  if (!Number.isInteger(monthNumber) || monthNumber < 1 || monthNumber > 12) throw new RangeError('Bangla month must be between 1 and 12')
  const lengths = monthLengthsForBanglaYear(banglaYear)
  if (!Number.isInteger(dayNumber) || dayNumber < 1 || dayNumber > lengths[monthNumber - 1]) throw new RangeError(`এই মাসে ${lengths[monthNumber - 1]} দিনের বেশি নেই`)
  let offset = dayNumber - 1
  for (let index = 0; index < monthNumber - 1; index += 1) offset += lengths[index]
  const startGregorianYear = banglaYear + 593
  const date = new Date(getBanglaYearStart(startGregorianYear).getTime() + offset * DAY_MS)
  return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate())
}

export function getBanglaDate(value) {
  return gregorianToBangla(value)
}

export function getBanglaSeason(month) {
  const value = Number(month)
  if (!Number.isInteger(value) || value < 1 || value > 12) throw new RangeError('Bangla month must be between 1 and 12')
  return BENGALI_SEASONS[Math.floor((value - 1) / 2)]
}

export function formatBanglaNumber(value) {
  return String(value).replace(/[0-9]/g, digit => '০১২৩৪৫৬৭৮৯'[Number(digit)])
}

export function formatBanglaDate(value) {
  const date = gregorianToBangla(value)
  return `${date.weekday}, ${formatBanglaNumber(date.day)} ${date.monthName} ${formatBanglaNumber(date.year)} বঙ্গাব্দ`
}

export function getNextPohelaBoishakh(value) {
  const date = toGregorianDate(value)
  const year = date.getUTCFullYear()
  const thisYear = getBanglaYearStart(year)
  const target = date.getTime() <= thisYear.getTime() ? thisYear : getBanglaYearStart(year + 1)
  return new Date(target.getUTCFullYear(), target.getUTCMonth(), target.getUTCDate())
}

export function getDaysBetween(startValue, endValue) {
  const start = toGregorianDate(startValue)
  const end = toGregorianDate(endValue)
  const days = Math.abs(Math.round((end.getTime() - start.getTime()) / DAY_MS))
  return { days, weeks: Math.floor(days / 7), remainingDays: days % 7, direction: end.getTime() >= start.getTime() ? 1 : -1 }
}

export function calculateBanglaAge(birthValue, asOfValue = new Date()) {
  const birth = toGregorianDate(birthValue)
  const asOf = toGregorianDate(asOfValue)
  if (birth.getTime() > asOf.getTime()) throw new RangeError('জন্মতারিখ ভবিষ্যতের হতে পারে না')
  const born = gregorianToBangla(birth)
  const current = gregorianToBangla(asOf)
  let age = current.year - born.year
  if (current.month < born.month || (current.month === born.month && current.day < born.day)) age -= 1
  return Math.max(0, age)
}

export function getBangladeshFixedHolidays(gregorianYear) {
  const year = Number(gregorianYear)
  if (!Number.isInteger(year) || year < 1 || year > 9998) throw new RangeError('Invalid Gregorian year')
  const holidays = [
    [`${year}-02-21`, 'শহীদ দিবস ও আন্তর্জাতিক মাতৃভাষা দিবস'],
    [`${year}-03-26`, 'স্বাধীনতা ও জাতীয় দিবস'],
    [`${year}-04-14`, 'বাংলা নববর্ষ'],
    [`${year}-05-01`, 'মে দিবস'],
    [`${year}-12-16`, 'বিজয় দিবস'],
    [`${year}-12-25`, 'বড়দিন']
  ]
  return holidays.map(([date, name]) => ({ date, name, bangla: gregorianToBangla(date) }))
}
__BANGLA_DATE_CALENDAR_JS__

cat > "$ROOT/favicon.svg" <<'__BANGLA_DATE_FAVICON_SVG__'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <rect width="64" height="64" rx="18" fill="#0d6b53"/>
  <circle cx="45" cy="17" r="5" fill="#efc06d"/>
  <path d="M13 43c6-1 9-6 9-14V19h7v10c0 6 2 10 8 10 6 0 9-4 9-11V19h7v12c0 12-6 19-16 19-7 0-12-3-15-9-2 4-5 7-9 8z" fill="#fff"/>
</svg>
__BANGLA_DATE_FAVICON_SVG__

cat > "$ROOT/humans.txt" <<'__BANGLA_DATE_HUMANS_TXT__'
Creator: RA Fahim
Role: Web Developer & Creator, Full-stack, 1 year
Website: https://rafahim.com
GitHub: https://github.com/rafahim
Email: dev@rafahim.com
X: https://twitter.com/rafahimn
LinkedIn: https://linkedin.com/in/rafahimn
Location: Dhaka, Bangladesh

Standards: HTML5, CSS3, ECMAScript modules
Calendar: Bangladesh Bangla Academy 2019 revised civil calendar
Privacy: Gregorian and Bangla conversion is calculated locally in the browser
Copyright: 2026 RA Fahim
__BANGLA_DATE_HUMANS_TXT__

cat > "$ROOT/index.html" <<'__BANGLA_DATE_INDEX_HTML__'
<!doctype html>
<html lang="bn">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Bangla Date Converter — English to Bengali Calendar Date Converter | RA Fahim</title>
  <meta name="description" content="বাংলা একাডেমির ২০১৯ সালের সংশোধিত পঞ্জিকা অনুযায়ী ইংরেজি তারিখ থেকে বাংলা তারিখ এবং বাংলা তারিখ থেকে ইংরেজি তারিখ নির্ভুলভাবে রূপান্তর করুন।">
  <meta name="keywords" content="bangla date converter, bengali calendar, bangla year converter, pohela boishakh, বাংলা তারিখ, বাংলা ক্যালেন্ডার, ইংরেজি বাংলা তারিখ">
  <meta name="author" content="RA Fahim">
  <meta name="robots" content="index, follow, max-image-preview:large">
  <link rel="canonical" href="https://rafahim.com/bangla-date/">
  <meta name="theme-color" content="#0d6b53">
  <meta property="og:type" content="website">
  <meta property="og:locale" content="bn_BD">
  <meta property="og:site_name" content="RA Fahim">
  <meta property="og:title" content="Bangla Date Converter — English to Bengali Calendar Date Converter | RA Fahim">
  <meta property="og:description" content="বাংলা ও ইংরেজি তারিখ রূপান্তর করুন বাংলা একাডেমির ২০১৯ সালের সংশোধিত ক্যালেন্ডার অনুযায়ী।">
  <meta property="og:url" content="https://rafahim.com/bangla-date/">
  <meta property="og:image" content="https://rafahim.com/bangla-date/og-image.svg">
  <meta property="og:image:alt" content="Bangla Date Converter by RA Fahim">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="Bangla Date Converter — English to Bengali Calendar Date Converter | RA Fahim">
  <meta name="twitter:description" content="বাংলা ও ইংরেজি তারিখ সহজে রূপান্তর করুন।">
  <meta name="twitter:image" content="https://rafahim.com/bangla-date/og-image.svg">
  <link rel="icon" href="favicon.svg" type="image/svg+xml">
  <link rel="manifest" href="manifest.json">
  <link rel="stylesheet" href="style.css">
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "WebApplication",
        "name": "Bangla Date Converter",
        "url": "https://rafahim.com/bangla-date/",
        "applicationCategory": "UtilitiesApplication",
        "operatingSystem": "Any",
        "inLanguage": "bn-BD",
        "description": "Bangla Academy 2019 revised calendar converter for Gregorian and Bengali dates.",
        "author": { "@type": "Person", "name": "RA Fahim", "url": "https://rafahim.com" }
      },
      {
        "@type": "Person",
        "name": "RA Fahim",
        "url": "https://rafahim.com",
        "jobTitle": "Web Developer & Creator",
        "description": "Full-stack web developer and creator; 1 year.",
        "homeLocation": { "@type": "Place", "name": "Dhaka, Bangladesh" },
        "sameAs": ["https://github.com/rafahim", "https://twitter.com/rafahimn", "https://linkedin.com/in/rafahimn"]
      },
      {
        "@type": "BreadcrumbList",
        "itemListElement": [
          { "@type": "ListItem", "position": 1, "name": "Home", "item": "https://rafahim.com" },
          { "@type": "ListItem", "position": 2, "name": "Bangla Date Converter", "item": "https://rafahim.com/bangla-date/" }
        ]
      }
    ]
  }
  </script>
  <script type="module" src="script.js"></script>
</head>
<body>
  <div class="site-shell">
    <header class="topbar">
      <a class="brand" href="https://rafahim.com" aria-label="RA Fahim home">
        <span class="brand-mark">বা</span>
        <span class="brand-copy"><strong>বাংলা তারিখ</strong><small>Bangla Date Converter</small></span>
      </a>
      <div class="top-actions">
        <span class="standard-pill"><span class="status-dot"></span> বাংলা একাডেমি ২০১৯</span>
        <button id="theme-toggle" class="icon-button" type="button" aria-label="ডার্ক মোড চালু বা বন্ধ করুন" title="থিম পরিবর্তন"><span id="theme-icon">☾</span></button>
      </div>
    </header>

    <main>
      <section class="hero">
        <div class="hero-copy">
          <p class="eyebrow"><span class="eyebrow-line"></span> বাংলাদেশি বাংলা ক্যালেন্ডার</p>
          <h1>ইংরেজি ও বাংলা<br><span>তারিখ রূপান্তর</span></h1>
          <p class="hero-description">বাংলা একাডেমির ২০১৯ সালের সংশোধিত পঞ্জিকা অনুযায়ী যেকোনো তারিখ রূপান্তর করুন। সহজ, নির্ভুল এবং আপনার ব্রাউজারেই।</p>
          <div class="hero-tags"><span>✓ দ্বিমুখী রূপান্তর</span><span>✓ ফাল্গুনের লিপ-ইয়ার নিয়ম</span><span>✓ ব্যক্তিগত ডেটা ডিভাইসেই থাকে</span></div>
        </div>
        <div class="hero-art" aria-hidden="true">
          <div class="art-orbit orbit-one"></div><div class="art-orbit orbit-two"></div>
          <div class="art-sun"></div><div class="art-leaf leaf-one"></div><div class="art-leaf leaf-two"></div>
          <div class="art-date"><span>আজকের দিন</span><strong id="hero-bangla-day">—</strong><small id="hero-bangla-month">বাংলা তারিখ</small></div>
          <span class="art-floating floating-one">১৪</span><span class="art-floating floating-two">বৈশাখ</span>
        </div>
      </section>

      <section class="dashboard-grid" aria-label="তারিখ রূপান্তর">
        <article class="panel converter-panel">
          <div class="panel-heading">
            <div><span class="section-kicker">DATE CONVERTER</span><h2>তারিখ রূপান্তর করুন</h2></div>
            <span class="panel-icon">⇄</span>
          </div>
          <div class="mode-switch" role="tablist" aria-label="রূপান্তরের ধরন">
            <button class="mode-tab active" data-mode="to-bangla" type="button" role="tab" aria-selected="true">ইংরেজি → বাংলা</button>
            <button class="mode-tab" data-mode="to-gregorian" type="button" role="tab" aria-selected="false">বাংলা → ইংরেজি</button>
          </div>
          <form id="converter-form" novalidate>
            <div id="gregorian-inputs" class="field-group">
              <label for="gregorian-date">ইংরেজি তারিখ নির্বাচন করুন</label>
              <div class="date-input-wrap"><span class="field-symbol">▦</span><input id="gregorian-date" name="gregorian-date" type="date" required></div>
              <p class="field-hint">দিন / মাস / বছর — Gregorian calendar</p>
            </div>
            <div id="bangla-inputs" class="field-group hidden" aria-hidden="true">
              <label>বাংলা তারিখ লিখুন</label>
              <div class="bangla-fields">
                <div><label class="sub-label" for="bangla-day">দিন</label><input id="bangla-day" type="number" min="1" max="31" inputmode="numeric" placeholder="দিন" value="1"></div>
                <div><label class="sub-label" for="bangla-month">মাস</label><select id="bangla-month"></select></div>
                <div><label class="sub-label" for="bangla-year">বঙ্গাব্দ</label><input id="bangla-year" type="number" min="1" max="9000" inputmode="numeric" placeholder="বছর"></div>
              </div>
              <p class="field-hint">বাংলা একাডেমির সংশোধিত ক্যালেন্ডার</p>
            </div>
            <button class="primary-button" type="submit"><span>তারিখ রূপান্তর করুন</span><span class="button-arrow">↗</span></button>
            <p id="converter-error" class="form-error" role="alert"></p>
          </form>
          <div id="conversion-result" class="conversion-result" aria-live="polite">
            <div class="result-topline"><span class="result-label">রূপান্তরের ফলাফল</span><span class="result-check">✓</span></div>
            <p id="result-weekday" class="result-weekday">আজকের দিন</p>
            <h3 id="result-main">তারিখ প্রস্তুত হচ্ছে…</h3>
            <p id="result-secondary" class="result-secondary">ইংরেজি তারিখ</p>
            <div class="result-meta"><span><small>ঋতু</small><strong id="result-season">—</strong></span><span><small>বঙ্গাব্দ</small><strong id="result-year">—</strong></span><span><small>মাসের দিন</small><strong id="result-month-length">—</strong></span></div>
            <div class="result-actions"><button type="button" id="copy-result" class="utility-button">▣ কপি</button><button type="button" id="share-result" class="utility-button">↗ শেয়ার</button><button type="button" id="print-result" class="utility-button">⎙ প্রিন্ট</button></div>
            <p id="copy-feedback" class="copy-feedback" aria-live="polite"></p>
          </div>
        </article>

        <div class="side-stack">
          <article class="today-card">
            <div class="today-card-top"><span class="today-spark">✳</span><span>আজকের বাংলা তারিখ</span><span class="today-live">LIVE</span></div>
            <p id="today-weekday" class="today-weekday">—</p>
            <div class="today-date-line"><strong id="today-day">—</strong><div><span id="today-month">—</span><small id="today-year">—</small></div></div>
            <div class="today-divider"></div>
            <div class="today-bottom"><span id="today-gregorian">—</span><span id="today-season" class="season-pill">—</span></div>
          </article>
          <article class="countdown-card">
            <div class="countdown-icon">✿</div><div class="countdown-content"><p class="section-kicker">NEXT CELEBRATION</p><h3>পহেলা বৈশাখ</h3><p id="pohela-date">১৪ এপ্রিল</p></div>
            <div class="countdown-count"><strong id="pohela-days">—</strong><span id="pohela-label">দিন বাকি</span></div>
          </article>
          <article class="calendar-note"><span class="note-icon">ⓘ</span><p><strong>ক্যালেন্ডার নোট</strong><br>১৪ এপ্রিল বাংলা বছরের প্রথম দিন। ফাল্গুনে গ্রেগরিয়ান অধিবর্ষ অনুযায়ী ২৯ বা ৩০ দিন থাকে।</p></article>
        </div>
      </section>

      <section class="tools-section">
        <div class="section-header"><div><p class="section-kicker">MORE DATE TOOLS</p><h2>আরও তারিখের হিসাব</h2></div><p>দৈনন্দিন প্রয়োজনীয় হিসাব এক জায়গায়</p></div>
        <div class="tools-grid">
          <article class="panel tool-card">
            <div class="tool-title-row"><span class="tool-icon age-icon">বছর</span><div><h3>বাংলা হিসাবে বয়স</h3><p>বঙ্গাব্দ অনুযায়ী পূর্ণ বয়স</p></div></div>
            <form id="age-form" class="tool-form" novalidate><label for="birth-date">জন্মতারিখ</label><input id="birth-date" type="date" required><button class="secondary-button" type="submit">বয়স হিসাব করুন <span>→</span></button><p id="age-result" class="tool-result" aria-live="polite">জন্মতারিখ নির্বাচন করুন।</p></form>
          </article>
          <article class="panel tool-card">
            <div class="tool-title-row"><span class="tool-icon diff-icon">∆</span><div><h3>তারিখের ব্যবধান</h3><p>দুই তারিখের মাঝে কত দিন</p></div></div>
            <form id="difference-form" class="tool-form" novalidate><label for="diff-start">শুরুর তারিখ</label><input id="diff-start" type="date" required><label for="diff-end">শেষের তারিখ</label><input id="diff-end" type="date" required><button class="secondary-button" type="submit">ব্যবধান বের করুন <span>→</span></button><p id="difference-result" class="tool-result" aria-live="polite">দুটি তারিখ নির্বাচন করুন।</p></form>
          </article>
          <article class="panel holiday-card">
            <div class="holiday-heading"><div><p class="section-kicker">BANGLADESH</p><h3>জাতীয় দিবস ও ছুটি</h3></div><span class="holiday-icon">▤</span></div>
            <p class="holiday-year" id="holiday-year">২০২৬ সালের নির্দিষ্ট তারিখ</p>
            <div id="holiday-list" class="holiday-list"></div>
            <p class="holiday-note">ঈদ ও অন্যান্য চন্দ্রভিত্তিক ছুটির তারিখ সরকারি ঘোষণায় পরিবর্তিত হতে পারে।</p>
          </article>
        </div>
      </section>

      <section class="how-section">
        <div class="how-copy"><p class="section-kicker">HOW IT WORKS</p><h2>সহজ হিসাব, নির্ভরযোগ্য নিয়ম</h2><p>এই কনভার্টার বাংলাদেশে ব্যবহৃত বাংলা একাডেমির ২০১৯ সালের সংশোধিত নাগরিক পঞ্জিকা অনুসরণ করে। ঐতিহাসিক বছরের তারিখও একই নিয়ম ধারাবাহিকভাবে প্রয়োগ করে হিসাব করা হয়।</p></div>
        <div class="rule-list"><div><span>০১</span><p><strong>বৈশাখ থেকে আশ্বিন</strong><small>প্রতিটি মাস ৩১ দিনের</small></p></div><div><span>০২</span><p><strong>কার্তিক থেকে মাঘ</strong><small>প্রতিটি মাস ৩০ দিনের</small></p></div><div><span>০৩</span><p><strong>ফাল্গুন ও চৈত্র</strong><small>ফাল্গুন ২৯/৩০ দিন, চৈত্র ৩০ দিন</small></p></div></div>
      </section>
    </main>

    <footer class="footer"><a class="footer-brand" href="https://rafahim.com">RA Fahim</a><p>Built with ❤️ by RA Fahim · <a href="https://rafahim.com">rafahim.com</a> · © 2026 RA Fahim</p><div class="footer-links"><a href="https://github.com/rafahim">GitHub</a><a href="mailto:dev@rafahim.com">Contact</a></div></footer>
  </div>
</body>
</html>
__BANGLA_DATE_INDEX_HTML__

cat > "$ROOT/manifest.json" <<'__BANGLA_DATE_MANIFEST_JSON__'
{
  "id": "/bangla-date/",
  "name": "Bangla Date Converter — RA Fahim",
  "short_name": "বাংলা তারিখ",
  "description": "Bangla Academy 2019 revised Gregorian and Bangla calendar converter.",
  "lang": "bn-BD",
  "start_url": "./",
  "scope": "./",
  "display": "standalone",
  "background_color": "#f5f8f6",
  "theme_color": "#0d6b53",
  "icons": [
    { "src": "favicon.svg", "sizes": "any", "type": "image/svg+xml", "purpose": "any maskable" }
  ]
}
__BANGLA_DATE_MANIFEST_JSON__

cat > "$ROOT/og-image.svg" <<'__BANGLA_DATE_OG_IMAGE_SVG__'
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f3faf5"/><stop offset="1" stop-color="#dcefe3"/></linearGradient>
    <linearGradient id="gold" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f7d99b"/><stop offset="1" stop-color="#e7b65f"/></linearGradient>
  </defs>
  <rect width="1200" height="630" fill="url(#bg)"/>
  <circle cx="1010" cy="135" r="240" fill="#cfe7d8" opacity=".65"/>
  <circle cx="1040" cy="140" r="175" fill="none" stroke="#8fc3a3" stroke-width="2" opacity=".7"/>
  <circle cx="1040" cy="140" r="220" fill="none" stroke="#b5d9c1" stroke-width="2"/>
  <rect x="80" y="76" width="72" height="72" rx="22" fill="#0d6b53"/>
  <text x="116" y="124" font-family="sans-serif" font-size="34" font-weight="700" fill="#fff" text-anchor="middle">বা</text>
  <text x="175" y="106" font-family="sans-serif" font-size="22" font-weight="700" fill="#194a38">RA Fahim</text>
  <text x="175" y="132" font-family="sans-serif" font-size="15" fill="#648273">BANGLA DATE CONVERTER</text>
  <text x="80" y="254" font-family="sans-serif" font-size="58" font-weight="700" fill="#173d2e">ইংরেজি ও বাংলা</text>
  <text x="80" y="328" font-family="sans-serif" font-size="62" font-weight="700" fill="#0d6b53">তারিখ রূপান্তর</text>
  <text x="84" y="384" font-family="sans-serif" font-size="21" fill="#577667">Gregorian ↔ Bengali Calendar · Bangla Academy 2019</text>
  <rect x="80" y="444" width="405" height="66" rx="16" fill="#fff" stroke="#d4e9db"/>
  <text x="108" y="485" font-family="sans-serif" font-size="20" fill="#285b43">দ্রুত • নির্ভুল • ব্রাউজারেই</text>
  <circle cx="1004" cy="320" r="140" fill="url(#gold)"/>
  <circle cx="1004" cy="320" r="111" fill="#fff9e9" opacity=".88"/>
  <text x="1004" y="286" font-family="sans-serif" font-size="19" fill="#54725c" text-anchor="middle">আজকের দিন</text>
  <text x="1004" y="355" font-family="sans-serif" font-size="76" font-weight="700" fill="#0d6b53" text-anchor="middle">১৪</text>
  <text x="1004" y="389" font-family="sans-serif" font-size="23" font-weight="700" fill="#285b43" text-anchor="middle">বৈশাখ</text>
  <text x="80" y="580" font-family="sans-serif" font-size="16" fill="#719080">rafahim.com/bangla-date/</text>
</svg>
__BANGLA_DATE_OG_IMAGE_SVG__

cat > "$ROOT/package.json" <<'__BANGLA_DATE_PACKAGE_JSON__'
{
  "name": "bangla-date-converter",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "description": "Bangla Academy 2019 Bengali calendar converter",
  "scripts": {
    "start": "node api/server.js",
    "test": "node --test tests/*.test.js"
  },
  "engines": {
    "node": ">=18"
  }
}
__BANGLA_DATE_PACKAGE_JSON__

cat > "$ROOT/robots.txt" <<'__BANGLA_DATE_ROBOTS_TXT__'
User-agent: *
Allow: /
Sitemap: https://rafahim.com/bangla-date/sitemap.xml
__BANGLA_DATE_ROBOTS_TXT__

cat > "$ROOT/script.js" <<'__BANGLA_DATE_SCRIPT_JS__'
import { BENGALI_MONTHS, gregorianToBangla, banglaToGregorian, getBanglaMonthLength, getBanglaSeason, formatBanglaNumber, getNextPohelaBoishakh, getDaysBetween, calculateBanglaAge, getBangladeshFixedHolidays, toISODate } from './calendar.js'

const $ = selector => document.querySelector(selector)
const $$ = selector => [...document.querySelectorAll(selector)]
const todayISO = getDhakaTodayISO()
let activeMode = 'to-bangla'
let lastResult = ''

function getDhakaTodayISO() {
  const parts = new Intl.DateTimeFormat('en-GB', { timeZone: 'Asia/Dhaka', year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(new Date())
  const values = Object.fromEntries(parts.filter(part => part.type !== 'literal').map(part => [part.type, part.value]))
  return `${values.year}-${values.month}-${values.day}`
}

function formatGregorian(value) {
  return new Intl.DateTimeFormat('en-GB', { timeZone: 'UTC', day: '2-digit', month: 'long', year: 'numeric' }).format(new Date(`${toISODate(value)}T00:00:00Z`))
}

function localizeDate(value) {
  return new Intl.DateTimeFormat('bn-BD', { timeZone: 'UTC', day: 'numeric', month: 'long', year: 'numeric' }).format(new Date(`${toISODate(value)}T00:00:00Z`))
}

function setMode(mode) {
  activeMode = mode
  $$('.mode-tab').forEach(button => {
    const selected = button.dataset.mode === mode
    button.classList.toggle('active', selected)
    button.setAttribute('aria-selected', String(selected))
  })
  const gregorian = mode === 'to-bangla'
  $('#gregorian-inputs').classList.toggle('hidden', !gregorian)
  $('#bangla-inputs').classList.toggle('hidden', gregorian)
  $('#gregorian-inputs').setAttribute('aria-hidden', String(!gregorian))
  $('#bangla-inputs').setAttribute('aria-hidden', String(gregorian))
  $('#converter-error').textContent = ''
}

function renderResult(gregorianValue) {
  const iso = toISODate(gregorianValue)
  const bangla = gregorianToBangla(iso)
  $('#result-weekday').textContent = bangla.weekday
  $('#result-main').textContent = `${formatBanglaNumber(bangla.day)} ${bangla.monthName} ${formatBanglaNumber(bangla.year)} বঙ্গাব্দ`
  $('#result-secondary').textContent = `ইংরেজি তারিখ: ${formatGregorian(iso)}`
  $('#result-season').textContent = bangla.season
  $('#result-year').textContent = `${formatBanglaNumber(bangla.year)} বঙ্গাব্দ`
  $('#result-month-length').textContent = `${formatBanglaNumber(bangla.monthLength)} দিন`
  lastResult = `বাংলা তারিখ: ${bangla.weekday}, ${formatBanglaNumber(bangla.day)} ${bangla.monthName} ${formatBanglaNumber(bangla.year)} বঙ্গাব্দ\nইংরেজি তারিখ: ${formatGregorian(iso)}\nঋতু: ${bangla.season}\nবাংলা একাডেমি ২০১৯ সংশোধিত ক্যালেন্ডার\nhttps://rafahim.com/bangla-date/`
}

function renderToday() {
  const bangla = gregorianToBangla(todayISO)
  $('#hero-bangla-day').textContent = formatBanglaNumber(bangla.day)
  $('#hero-bangla-month').textContent = bangla.monthName
  $('#today-weekday').textContent = bangla.weekday
  $('#today-day').textContent = formatBanglaNumber(bangla.day)
  $('#today-month').textContent = bangla.monthName
  $('#today-year').textContent = `${formatBanglaNumber(bangla.year)} বঙ্গাব্দ`
  $('#today-gregorian').textContent = localizeDate(todayISO)
  $('#today-season').textContent = `${bangla.season} ঋতু`
  const next = getNextPohelaBoishakh(todayISO)
  const days = getDaysBetween(todayISO, toISODate(next)).days
  $('#pohela-date').textContent = localizeDate(toISODate(next))
  $('#pohela-days').textContent = formatBanglaNumber(days)
  $('#pohela-label').textContent = days === 0 ? 'আজই উৎসব' : 'দিন বাকি'
  $('#gregorian-date').value = todayISO
  $('#birth-date').max = todayISO
  $('#diff-start').value = todayISO
  $('#diff-end').value = todayISO
  $('#bangla-year').value = bangla.year
  $('#bangla-month').value = String(bangla.month)
  $('#bangla-day').value = String(bangla.day)
  renderResult(todayISO)
  renderHolidays(new Date(`${todayISO}T00:00:00Z`).getUTCFullYear())
}

function renderHolidays(year) {
  const holidays = getBangladeshFixedHolidays(year)
  $('#holiday-year').textContent = `${formatBanglaNumber(year)} সালের নির্দিষ্ট তারিখ`
  $('#holiday-list').replaceChildren(...holidays.map(holiday => {
    const item = document.createElement('div')
    item.className = 'holiday-item'
    const date = document.createElement('span')
    date.className = 'holiday-date'
    date.textContent = new Intl.DateTimeFormat('bn-BD', { timeZone: 'UTC', day: 'numeric', month: 'short' }).format(new Date(`${holiday.date}T00:00:00Z`))
    const name = document.createElement('span')
    name.className = 'holiday-name'
    name.textContent = holiday.name
    item.append(date, name)
    return item
  }))
}

function handleConvert(event) {
  event.preventDefault()
  $('#converter-error').textContent = ''
  try {
    let converted
    if (activeMode === 'to-bangla') {
      const value = $('#gregorian-date').value
      if (!value) throw new Error('একটি ইংরেজি তারিখ নির্বাচন করুন।')
      converted = toISODate(value)
    } else {
      const day = Number($('#bangla-day').value)
      const month = Number($('#bangla-month').value)
      const year = Number($('#bangla-year').value)
      if (!year || !day || !month) throw new Error('বাংলা দিন, মাস ও বছর পূরণ করুন।')
      converted = toISODate(banglaToGregorian(year, month, day))
    }
    renderResult(converted)
  } catch (error) {
    $('#converter-error').textContent = error.message || 'তারিখ রূপান্তর করা যায়নি।'
  }
}

async function copyText(text) {
  if (navigator.clipboard && window.isSecureContext) {
    await navigator.clipboard.writeText(text)
    return
  }
  const area = document.createElement('textarea')
  area.value = text
  area.style.position = 'fixed'
  area.style.opacity = '0'
  document.body.append(area)
  area.select()
  const successful = document.execCommand('copy')
  area.remove()
  if (!successful) throw new Error('কপি করা সম্ভব হয়নি।')
}

function setTheme(dark) {
  document.body.classList.toggle('dark', dark)
  $('#theme-icon').textContent = dark ? '☀' : '☾'
  $('#theme-toggle').setAttribute('aria-label', dark ? 'লাইট মোড চালু করুন' : 'ডার্ক মোড চালু করুন')
  try { localStorage.setItem('bangla-date-theme', dark ? 'dark' : 'light') } catch {}
}

function initialize() {
  $('#bangla-month').replaceChildren(...BENGALI_MONTHS.map((month, index) => {
    const option = document.createElement('option')
    option.value = String(index + 1)
    option.textContent = month
    return option
  }))
  $$('.mode-tab').forEach(button => button.addEventListener('click', () => setMode(button.dataset.mode)))
  $('#converter-form').addEventListener('submit', handleConvert)
  $('#copy-result').addEventListener('click', async () => {
    try {
      await copyText(lastResult)
      $('#copy-feedback').textContent = 'তারিখ কপি করা হয়েছে।'
    } catch (error) {
      $('#copy-feedback').textContent = error.message || 'কপি করা যায়নি।'
    }
  })
  $('#share-result').addEventListener('click', async () => {
    try {
      if (navigator.share) await navigator.share({ title: 'বাংলা তারিখ রূপান্তর', text: lastResult, url: 'https://rafahim.com/bangla-date/' })
      else {
        await copyText(`${lastResult}\n${location.href}`)
        $('#copy-feedback').textContent = 'শেয়ার লিংক কপি করা হয়েছে।'
      }
    } catch (error) {
      if (error.name !== 'AbortError') $('#copy-feedback').textContent = 'শেয়ার করা যায়নি।'
    }
  })
  $('#print-result').addEventListener('click', () => window.print())
  $('#age-form').addEventListener('submit', event => {
    event.preventDefault()
    try {
      const birth = $('#birth-date').value
      if (!birth) throw new Error('জন্মতারিখ নির্বাচন করুন।')
      const years = calculateBanglaAge(birth, todayISO)
      $('#age-result').textContent = `আপনার বাংলা হিসাবে পূর্ণ বয়স ${formatBanglaNumber(years)} বছর।`
    } catch (error) {
      $('#age-result').textContent = error.message || 'বয়স হিসাব করা যায়নি।'
    }
  })
  $('#difference-form').addEventListener('submit', event => {
    event.preventDefault()
    try {
      const start = $('#diff-start').value
      const end = $('#diff-end').value
      if (!start || !end) throw new Error('শুরু ও শেষের তারিখ নির্বাচন করুন।')
      const difference = getDaysBetween(start, end)
      const direction = difference.direction < 0 ? ' (শুরুর তারিখটি পরে)' : ''
      $('#difference-result').textContent = `মোট ${formatBanglaNumber(difference.days)} দিন · ${formatBanglaNumber(difference.weeks)} সপ্তাহ ${formatBanglaNumber(difference.remainingDays)} দিন${direction}`
    } catch (error) {
      $('#difference-result').textContent = error.message || 'তারিখের ব্যবধান হিসাব করা যায়নি।'
    }
  })
  $('#theme-toggle').addEventListener('click', () => setTheme(!document.body.classList.contains('dark')))
  try { setTheme(localStorage.getItem('bangla-date-theme') === 'dark') } catch { setTheme(false) }
  renderToday()
}

initialize()
__BANGLA_DATE_SCRIPT_JS__

cat > "$ROOT/sitemap.xml" <<'__BANGLA_DATE_SITEMAP_XML__'
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://rafahim.com/bangla-date/</loc>
    <changefreq>monthly</changefreq>
    <priority>0.9</priority>
  </url>
</urlset>
__BANGLA_DATE_SITEMAP_XML__

cat > "$ROOT/style.css" <<'__BANGLA_DATE_STYLE_CSS__'
@import url('https://fonts.googleapis.com/css2?family=Hind+Siliguri:wght@400;500;600;700&family=Manrope:wght@400;500;600;700;800&display=swap');

:root{font-family:'Hind Siliguri','Noto Sans Bengali',sans-serif;color:#17332d;background:#f5f8f6;font-synthesis:none;text-rendering:optimizeLegibility;--ink:#17332d;--muted:#768780;--green:#0d6b53;--green-dark:#084c3e;--green-soft:#e7f4ee;--line:#e4ece7;--surface:#fff;--canvas:#f5f8f6;--gold:#eebd63;--shadow:0 16px 50px rgba(17,58,45,.07);--radius:22px}
*{box-sizing:border-box}
html{scroll-behavior:smooth}
body{margin:0;background:var(--canvas);color:var(--ink);min-width:320px}
button,input,select{font:inherit}
button,a{-webkit-tap-highlight-color:transparent}
button{cursor:pointer}
a{color:inherit;text-decoration:none}
.site-shell{max-width:1240px;margin:0 auto;padding:0 38px}
.topbar{height:88px;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid rgba(221,232,225,.78)}
.brand{display:flex;align-items:center;gap:12px}.brand-mark{display:grid;place-items:center;width:43px;height:43px;border-radius:14px;background:var(--green);color:white;font-weight:700;font-size:24px;box-shadow:0 8px 18px rgba(13,107,83,.2)}.brand-copy{display:flex;flex-direction:column;line-height:1.25}.brand-copy strong{font-size:17px;font-weight:700;letter-spacing:-.3px}.brand-copy small{font:11px 'Manrope',sans-serif;color:var(--muted);margin-top:4px}.top-actions{display:flex;gap:13px;align-items:center}.standard-pill{display:flex;gap:8px;align-items:center;padding:9px 13px;border:1px solid #dfeae3;border-radius:99px;background:rgba(255,255,255,.62);font-size:12px;color:#587267}.status-dot{width:6px;height:6px;background:#35a779;border-radius:50%;box-shadow:0 0 0 3px #d9f1e4}.icon-button{display:grid;place-items:center;width:40px;height:40px;border:1px solid var(--line);border-radius:13px;background:var(--surface);color:var(--ink);font-size:20px;transition:transform .2s,background .2s}.icon-button:hover{transform:translateY(-2px)}
.hero{display:grid;grid-template-columns:1.16fr .84fr;gap:45px;align-items:center;padding:45px 0 35px;min-height:320px}.eyebrow,.section-kicker{margin:0;color:var(--green);font:700 10px 'Manrope',sans-serif;letter-spacing:1.6px}.eyebrow{display:flex;align-items:center;gap:10px;font-family:'Hind Siliguri',sans-serif;font-size:12px;letter-spacing:.4px}.eyebrow-line{display:inline-block;width:25px;height:2px;background:var(--gold);border-radius:4px}.hero h1{margin:12px 0 13px;font-size:clamp(34px,4.6vw,53px);letter-spacing:-1.7px;line-height:1.13;font-weight:700}.hero h1 span{color:var(--green)}.hero-description{max-width:540px;color:#6b7d75;line-height:1.9;font-size:14px;margin:0}.hero-tags{display:flex;flex-wrap:wrap;gap:9px;margin-top:20px}.hero-tags span{font-size:11px;padding:7px 10px;border-radius:7px;background:#eaf2ed;color:#557367}.hero-art{height:250px;position:relative;display:grid;place-items:center;isolation:isolate}.art-orbit{position:absolute;border:1px solid #d6e8dc;border-radius:50%;transform:rotate(-18deg)}.orbit-one{width:220px;height:220px}.orbit-two{width:285px;height:150px;transform:rotate(30deg)}.art-sun{position:absolute;width:172px;height:172px;border-radius:50%;background:radial-gradient(circle at 35% 30%,#f8db9c,#ebbd68 68%,#dba450);box-shadow:0 15px 38px #e5be7540;z-index:-1}.art-date{height:144px;width:144px;border-radius:50%;display:flex;flex-direction:column;align-items:center;justify-content:center;color:#20513f;background:#fffdf6b8;border:1px solid #ffefc8;backdrop-filter:blur(8px);box-shadow:0 9px 30px #8b733226}.art-date span{font-size:11px}.art-date strong{font-size:48px;line-height:1.25;font-weight:700}.art-date small{font-size:13px}.art-leaf{position:absolute;width:50px;height:22px;background:#74a98a;border-radius:95% 0 95% 0;opacity:.85}.leaf-one{transform:rotate(-36deg);left:14%;top:37%}.leaf-two{transform:rotate(142deg);right:13%;bottom:30%;background:#2c7a5f}.art-floating{position:absolute;color:var(--green);font-size:14px;font-weight:700;background:#fff;border-radius:12px;box-shadow:0 9px 22px #23463814;padding:9px 13px}.floating-one{right:13%;top:16%}.floating-two{left:10%;bottom:12%;font-size:12px}
.dashboard-grid{display:grid;grid-template-columns:minmax(0,1.2fr) minmax(310px,.8fr);gap:21px;align-items:stretch}.panel{background:var(--surface);border:1px solid var(--line);border-radius:var(--radius);box-shadow:var(--shadow)}.converter-panel{padding:27px}.panel-heading{display:flex;justify-content:space-between;align-items:center}.panel-heading h2{font-size:23px;margin:6px 0 0;letter-spacing:-.45px}.panel-icon{font-size:26px;color:var(--green);background:var(--green-soft);width:46px;height:46px;display:grid;place-items:center;border-radius:15px}.mode-switch{display:grid;grid-template-columns:1fr 1fr;padding:5px;background:#f0f5f2;border-radius:12px;margin:23px 0 22px;gap:4px}.mode-tab{border:0;background:transparent;color:#7a8a82;border-radius:8px;padding:11px 9px;font-weight:600;font-size:13px;transition:background .18s,color .18s,box-shadow .18s}.mode-tab.active{background:var(--surface);color:var(--green-dark);box-shadow:0 2px 8px #163c2b10}.field-group>label,.tool-form>label{display:block;font-size:13px;font-weight:600;margin-bottom:8px}.date-input-wrap{position:relative}.field-symbol{position:absolute;left:14px;top:11px;color:var(--green);font-size:17px;pointer-events:none}.field-group input[type=date],.tool-form input[type=date],.bangla-fields input,.bangla-fields select{width:100%;height:46px;border:1px solid #dfe8e2;border-radius:10px;background:var(--surface);padding:0 13px;color:var(--ink);outline:none;transition:border .2s,box-shadow .2s}.field-group input[type=date]{padding-left:42px}.field-group input:focus,.tool-form input:focus,.bangla-fields input:focus,.bangla-fields select:focus{border-color:#72b69c;box-shadow:0 0 0 3px #c8e7d8a0}.field-hint{font-size:11px;color:#98a69f;margin:7px 0 17px}.bangla-fields{display:grid;grid-template-columns:.65fr 1.4fr .95fr;gap:9px}.sub-label{display:block!important;font-size:11px!important;color:#7c8c84!important;font-weight:500!important;margin:0 0 5px!important}.bangla-fields input,.bangla-fields select{padding:0 9px;min-width:0}.primary-button{display:flex;justify-content:center;align-items:center;gap:15px;width:100%;min-height:49px;padding:11px 16px;border:0;border-radius:11px;color:white;background:var(--green);font-size:14px;font-weight:600;box-shadow:0 8px 18px #0d6b5320;transition:background .2s,transform .2s}.primary-button:hover{background:var(--green-dark);transform:translateY(-1px)}.button-arrow{font-size:18px}.form-error{font-size:12px;color:#ba3b3b;min-height:0;margin:0}.form-error:not(:empty){margin-top:9px}.hidden{display:none!important}
.conversion-result{margin-top:23px;background:linear-gradient(135deg,#f1f8f3,#edf7f1);border:1px solid #dcefe2;border-radius:17px;padding:19px 20px 13px;position:relative;overflow:hidden}.conversion-result:after{content:"";position:absolute;right:-36px;top:-47px;width:120px;height:120px;border-radius:50%;border:20px solid #dcefe280;pointer-events:none}.result-topline{display:flex;justify-content:space-between;align-items:center;position:relative;z-index:1}.result-label{font-size:11px;color:#71867a}.result-check{display:grid;place-items:center;width:23px;height:23px;background:#d3eddb;color:var(--green);border-radius:50%;font-size:13px}.result-weekday{color:var(--green);font-size:13px;margin:16px 0 1px}.conversion-result h3{font-size:clamp(19px,2.5vw,25px);font-weight:700;line-height:1.5;margin:0;letter-spacing:-.45px;position:relative;z-index:1}.result-secondary{font-size:12px;color:#819288;margin:3px 0 17px}.result-meta{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;padding:13px 0;border-top:1px solid #d6e8db}.result-meta span{display:flex;flex-direction:column;gap:3px}.result-meta small{font-size:10px;color:#8a9a91}.result-meta strong{font-size:12px;font-weight:600;color:#315e4b}.result-actions{display:flex;gap:8px;border-top:1px solid #d6e8db;padding-top:12px}.utility-button{border:1px solid #d4e5d9;color:#466b59;background:#ffffffa6;border-radius:8px;font-size:11px;padding:7px 12px;transition:background .2s}.utility-button:hover{background:#fff}.copy-feedback{font-size:11px;color:var(--green);margin:6px 0 0;min-height:0}.copy-feedback:not(:empty){min-height:14px}
.side-stack{display:flex;flex-direction:column;gap:15px}.today-card{padding:23px 24px;border-radius:var(--radius);background:linear-gradient(145deg,#0d6b53,#084c3e);color:white;box-shadow:0 17px 35px #0a5e4925;position:relative;overflow:hidden}.today-card:after{content:"";position:absolute;right:-60px;top:30px;width:200px;height:200px;border-radius:50%;border:1px solid #ffffff1c;box-shadow:0 0 0 24px #ffffff08,0 0 0 50px #ffffff05;pointer-events:none}.today-card-top{display:flex;align-items:center;gap:8px;font-size:12px;color:#d7eee3;position:relative;z-index:1}.today-spark{font-size:18px;color:#f1ca7e}.today-live{margin-left:auto;font:700 9px 'Manrope',sans-serif;letter-spacing:1px;border:1px solid #8fceb2a0;border-radius:5px;padding:4px 6px;color:#d4f4e3}.today-weekday{margin:26px 0 1px;font-size:13px;color:#b5dfcb}.today-date-line{display:flex;align-items:center;gap:13px}.today-date-line>strong{font-size:60px;line-height:1.1;letter-spacing:-2px}.today-date-line>div{display:flex;flex-direction:column;gap:4px}.today-date-line span{font-size:19px;font-weight:600}.today-date-line small{font-size:12px;color:#b5dfcb}.today-divider{height:1px;background:#ffffff27;margin:22px 0 13px}.today-bottom{display:flex;align-items:center;justify-content:space-between;gap:12px;font-size:11px;color:#d3e9dd}.season-pill{padding:6px 9px;border:1px solid #ffffff2b;border-radius:99px;color:#f5dfb0}.countdown-card{display:flex;align-items:center;gap:13px;padding:19px;border-radius:18px;background:#fff9ee;border:1px solid #f5e9d0}.countdown-icon{width:44px;height:44px;display:grid;place-items:center;border-radius:14px;background:#f9e8c4;color:#ae7931;font-size:25px;flex:none}.countdown-content{min-width:0;flex:1}.countdown-content .section-kicker{font-size:8px;color:#a87b3e;letter-spacing:1px}.countdown-content h3{font-size:16px;margin:3px 0 0;color:#5e492e}.countdown-content>p:last-child{font-size:11px;color:#a58a65;margin:0}.countdown-count{display:flex;flex-direction:column;align-items:center;min-width:54px;padding-left:13px;border-left:1px solid #eadfc9}.countdown-count strong{font:800 27px 'Manrope',sans-serif;color:#9c6725;line-height:1.1}.countdown-count span{font-size:10px;color:#a58a65}.calendar-note{display:flex;gap:11px;align-items:flex-start;background:#edf4f1;border-radius:13px;padding:13px 15px;color:#71857a}.note-icon{font-size:17px;color:#43856a;line-height:1.4}.calendar-note p{margin:0;font-size:11px;line-height:1.7}.calendar-note strong{color:#3e6452;font-size:12px}
.tools-section{padding:58px 0 38px}.section-header{display:flex;justify-content:space-between;align-items:end;margin-bottom:19px}.section-header h2,.how-copy h2{margin:5px 0 0;font-size:27px;letter-spacing:-.8px}.section-header>p{font-size:12px;color:var(--muted);margin:0 0 4px}.tools-grid{display:grid;grid-template-columns:1fr 1fr 1fr;gap:17px;align-items:stretch}.tool-card,.holiday-card{padding:22px 21px;box-shadow:0 8px 30px rgba(17,58,45,.035)}.tool-title-row{display:flex;align-items:center;gap:12px}.tool-icon{width:42px;height:42px;border-radius:13px;display:grid;place-items:center;flex:none;font-size:12px;font-weight:700}.age-icon{background:#e7f1ff;color:#4875b3}.diff-icon{background:#f5eafa;color:#9364a5;font-size:24px}.tool-title-row h3,.holiday-heading h3{margin:0;font-size:16px;letter-spacing:-.25px}.tool-title-row p{font-size:11px;color:#8a9a92;margin:3px 0 0}.tool-form{margin-top:19px}.tool-form label{font-size:12px;margin-bottom:6px}.tool-form input[type=date]{height:42px;font-size:12px;margin-bottom:12px}.secondary-button{width:100%;height:41px;display:flex;align-items:center;justify-content:space-between;border:1px solid #d7e7dd;background:#f0f7f2;color:#285e48;border-radius:9px;padding:0 12px;font-size:12px;font-weight:600;transition:background .2s}.secondary-button:hover{background:#e1f1e7}.secondary-button span{font-size:16px}.tool-result{font-size:12px;color:#6e8278;background:#f8faf8;border-radius:8px;padding:10px 11px;min-height:39px;margin:10px 0 0;line-height:1.6}.holiday-heading{display:flex;align-items:center;justify-content:space-between}.holiday-heading .section-kicker{font-size:9px}.holiday-heading h3{margin-top:5px}.holiday-icon{display:grid;place-items:center;width:39px;height:39px;background:#fff4df;border-radius:12px;color:#ba843d;font-size:20px}.holiday-year{color:#97a49e;font-size:10px;margin:14px 0 8px}.holiday-list{display:flex;flex-direction:column;gap:0}.holiday-item{display:flex;gap:10px;align-items:center;padding:8px 0;border-bottom:1px solid #edf1ed}.holiday-item:last-child{border-bottom:0}.holiday-date{width:48px;flex:none;border-radius:7px;background:#f2f7f3;color:#3e765b;text-align:center;font-size:11px;font-weight:600;padding:5px 3px}.holiday-name{font-size:11px;color:#536c60;line-height:1.4}.holiday-note{font-size:10px;color:#9ba8a1;line-height:1.6;margin:10px 0 0;border-top:1px solid #edf1ed;padding-top:10px}
.how-section{display:grid;grid-template-columns:1.1fr .9fr;gap:70px;align-items:center;padding:31px 0 58px}.how-copy h2{font-size:25px}.how-copy>p:last-child{font-size:13px;line-height:1.9;color:#788980;margin:12px 0 0;max-width:560px}.rule-list{display:flex;flex-direction:column;gap:12px}.rule-list>div{display:flex;align-items:center;gap:13px;padding:12px 15px;border:1px solid #e2ebe5;border-radius:12px;background:#ffffffa6}.rule-list>div>span{display:grid;place-items:center;width:35px;height:35px;background:#e9f4ed;color:var(--green);font:700 11px 'Manrope',sans-serif;border-radius:10px;flex:none}.rule-list p{margin:0;display:flex;flex-direction:column;gap:3px}.rule-list strong{font-size:12px}.rule-list small{font-size:11px;color:#87978f}.footer{display:flex;align-items:center;gap:20px;padding:22px 0;border-top:1px solid #e1e9e3;color:#8a9a91;font-size:11px}.footer-brand{font:800 12px 'Manrope',sans-serif;color:var(--green)}.footer p{margin:0;flex:1}.footer p a{color:#567765}.footer-links{display:flex;gap:15px}.footer-links a:hover,.footer p a:hover{text-decoration:underline;color:var(--green)}
body.dark{--ink:#e2eee8;--muted:#9aada4;--green:#60c49b;--green-dark:#328c69;--green-soft:#203c31;--line:#2d453a;--surface:#182b23;--canvas:#101d17;--shadow:0 16px 48px rgba(0,0,0,.14);color:var(--ink)}body.dark .topbar{border-color:#263d32}body.dark .standard-pill{background:#1a2c23;border-color:#2f4a3c;color:#b5cabd}body.dark .hero-description,body.dark .section-header>p,body.dark .how-copy>p:last-child{color:#9aada4}body.dark .hero-tags span,body.dark .mode-switch{background:#1e3329;color:#a9c6b6}body.dark .mode-tab{color:#9fb6a8}body.dark .mode-tab.active{background:#304b3c;color:#e5f6ec}body.dark .field-group input[type=date],body.dark .tool-form input[type=date],body.dark .bangla-fields input,body.dark .bangla-fields select{border-color:#385244;background:#132119;color:#e2eee8;color-scheme:dark}body.dark .conversion-result{background:linear-gradient(135deg,#203a2c,#192f24);border-color:#2d4e3a}body.dark .result-meta{border-color:#355541}body.dark .result-meta strong{color:#c0e4ce}body.dark .result-meta small,body.dark .result-secondary,body.dark .result-label{color:#9ab5a4}body.dark .result-check{background:#2a6244;color:#d5f5df}body.dark .result-actions{border-color:#355541}body.dark .utility-button{background:#20372a;border-color:#3b5946;color:#bfd8c6}body.dark .utility-button:hover{background:#2a4634}body.dark .countdown-card{background:#312a1d;border-color:#50432a}body.dark .countdown-icon{background:#4b3c22;color:#f0c778}body.dark .countdown-content h3{color:#f0dfbb}body.dark .countdown-content>p:last-child,body.dark .countdown-count span{color:#c3ae83}body.dark .countdown-count strong{color:#f0c778}body.dark .countdown-count{border-color:#5b4c31}body.dark .calendar-note{background:#1c3026;color:#a8bdb0}body.dark .calendar-note strong{color:#c5e1cf}body.dark .tool-result{background:#1d3026;color:#a4b9ab}body.dark .secondary-button{background:#20382a;border-color:#395846;color:#c3e1cc}body.dark .secondary-button:hover{background:#294835}body.dark .holiday-item{border-color:#2c4035}body.dark .holiday-date{background:#243c2d;color:#add9ba}body.dark .holiday-name{color:#b7cabd}body.dark .holiday-note{border-color:#2c4035;color:#9aada4}body.dark .holiday-icon{background:#473820;color:#f1c574}body.dark .rule-list>div{background:#172920;border-color:#2c4235}body.dark .rule-list>div>span{background:#264a34;color:#b9e4c7}body.dark .rule-list small{color:#9aada4}body.dark .footer{border-color:#263d32;color:#9aada4}body.dark .footer p a{color:#b0cebc}
@media(max-width:1000px){.site-shell{padding:0 25px}.hero{gap:20px}.dashboard-grid{grid-template-columns:minmax(0,1fr) minmax(280px,.82fr)}.converter-panel{padding:22px}.tools-grid{grid-template-columns:1fr 1fr}.holiday-card{grid-column:span 2}.holiday-list{display:grid;grid-template-columns:1fr 1fr;column-gap:18px}.holiday-note{margin-top:6px}.how-section{gap:35px}}
@media(max-width:720px){.site-shell{padding:0 17px}.topbar{height:72px}.brand-mark{width:39px;height:39px}.brand-copy strong{font-size:15px}.brand-copy small{font-size:9px}.standard-pill{font-size:10px;padding:8px}.hero{grid-template-columns:1fr;gap:0;padding:34px 0 26px;min-height:auto}.hero h1{font-size:40px}.hero-art{height:180px;margin-top:1px}.orbit-one{width:165px;height:165px}.orbit-two{width:225px;height:115px}.art-sun{width:130px;height:130px}.art-date{width:110px;height:110px}.art-date strong{font-size:37px}.art-date small{font-size:11px}.floating-one{right:20%;top:6%}.floating-two{left:20%;bottom:0}.dashboard-grid{grid-template-columns:1fr}.side-stack{display:grid;grid-template-columns:1fr 1fr;align-items:stretch}.today-card{grid-column:span 2}.calendar-note{grid-column:span 2}.countdown-card{padding:13px;gap:8px}.countdown-icon{width:34px;height:34px;font-size:19px}.countdown-content h3{font-size:14px}.countdown-content .section-kicker{font-size:7px}.countdown-count{padding-left:8px;min-width:40px}.countdown-count strong{font-size:23px}.tools-section{padding-top:44px}.section-header{align-items:start;gap:10px;flex-direction:column}.section-header h2{font-size:25px}.tools-grid{grid-template-columns:1fr}.holiday-card{grid-column:auto}.holiday-list{grid-template-columns:1fr 1fr}.how-section{grid-template-columns:1fr;gap:21px;padding:18px 0 38px}.how-copy h2{font-size:23px}.footer{flex-wrap:wrap;gap:9px 16px}.footer p{order:3;flex-basis:100%;line-height:1.8}.footer-links{margin-left:auto}}
@media(max-width:400px){.site-shell{padding:0 12px}.hero h1{font-size:35px}.hero-tags{gap:6px}.hero-tags span{font-size:10px;padding:6px 7px}.converter-panel{padding:17px}.panel-heading h2{font-size:20px}.mode-tab{font-size:11px}.result-meta{gap:5px}.result-meta strong{font-size:11px}.result-actions{gap:5px}.utility-button{padding:7px 9px;font-size:10px}.today-card{padding:20px}.today-date-line>strong{font-size:53px}.today-date-line span{font-size:17px}.holiday-list{grid-template-columns:1fr}.standard-pill{gap:5px;padding:7px}.top-actions{gap:7px}}
@media print{body{background:white!important;color:#172e25!important}.site-shell{max-width:100%;padding:0 12px}.topbar,.hero-art,.hero-tags,.mode-switch,#converter-form,.result-actions,.tools-section,.how-section,.footer,.countdown-card,.calendar-note,.icon-button{display:none!important}.hero{padding:10px 0;min-height:auto;display:block}.hero h1{font-size:24px}.dashboard-grid{display:block}.side-stack{display:none}.converter-panel{box-shadow:none;border:0;padding:0}.conversion-result{background:white;border:1px solid #ccc;break-inside:avoid}.result-meta{border-color:#ddd}.result-meta strong,.result-weekday,.conversion-result h3{color:#17332d}.conversion-result:after{display:none}}
__BANGLA_DATE_STYLE_CSS__

cat > "$ROOT/tests/calendar.test.js" <<'__BANGLA_DATE_TESTS_CALENDAR_TEST_JS__'
import test from 'node:test'
import assert from 'node:assert/strict'
import { isGregorianLeapYear, gregorianToBangla, banglaToGregorian, getBanglaMonthLength, getNextPohelaBoishakh, getDaysBetween, toISODate } from '../calendar.js'

test('Gregorian leap-year logic handles century boundaries', () => {
  assert.equal(isGregorianLeapYear(1952), true)
  assert.equal(isGregorianLeapYear(1971), false)
  assert.equal(isGregorianLeapYear(2000), true)
  assert.equal(isGregorianLeapYear(2024), true)
  assert.equal(isGregorianLeapYear(2100), false)
})

test('2019 revised calendar returns known dates across requested years', () => {
  const cases = [
    ['1952-02-21', 1358, 11, 8],
    ['1971-03-26', 1377, 12, 12],
    ['2000-02-21', 1406, 11, 8],
    ['2024-02-21', 1430, 11, 8],
    ['2100-02-28', 1506, 11, 15]
  ]
  for (const [date, year, month, day] of cases) {
    const result = gregorianToBangla(date)
    assert.deepEqual([result.year, result.month, result.day], [year, month, day])
    assert.equal(toISODate(banglaToGregorian(year, month, day)), date)
  }
})

test('Falgun length follows the Gregorian year in which February occurs', () => {
  assert.equal(getBanglaMonthLength(11, 2023), 29)
  assert.equal(getBanglaMonthLength(11, 2024), 30)
  assert.equal(getBanglaMonthLength(11, 2100), 29)
  assert.deepEqual([gregorianToBangla('2023-03-14').month, gregorianToBangla('2023-03-14').day], [11, 29])
  assert.deepEqual([gregorianToBangla('2023-03-15').month, gregorianToBangla('2023-03-15').day], [12, 1])
  assert.deepEqual([gregorianToBangla('2024-03-14').month, gregorianToBangla('2024-03-14').day], [11, 30])
  assert.deepEqual([gregorianToBangla('2024-03-15').month, gregorianToBangla('2024-03-15').day], [12, 1])
  assert.deepEqual([gregorianToBangla('2100-03-14').month, gregorianToBangla('2100-03-14').day], [11, 29])
})

test('Pohela Boishakh boundaries are consistent', () => {
  assert.deepEqual([gregorianToBangla('2024-04-13').year, gregorianToBangla('2024-04-13').month, gregorianToBangla('2024-04-13').day], [1430, 12, 30])
  assert.deepEqual([gregorianToBangla('2024-04-14').year, gregorianToBangla('2024-04-14').month, gregorianToBangla('2024-04-14').day], [1431, 1, 1])
  assert.equal(toISODate(getNextPohelaBoishakh('2024-04-13')), '2024-04-14')
  assert.equal(toISODate(getNextPohelaBoishakh('2024-04-14')), '2024-04-14')
  assert.equal(toISODate(getNextPohelaBoishakh('2024-04-15')), '2025-04-14')
})

test('date conversion round-trips for sample dates around year edges', () => {
  const dates = ['1952-01-01', '1952-04-13', '1952-04-14', '1971-03-26', '1971-04-14', '2000-02-29', '2000-12-31', '2024-02-29', '2024-04-13', '2024-04-14', '2100-03-15', '2100-04-13', '2100-04-14']
  for (const date of dates) {
    const bangla = gregorianToBangla(date)
    assert.equal(toISODate(banglaToGregorian(bangla.year, bangla.month, bangla.day)), date)
  }
})

test('invalid dates and impossible Bangla dates are rejected', () => {
  assert.throws(() => gregorianToBangla('2024-02-30'), RangeError)
  assert.throws(() => banglaToGregorian(1429, 11, 30), RangeError)
  assert.throws(() => banglaToGregorian(1431, 1, 32), RangeError)
})

test('day differences are absolute and retain direction', () => {
  assert.deepEqual(getDaysBetween('2024-04-14', '2024-04-01'), { days: 13, weeks: 1, remainingDays: 6, direction: -1 })
})

test('every day round-trips through the revised calendar in required test years', () => {
  for (const year of [1952, 1971, 2000, 2024, 2100]) {
    const start = new Date(Date.UTC(year, 0, 1))
    const end = new Date(Date.UTC(year + 1, 0, 1))
    for (let time = start.getTime(); time < end.getTime(); time += 86400000) {
      const date = new Date(time).toISOString().slice(0, 10)
      const bangla = gregorianToBangla(date)
      assert.equal(toISODate(banglaToGregorian(bangla.year, bangla.month, bangla.day)), date, `${date} round-trip`)
    }
  }
})
__BANGLA_DATE_TESTS_CALENDAR_TEST_JS__

ZIP_PATH="$ROOT.zip"
rm -f "$ZIP_PATH"
if command -v zip >/dev/null 2>&1; then
  zip -qr "$ZIP_PATH" . -x "./.git/*" "./node_modules/*"
elif command -v python3 >/dev/null 2>&1; then
  python3 - "$ROOT" "$ZIP_PATH" <<'PYZIP'
import pathlib, sys, zipfile
root = pathlib.Path(sys.argv[1])
target = pathlib.Path(sys.argv[2])
with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as archive:
    for file in sorted(root.rglob("*")):
        if file.is_file() and ".git" not in file.parts and "node_modules" not in file.parts:
            archive.write(file, file.relative_to(root.parent))
PYZIP
else
  printf "%s\n" "Need zip or Python 3 to build the project archive." >&2
  exit 1
fi
printf "Project files regenerated. Archive: %s\n" "$ZIP_PATH"
