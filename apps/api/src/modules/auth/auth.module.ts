import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthIdentity } from '../../entities/auth-identity.entity';
import { User } from '../../entities/user.entity';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';

@Module({
  imports: [TypeOrmModule.forFeature([AuthIdentity, User])],
  controllers: [AuthController],
  providers: [AuthService],
})
export class AuthModule {}
