import { JwtService } from '@nestjs/jwt';
import { NestExpressApplication } from '@nestjs/platform-express';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app-setup';

/**
 * M0-002 验收（TASKS.md M0-002）：
 * ① 启动 ② health 通过 ③ 未知路由返回契约错误格式 ④ JWT 签发/校验自测通过。
 * 前置：本地 PostgreSQL 已启动（DATABASE_URL 可达；本测试不建表、不改数据）。
 */
describe('M0-002 工程底座 e2e', () => {
  let app: NestExpressApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication<NestExpressApplication>();
    configureApp(app);
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('① 应用可启动，GET /v1/health 返回 {"status":"ok"}', async () => {
    const res = await request(app.getHttpServer()).get('/v1/health');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'ok' });
  });

  it('② 未知路由返回统一错误结构 {code,message}，code=NOT_FOUND', async () => {
    const res = await request(app.getHttpServer()).get('/v1/does-not-exist');
    expect(res.status).toBe(404);
    expect(res.body).toEqual({ code: 'NOT_FOUND', message: '资源不存在' });
  });

  it('③ 无 token / 篡改 token 访问受保护接口 → 401 AUTH_REQUIRED（统一结构）', async () => {
    const noToken = await request(app.getHttpServer()).get('/v1/me');
    expect(noToken.status).toBe(401);
    expect(noToken.body.code).toBe('AUTH_REQUIRED');
    expect(typeof noToken.body.message).toBe('string');

    const jwt = app.get(JwtService);
    const token = jwt.sign({}, { subject: '00000000-0000-4000-8000-000000000001' });
    const tampered = await request(app.getHttpServer())
      .get('/v1/me')
      .set('Authorization', `Bearer ${token.slice(0, -2)}xx`);
    expect(tampered.status).toBe(401);
    expect(tampered.body.code).toBe('AUTH_REQUIRED');
  });

  it('④ JWT 签发/校验自测：HS256、payload {sub}、365 天', async () => {
    const jwt = app.get(JwtService);
    const sub = '00000000-0000-4000-8000-000000000001';
    const token = jwt.sign({}, { subject: sub });
    const payload = jwt.verify<{ sub: string }>(token);
    expect(payload.sub).toBe(sub);
    expect(jwt.decode(token)).toMatchObject({
      sub,
      exp: expect.any(Number),
    });
    // 365 天有效期
    const decoded = jwt.decode(token) as { iat: number; exp: number };
    expect(decoded.exp - decoded.iat).toBe(365 * 24 * 3600);
  });
});
