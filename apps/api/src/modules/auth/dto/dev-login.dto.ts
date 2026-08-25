import { Transform } from 'class-transformer';
import { Matches } from 'class-validator';

export class DevLoginDto {
  @Matches(/^\d{11}$/, { message: '手机号需为 11 位数字' })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  phone!: string;
}
