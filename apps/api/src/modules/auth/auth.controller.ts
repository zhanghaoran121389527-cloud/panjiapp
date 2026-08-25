import { Body, Controller, HttpCode, Post } from '@nestjs/common';
import { ApiError } from '../../common/api-error';
import { Public } from '../../common/public.decorator';
import { config } from '../../config';
import { AuthService, DevLoginResult } from './auth.service';
import { DevLoginDto } from './dto/dev-login.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Post('dev-login')
  @HttpCode(200) // 契约 3.1：200（Nest POST 默认 201，需显式声明）
  devLogin(@Body() dto: DevLoginDto): Promise<DevLoginResult> {
    // 安全门：生产环境禁用 Dev Login（正式登录另行实现）；404 不暴露路由存在性
    if (config.nodeEnv === 'production') {
      throw new ApiError(404, 'NOT_FOUND', '资源不存在');
    }
    return this.authService.devLogin(dto);
  }
}
