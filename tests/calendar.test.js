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
