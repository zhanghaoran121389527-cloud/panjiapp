import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ApiError } from '../../common/api-error';
import { User } from '../../entities/user.entity';
import { UpdateNicknameDto } from './dto/update-nickname.dto';

export interface UserDto {
  id: string;
  nickname: string | null;
}

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly users: Repository<User>,
  ) {}

  async getById(id: string): Promise<UserDto> {
    const user = await this.users.findOneBy({ id });
    if (!user) throw new ApiError(404, 'NOT_FOUND', '用户不存在');
    return this.toDto(user);
  }

  async updateNickname(id: string, dto: UpdateNicknameDto): Promise<UserDto> {
    const user = await this.users.findOneBy({ id });
    if (!user) throw new ApiError(404, 'NOT_FOUND', '用户不存在');
    user.nickname = dto.nickname;
    await this.users.save(user);
    return this.toDto(user);
  }

  private toDto(user: User): UserDto {
    return { id: user.id, nickname: user.nickname };
  }
}
