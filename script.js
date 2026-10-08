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
