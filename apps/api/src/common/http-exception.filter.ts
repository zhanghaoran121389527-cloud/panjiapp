import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
  PayloadTooLargeException,
} from '@nestjs/common';
import { Response } from 'express';
import { ApiError, ErrorCode } from './api-error';

/**
 * 全局异常过滤器：所有错误统一输出 { code, message }（API_CONTRACT §1）。
 */
@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger('HttpExceptionFilter');

  catch(exception: unknown, host: ArgumentsHost): void {
    const res = host.switchToHttp().getResponse<Response>();
    let status: number = HttpStatus.INTERNAL_SERVER_ERROR;
    let code: ErrorCode = 'INTERNAL';
    let message = '服务器内部错误';

    if (exception instanceof ApiError) {
      status = exception.status;
      code = exception.code;
      message = exception.message;
    } else if (exception instanceof PayloadTooLargeException) {
      status = HttpStatus.PAYLOAD_TOO_LARGE;
      code = 'UPLOAD_TOO_LARGE';
      message = '图片大小不能超过 10MB';
    } else if (exception instanceof HttpException) {
      status = exception.getStatus();
      const body = exception.getResponse();
      if (
        typeof body === 'object' &&
        body !== null &&
        'code' in body &&
        'message' in body
      ) {
        code = (body as { code: ErrorCode }).code;
        message = (body as { message: string }).message;
      } else if (status === HttpStatus.NOT_FOUND) {
        code = 'NOT_FOUND';
        message = '资源不存在';
      } else if (status === HttpStatus.UNAUTHORIZED) {
        code = 'AUTH_REQUIRED';
        message = '请先登录';
      } else if (status === HttpStatus.BAD_REQUEST) {
        code = 'VALIDATION_ERROR';
        message =
          typeof body === 'object' &&
          body !== null &&
          'message' in body &&
          typeof (body as { message: unknown }).message === 'string'
            ? ((body as { message: string }).message)
            : '请求参数不合法';
      } else {
        code = 'INTERNAL';
        message = '请求处理失败';
      }
    } else {
      this.logger.error(
        exception instanceof Error ? exception.stack : String(exception),
      );
    }

    res.status(status).json({ code, message });
  }
}
