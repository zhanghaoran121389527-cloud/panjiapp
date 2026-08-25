import { Transform } from 'class-transformer';
import {
  IsOptional,
  IsString,
  IsUUID,
  Length,
  Matches,
  MaxLength,
} from 'class-validator';

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;
const UPLOAD_URL_RE = /^\/uploads\/[A-Za-z0-9.-]+$/;

const trim = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() : value;

/** 可选文本：trim 后空串归一为 null（契约：可选字段一律 null，不用空字符串）。 */
const trimToNull = ({ value }: { value: unknown }) => {
  if (typeof value !== 'string') return value;
  const t = value.trim();
  return t === '' ? null : t;
};

export class CreateItemDto {
  @Transform(trim)
  @IsString({ message: '名称需为字符串' })
  @Length(1, 50, { message: '名称需为 1~50 字' })
  name!: string;

  @IsUUID('4', { message: 'categoryId 需为 UUID' })
  categoryId!: string;

  @Transform(trimToNull)
  @IsOptional()
  @IsString({ message: '封面需为字符串' })
  @Matches(UPLOAD_URL_RE, { message: '封面需为 /uploads/ 相对 URL' })
  @MaxLength(1000, { message: '封面 URL 过长' })
  coverImageUrl: string | null;

  @Transform(trimToNull)
  @IsOptional()
  @IsString({ message: '子类需为字符串' })
  @MaxLength(50, { message: '子类不能超过 50 字' })
  subcategory: string | null;

  @Transform(trimToNull)
  @IsOptional()
  @IsString({ message: '尺寸需为字符串' })
  @MaxLength(100, { message: '尺寸/规格不能超过 100 字' })
  sizeSpec: string | null;

  @Transform(trimToNull)
  @IsOptional()
  @Matches(DATE_RE, { message: '入手日期格式需为 YYYY-MM-DD' })
  acquiredDate: string | null;

  @Transform(trimToNull)
  @IsOptional()
  @IsString({ message: '备注需为字符串' })
  @MaxLength(500, { message: '备注不能超过 500 字' })
  notes: string | null;
}
