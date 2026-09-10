export type WeekStart = 'monday' | 'tuesday' | 'wednesday' | 'thursday' | 'friday' | 'saturday' | 'sunday' | 'rolling_7_days';

const weekDayIndex: Record<Exclude<WeekStart, 'rolling_7_days'>, number> = {
  sunday: 0,
  monday: 1,
  tuesday: 2,
  wednesday: 3,
  thursday: 4,
  friday: 5,
  saturday: 6,
};

export function weekWindowStart(preference: WeekStart, now = new Date()) {
  if (preference === 'rolling_7_days') return new Date(now.getTime() - 7 * 86400000);
  const start = new Date(now);
  start.setHours(0, 0, 0, 0);
  start.setDate(start.getDate() - ((start.getDay() - weekDayIndex[preference] + 7) % 7));
  return start;
}

export function isWithinWeekWindow(value: string | Date, preference: WeekStart, now = new Date()) {
  const date = typeof value === 'string' ? new Date(value) : value;
  return date >= weekWindowStart(preference, now) && date <= now;
}
