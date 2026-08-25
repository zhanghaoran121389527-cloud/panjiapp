import { Transform } from 'class-transformer';
import {
  IsOptional,
  IsString,
  IsUUID,
  Length,
  Matches,
  MaxLength,
  ValidateIf,
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

/**
 * 契约 3.8：部分更新；可选字段传 null 清空。
 * name/categoryId 为必填语义：null 不合法；undefined 表示不更新。
 * 其余可选字段：@IsOptional 下 null/undefined 均跳过，空串已归一为 null。
 */
export class UpdateItemDto {
  @ValidateIf((o: UpdateItemDto) => o.name !== undefined)
  @Transform(trim)
  @IsString({ message: '名称需为字符串' })
  @Length(1, 50, { message: '名称需为 1~50 字' })
  name?: string;

  @ValidateIf((o: UpdateItemDto) => o.categoryId !== undefined)
  @IsUUID('4', { message: 'categoryId 需为 UUID' })
  categoryId?: string;

  @Transform(trimToNull)
  @IsOptional()
  @IsString({ message: '封面需为字符串' })
  @Matches(UPLOAD_URL_RE, { message: '封面需为 /uploads/ 相对 URL' })
  @MaxLength(1000, { message: '封面 URL 过长' })
  coverImageUrl?: string | null;

  @Transform(trimToNull)
  @IsOptional()
  @IsString({ message: '子类需为字符串' })
  @MaxLength(50, { message: '子类不能超过 50 字' })
  subcategory?: string | null;

  @Transform(trimToNull)
  @IsOptional()
  @IsString({ message: '尺寸需为字符串' })
  @MaxLength(100, { message: '尺寸/规格不能超过 100 字' })
  sizeSpec?: string | null;

  @Transform(trimToNull)
  @IsOptional()
  @Matches(DATE_RE, { message: '入手日期格式需为 YYYY-MM-DD' })
  acquiredDate?: string | null;

  @Transform(trimToNull)
  @IsOptional()
  @IsString({ message: '备注需为字符串' })
  @MaxLength(500, { message: '备注不能超过 500 字' })
  notes?: string | null;
}
