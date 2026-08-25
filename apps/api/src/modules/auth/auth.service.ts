import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, Repository } from 'typeorm';
import { AuthIdentity } from '../../entities/auth-identity.entity';
import { User } from '../../entities/user.entity';
import { DevLoginDto } from './dto/dev-login.dto';

export interface AuthUserDto {
  id: string;
  nickname: string | null;
}

export interface DevLoginResult {
  token: string;
  user: AuthUserDto;
  isNewUser: boolean;
}

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(AuthIdentity)
    private readonly identities: Repository<AuthIdentity>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    private readonly dataSource: DataSource,
    private readonly jwt: JwtService,
  ) {}

  /** 契约 3.1：provider='dev' + identifier=phone 查身份；无则建 user + identity。无短信。 */
  async devLogin(dto: DevLoginDto): Promise<DevLoginResult> {
    const identity = await this.identities.findOne({
      where: { provider: 'dev', identifier: dto.phone },
    });
    if (identity) {
      const user = await this.users.findOneByOrFail({ id: identity.userId });
      return this.buildResult(user, false);
    }

    // ponytail: 同号并发首登会撞 UNIQUE(provider,identifier)；M1 单客户端场景可接受
    const user = await this.dataSource.transaction(async (em) => {
      const created = em.create(User, { nickname: null });
      await em.save(created);
      const ident = em.create(AuthIdentity, {
        userId: created.id,
        provider: 'dev',
        identifier: dto.phone,
      });
      await em.save(ident);
      return created;
    });
    return this.buildResult(user, true);
  }

  private buildResult(user: User, isNewUser: boolean): DevLoginResult {
    const token = this.jwt.sign({}, { subject: user.id });
    return {
      token,
      user: { id: user.id, nickname: user.nickname },
      isNewUser,
    };
  }
}
