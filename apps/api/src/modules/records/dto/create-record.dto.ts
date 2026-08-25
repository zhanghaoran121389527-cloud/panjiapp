import { Transform } from 'class-transformer';
import {
  IsArray,
  IsInt,
  IsOptional,
  IsString,
  Length,
  Matches,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;
const UPLOAD_URL_RE = /^\/uploads\/[A-Za-z0-9.-]+$/;

const trim = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() : value;

const trimToNull = ({ value }: { value: unknown }) => {
  if (typeof value !== 'string') return value;
  const t = value.trim();
  return t === '' ? null : t;
};

export class CreateRecordDto {
  /** 契约 3.11：0~N 张，先经上传接口拿到相对 URL，sort_order=数组下标。 */
  @IsOptional()
  @IsArray({ message: 'photoUrls 需为数组' })
  @IsString({ each: true, message: 'photoUrls 元素需为字符串' })
  @Matches(UPLOAD_URL_RE, {
    each: true,
    message: 'photoUrls 需为 /uploads/ 相对 URL',
  })
  photoUrls?: string[];

  @Transform(trim)
  @IsString({ message: '一句话需为字符串' })
  @Length(1, 500, { message: '一句话需为 1~500 字' })
  content!: string;

  @IsOptional()
  @IsInt({ message: '盘玩时长需为整数分钟' })
  @Min(1, { message: '盘玩时长至少 1 分钟' })
  @Max(1440, { message: '盘玩时长不能超过 1440 分钟' })
  durationMinutes?: number;

  @Transform(trimToNull)
  @IsOptional()
  @IsString({ message: '盘玩方式需为字符串' })
  @MaxLength(20, { message: '盘玩方式不能超过 20 字' })
  method: string | null;

  /** 选填，默认今天；过去日期=补录；不得晚于北京时间今天（裁决 A10）。 */
  @IsOptional()
  @Matches(DATE_RE, { message: '记录日期格式需为 YYYY-MM-DD' })
  recordedDate?: string;
}
