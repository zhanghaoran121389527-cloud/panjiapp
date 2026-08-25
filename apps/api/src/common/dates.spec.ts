import { dayCount, isValidDateString, todayBeijing } from './dates';

describe('dates（北京时间）', () => {
  it('todayBeijing 返回 YYYY-MM-DD', () => {
    expect(todayBeijing()).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  });

  it('dayCount：无记录 = 0', () => {
    expect(dayCount(null, '2025-01-10')).toBe(0);
  });

  it('dayCount：当天首记 = 1', () => {
    expect(dayCount('2025-01-10', '2025-01-10')).toBe(1);
  });

  it('dayCount：最早记录 3 天前 = 4', () => {
    expect(dayCount('2025-01-07', '2025-01-10')).toBe(4);
  });

  it('dayCount：跨月/跨年边界', () => {
    expect(dayCount('2024-12-31', '2025-01-01')).toBe(2);
  });

  it('isValidDateString：拒绝格式错误与不存在的日期', () => {
    expect(isValidDateString('2025-02-30')).toBe(false);
    expect(isValidDateString('2025-13-01')).toBe(false);
    expect(isValidDateString('2025-1-2')).toBe(false);
    expect(isValidDateString('2025-02-28')).toBe(true);
    expect(isValidDateString('2024-02-29')).toBe(true);
    expect(isValidDateString('not-a-date')).toBe(false);
  });
});
