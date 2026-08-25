export type ErrorCode =
  | 'AUTH_REQUIRED'
  | 'VALIDATION_ERROR'
  | 'NOT_FOUND'
  | 'UPLOAD_TOO_LARGE'
  | 'UNSUPPORTED_TYPE'
  | 'INTERNAL';

/** 统一业务错误：HTTP 状态码 + 契约错误码 + 人类可读描述。 */
export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly code: ErrorCode,
    message: string,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}
