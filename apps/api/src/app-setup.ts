import { ValidationPipe } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import { mkdirSync } from 'fs';
import { resolve } from 'path';
import { ApiError } from './common/api-error';
import { config } from './config';

/** main.ts 与 e2e 共用的应用装配：前缀 /v1、校验管道、/uploads 静态托管。 */
export function configureApp(app: NestExpressApplication): void {
  app.setGlobalPrefix('v1');

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // 剥离 DTO 之外的字段
      transform: true,
      exceptionFactory: (errors) => {
        const first = errors[0];
        const message = first?.constraints
          ? Object.values(first.constraints)[0]
          : '请求参数不合法';
        return new ApiError(400, 'VALIDATION_ERROR', message);
      },
    }),
  );

  // 静态托管上传图片：/uploads/<uuid>.<ext>（resolve 兼容绝对路径 UPLOAD_DIR）
  const uploadDir = resolve(process.cwd(), config.uploadDir);
  mkdirSync(uploadDir, { recursive: true });
  app.useStaticAssets(uploadDir, { prefix: '/uploads' });
}
