import { Transform } from 'class-transformer';
import { IsString, Length } from 'class-validator';

export class UpdateNicknameDto {
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString({ message: '昵称需为字符串' })
  @Length(1, 20, { message: '昵称需为 1~20 字' })
  nickname!: string;
}
