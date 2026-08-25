/**
 * 日期工具：全部按北京时间（Asia/Shanghai）解释（契约裁决 A8）。
 * date 列为 'YYYY-MM-DD' 字符串，不做时区转换。
 */

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

/** 北京时间的"今天"，'YYYY-MM-DD'。 */
export function todayBeijing(): string {
  return new Date(Date.now() + 8 * 3600 * 1000).toISOString().slice(0, 10);
}

/** 是否为真实存在的日历日期（格式 + 合法性，如 2025-02-30 为假）。 */
export function isValidDateString(value: string): boolean {
  if (!DATE_RE.test(value)) return false;
  const d = new Date(`${value}T00:00:00Z`);
  return !Number.isNaN(d.getTime()) && d.toISOString().slice(0, 10) === value;
}

/**
 * 盘玩天数（契约 4.1）：有记录 = 今天 − min(recorded_date) 天数 + 1；无记录 = 0。
 * 入参均为 'YYYY-MM-DD'；Date.parse 按 UTC 午夜解释，差值不涉及时区。
 */
export function dayCount(minRecordedDate: string | null, today: string): number {
  if (!minRecordedDate) return 0;
  const diffDays = Math.round(
    (Date.parse(today) - Date.parse(minRecordedDate)) / 86400000,
  );
  return diffDays + 1;
}
