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
