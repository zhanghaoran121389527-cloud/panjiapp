import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';
import { ApiError } from './api-error';
import { IS_PUBLIC_KEY } from './public.decorator';

export interface AuthedRequest extends Request {
  user: { id: string };
}

/**
 * 全局登录守卫：默认全部接口需要 Bearer JWT（payload { sub: userId }），
 * @Public() 标记的接口除外。失败一律 AUTH_REQUIRED。
 */
@Injectable()
export class AuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly jwt: JwtService,
  ) {}

  canActivate(context: ExecutionContext): boolean {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;

    const request = context.switchToHttp().getRequest<AuthedRequest>();
    const header = request.headers.authorization ?? '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : '';
    if (!token) throw new ApiError(401, 'AUTH_REQUIRED', '请先登录');

    try {
      const payload = this.jwt.verify<{ sub: string }>(token);
      request.user = { id: payload.sub };
      return true;
    } catch {
      throw new ApiError(401, 'AUTH_REQUIRED', '登录已失效，请重新登录');
    }
  }
}
