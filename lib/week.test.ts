import { strict as assert } from 'node:assert';
import test from 'node:test';
import { isWithinWeekWindow, weekWindowStart, type WeekStart } from './week.ts';

function localParts(value: Date) {
  return [value.getFullYear(), value.getMonth(), value.getDate(), value.getHours(), value.getMinutes(), value.getSeconds(), value.getMilliseconds()];
}

test('fixed weekday preferences start at local midnight on the most recent matching day', () => {
  const thursdayAfternoon = new Date(2026, 8, 10, 15, 30);
  const expectedDates: Record<Exclude<WeekStart, 'rolling_7_days'>, number> = {
    monday: 7,
    tuesday: 8,
    wednesday: 9,
    thursday: 10,
    friday: 4,
    saturday: 5,
    sunday: 6,
  };

  for (const [preference, expectedDate] of Object.entries(expectedDates)) {
    assert.deepEqual(
      localParts(weekWindowStart(preference as Exclude<WeekStart, 'rolling_7_days'>, thursdayAfternoon)),
      [2026, 8, expectedDate, 0, 0, 0, 0],
    );
  }
});

test('rolling preference starts exactly seven days ago', () => {
  const now = new Date(2026, 8, 10, 15, 30, 45, 123);
  assert.equal(now.getTime() - weekWindowStart('rolling_7_days', now).getTime(), 7 * 86400000);
});

test('calendar windows include their boundary and exclude prior and future sessions', () => {
  const now = new Date(2026, 8, 10, 15, 30);
  assert.equal(isWithinWeekWindow(new Date(2026, 8, 7, 0, 0), 'monday', now), true);
  assert.equal(isWithinWeekWindow(new Date(2026, 8, 6, 23, 59), 'monday', now), false);
  assert.equal(isWithinWeekWindow(new Date(2026, 8, 6, 12, 0), 'sunday', now), true);
  assert.equal(isWithinWeekWindow(new Date(2026, 8, 10, 15, 31), 'monday', now), false);
});

test('rolling windows include exactly seven days ago but not an earlier instant', () => {
  const now = new Date(2026, 8, 10, 15, 30);
  const boundary = new Date(now.getTime() - 7 * 86400000);
  assert.equal(isWithinWeekWindow(boundary, 'rolling_7_days', now), true);
  assert.equal(isWithinWeekWindow(new Date(boundary.getTime() - 1), 'rolling_7_days', now), false);
});
