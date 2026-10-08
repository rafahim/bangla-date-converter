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
