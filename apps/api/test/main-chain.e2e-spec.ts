import { NestExpressApplication } from '@nestjs/platform-express';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { DataSource } from 'typeorm';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app-setup';
import { todayBeijing } from '../src/common/dates';
import { buildDataSourceOptions } from '../src/data-source';

const PNG_1PX = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  'base64',
);

const WALNUT_ID = 'a1b2c3d4-0001-4000-8000-000000000001';
const RANDOM_UUID = '00000000-0000-4000-8000-000000000000';

function beijingDaysAgo(n: number): string {
  return new Date(Date.now() + 8 * 3600 * 1000 - n * 86400000)
    .toISOString()
    .slice(0, 10);
}

describe('盘迹 M1 主链 e2e（契约 v2.2）', () => {
  let app: NestExpressApplication;
  let ds: DataSource;
  let tokenA: string;
  let tokenB: string;
  let userIdA: string;
  let itemId: string;

  beforeAll(async () => {
    // 每次运行重建 schema（embedded PG 由 global-setup 起在 5433）
    ds = new DataSource(buildDataSourceOptions());
    await ds.initialize();
    await ds.query('DROP SCHEMA public CASCADE');
    await ds.query('CREATE SCHEMA public');
    await ds.runMigrations();

    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication<NestExpressApplication>();
    configureApp(app);
    await app.init();
  });

  afterAll(async () => {
    await app.close();
    await ds.destroy();
  });

  const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

  it('health 公开可用', async () => {
    const res = await request(app.getHttpServer()).get('/v1/health');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'ok' });
  });

  it('未知路由返回统一 NOT_FOUND', async () => {
    const res = await request(app.getHttpServer()).get('/v1/does-not-exist');
    expect(res.status).toBe(404);
    expect(res.body).toEqual({ code: 'NOT_FOUND', message: '资源不存在' });
  });

  it('dev-login：手机号校验（11 位数字）', async () => {
    const bad = await request(app.getHttpServer())
      .post('/v1/auth/dev-login')
      .send({ phone: '12345' });
    expect(bad.status).toBe(400);
    expect(bad.body.code).toBe('VALIDATION_ERROR');
  });

  it('dev-login：新号 isNewUser=true，返回 token', async () => {
    const res = await request(app.getHttpServer())
      .post('/v1/auth/dev-login')
      .send({ phone: '13800138000' });
    expect(res.status).toBe(200);
    expect(res.body.isNewUser).toBe(true);
    expect(res.body.token).toEqual(expect.any(String));
    expect(res.body.user).toEqual({ id: expect.any(String), nickname: null });
    tokenA = res.body.token;
    userIdA = res.body.user.id;
  });

  it('dev-login：同号再登录 isNewUser=false，昵称保留', async () => {
    await request(app.getHttpServer())
      .patch('/v1/me')
      .set(auth(tokenA))
      .send({ nickname: '盘友小王' })
      .expect(200);

    const res = await request(app.getHttpServer())
      .post('/v1/auth/dev-login')
      .send({ phone: '13800138000' });
    expect(res.status).toBe(200);
    expect(res.body.isNewUser).toBe(false);
    expect(res.body.user).toEqual({ id: userIdA, nickname: '盘友小王' });
  });

  it('受保护接口：无 token / 坏 token 一律 AUTH_REQUIRED', async () => {
    const noToken = await request(app.getHttpServer()).get('/v1/me');
    expect(noToken.status).toBe(401);
    expect(noToken.body.code).toBe('AUTH_REQUIRED');

    const badToken = await request(app.getHttpServer())
      .get('/v1/me')
      .set(auth('invalid.token.here'));
    expect(badToken.status).toBe(401);
    expect(badToken.body.code).toBe('AUTH_REQUIRED');
  });

  it('GET /me 返回当前用户', async () => {
    const res = await request(app.getHttpServer())
      .get('/v1/me')
      .set(auth(tokenA));
    expect(res.status).toBe(200);
    expect(res.body.user).toEqual({ id: userIdA, nickname: '盘友小王' });
  });

  it('PATCH /me：昵称 1~20 字校验', async () => {
    const ok = await request(app.getHttpServer())
      .patch('/v1/me')
      .set(auth(tokenA))
      .send({ nickname: '新昵称' });
    expect(ok.status).toBe(200);
    expect(ok.body.user.nickname).toBe('新昵称');

    const tooLong = await request(app.getHttpServer())
      .patch('/v1/me')
      .set(auth(tokenA))
      .send({ nickname: '一'.repeat(21) });
    expect(tooLong.status).toBe(400);
    expect(tooLong.body.code).toBe('VALIDATION_ERROR');

    const blank = await request(app.getHttpServer())
      .patch('/v1/me')
      .set(auth(tokenA))
      .send({ nickname: '     ' });
    expect(blank.status).toBe(400);
  });

  it('GET /categories：公开，固定 5 品类按 sort_order', async () => {
    const res = await request(app.getHttpServer()).get('/v1/categories');
    expect(res.status).toBe(200);
    expect(res.body.categories).toEqual([
      { id: WALNUT_ID, name: '核桃' },
      { id: 'a1b2c3d4-0002-4000-8000-000000000002', name: '菩提' },
      { id: 'a1b2c3d4-0003-4000-8000-000000000003', name: '木质' },
      { id: 'a1b2c3d4-0004-4000-8000-000000000004', name: '玉石' },
      { id: 'a1b2c3d4-0005-4000-8000-000000000005', name: '其他' },
    ]);
  });

  it('GET /items：新用户为空', async () => {
    const res = await request(app.getHttpServer())
      .get('/v1/items')
      .set(auth(tokenA));
    expect(res.status).toBe(200);
    expect(res.body.items).toEqual([]);
  });

  it('POST /items：创建校验（名称/品类）', async () => {
    const noName = await request(app.getHttpServer())
      .post('/v1/items')
      .set(auth(tokenA))
      .send({ categoryId: WALNUT_ID });
    expect(noName.status).toBe(400);
    expect(noName.body.code).toBe('VALIDATION_ERROR');

    const badCategory = await request(app.getHttpServer())
      .post('/v1/items')
      .set(auth(tokenA))
      .send({ name: '四座楼狮子头', categoryId: RANDOM_UUID });
    expect(badCategory.status).toBe(400);
    expect(badCategory.body).toEqual({
      code: 'VALIDATION_ERROR',
      message: '品类不存在',
    });
  });

  it('POST /items：创建成功返回完整对象，dayCount=0', async () => {
    const res = await request(app.getHttpServer())
      .post('/v1/items')
      .set(auth(tokenA))
      .send({
        name: '四座楼狮子头',
        categoryId: WALNUT_ID,
        subcategory: '狮子头',
        sizeSpec: '边 42 肚 42 高 38',
        notes: '第一对核桃',
      });
    expect(res.status).toBe(201);
    expect(res.body.item).toMatchObject({
      name: '四座楼狮子头',
      categoryId: WALNUT_ID,
      coverImageUrl: null,
      subcategory: '狮子头',
      sizeSpec: '边 42 肚 42 高 38',
      acquiredDate: null,
      notes: '第一对核桃',
      dayCount: 0,
    });
    itemId = res.body.item.id;
  });

  it('GET /items：仅当前用户，createdAt 倒序，dayCount=0', async () => {
    const res = await request(app.getHttpServer())
      .get('/v1/items')
      .set(auth(tokenA));
    expect(res.status).toBe(200);
    expect(res.body.items).toHaveLength(1);
    expect(res.body.items[0]).toMatchObject({
      id: itemId,
      name: '四座楼狮子头',
      dayCount: 0,
    });
  });

  it('GET /items/:id：详情不含 records，越权/非法 id 防护', async () => {
    const res = await request(app.getHttpServer())
      .get(`/v1/items/${itemId}`)
      .set(auth(tokenA));
    expect(res.status).toBe(200);
    expect(res.body.item.dayCount).toBe(0);
    expect(res.body.item).not.toHaveProperty('records');

    const badUuid = await request(app.getHttpServer())
      .get('/v1/items/not-a-uuid')
      .set(auth(tokenA));
    expect(badUuid.status).toBe(400);
    expect(badUuid.body.code).toBe('VALIDATION_ERROR');
  });

  it('POST records：默认日期=今天，dayCount 变 1', async () => {
    const res = await request(app.getHttpServer())
      .post(`/v1/items/${itemId}/records`)
      .set(auth(tokenA))
      .send({ content: '刚到手，先记录一下。' });
    expect(res.status).toBe(201);
    expect(res.body.record).toMatchObject({
      photoUrls: [],
      content: '刚到手，先记录一下。',
      durationMinutes: null,
      method: null,
      recordedDate: todayBeijing(),
    });
    const detail = await request(app.getHttpServer())
      .get(`/v1/items/${itemId}`)
      .set(auth(tokenA));
    expect(detail.body.item.dayCount).toBe(1);
  });

  it('POST records：photoUrls 落库并按序返回（0~N 张）', async () => {
    const res = await request(app.getHttpServer())
      .post(`/v1/items/${itemId}/records`)
      .set(auth(tokenA))
      .send({
        photoUrls: ['/uploads/aaaa.jpg', '/uploads/bbbb.png'],
        content: '盘了半小时',
        durationMinutes: 30,
        method: '手套盘',
      });
    expect(res.status).toBe(201);
    expect(res.body.record.photoUrls).toEqual([
      '/uploads/aaaa.jpg',
      '/uploads/bbbb.png',
    ]);
    expect(res.body.record.durationMinutes).toBe(30);
    expect(res.body.record.method).toBe('手套盘');
  });

  it('POST records：过去日期即补录', async () => {
    const res = await request(app.getHttpServer())
      .post(`/v1/items/${itemId}/records`)
      .set(auth(tokenA))
      .send({ content: '补录昨天', recordedDate: beijingDaysAgo(1) });
    expect(res.status).toBe(201);
    expect(res.body.record.recordedDate).toBe(beijingDaysAgo(1));
  });

  it('POST records：未来日期/空内容/非法日期被拒', async () => {
    const future = await request(app.getHttpServer())
      .post(`/v1/items/${itemId}/records`)
      .set(auth(tokenA))
      .send({ content: 'x', recordedDate: beijingDaysAgo(-1) });
    expect(future.status).toBe(400);
    expect(future.body.message).toBe('记录日期不能晚于今天');

    const empty = await request(app.getHttpServer())
      .post(`/v1/items/${itemId}/records`)
      .set(auth(tokenA))
      .send({ content: '   ' });
    expect(empty.status).toBe(400);

    const invalid = await request(app.getHttpServer())
      .post(`/v1/items/${itemId}/records`)
      .set(auth(tokenA))
      .send({ content: 'x', recordedDate: '2025-02-30' });
    expect(invalid.status).toBe(400);
  });

  it('GET records：recordedDate 倒序、同日期 createdAt 倒序', async () => {
    const res = await request(app.getHttpServer())
      .get(`/v1/items/${itemId}/records`)
      .set(auth(tokenA));
    expect(res.status).toBe(200);
    expect(res.body.records).toHaveLength(3);
    expect(res.body.records.map((r: { content: string }) => r.content)).toEqual([
      '盘了半小时', // 今天，最晚创建
      '刚到手，先记录一下。', // 今天，次晚创建
      '补录昨天', // 昨天
    ]);
    expect(res.body.records[0].photoUrls).toEqual([
      '/uploads/aaaa.jpg',
      '/uploads/bbbb.png',
    ]);
  });

  it('dayCount：补录昨天后 = 2', async () => {
    const res = await request(app.getHttpServer())
      .get(`/v1/items/${itemId}`)
      .set(auth(tokenA));
    expect(res.body.item.dayCount).toBe(2);
  });

  it('PATCH /items/:id：部分更新与清空，空对象/非法值拒绝', async () => {
    const ok = await request(app.getHttpServer())
      .patch(`/v1/items/${itemId}`)
      .set(auth(tokenA))
      .send({ name: '改名后的核桃', notes: null, sizeSpec: null });
    expect(ok.status).toBe(200);
    expect(ok.body.item.name).toBe('改名后的核桃');
    expect(ok.body.item.notes).toBeNull();
    expect(ok.body.item.sizeSpec).toBeNull();

    const empty = await request(app.getHttpServer())
      .patch(`/v1/items/${itemId}`)
      .set(auth(tokenA))
      .send({});
    expect(empty.status).toBe(400);

    const nullName = await request(app.getHttpServer())
      .patch(`/v1/items/${itemId}`)
      .set(auth(tokenA))
      .send({ name: null });
    expect(nullName.status).toBe(400);
  });

  it('用户隔离：B 看不到也动不了 A 的数据', async () => {
    const loginB = await request(app.getHttpServer())
      .post('/v1/auth/dev-login')
      .send({ phone: '13900139000' });
    expect(loginB.body.isNewUser).toBe(true);
    tokenB = loginB.body.token;

    const listB = await request(app.getHttpServer())
      .get('/v1/items')
      .set(auth(tokenB));
    expect(listB.body.items).toEqual([]);

    const getA = await request(app.getHttpServer())
      .get(`/v1/items/${itemId}`)
      .set(auth(tokenB));
    expect(getA.status).toBe(404);

    const recordA = await request(app.getHttpServer())
      .post(`/v1/items/${itemId}/records`)
      .set(auth(tokenB))
      .send({ content: '越权' });
    expect(recordA.status).toBe(404);

    const listRecordsA = await request(app.getHttpServer())
      .get(`/v1/items/${itemId}/records`)
      .set(auth(tokenB));
    expect(listRecordsA.status).toBe(404);

    const patchA = await request(app.getHttpServer())
      .patch(`/v1/items/${itemId}`)
      .set(auth(tokenB))
      .send({ name: '越权改名' });
    expect(patchA.status).toBe(404);

    const deleteA = await request(app.getHttpServer())
      .delete(`/v1/items/${itemId}`)
      .set(auth(tokenB));
    expect(deleteA.status).toBe(404);
  });

  it('uploads：需登录；合法 png 返回相对 URL 且可静态访问', async () => {
    const noAuth = await request(app.getHttpServer())
      .post('/v1/uploads')
      .attach('file', PNG_1PX, { filename: 'a.png', contentType: 'image/png' });
    expect(noAuth.status).toBe(401);

    const ok = await request(app.getHttpServer())
      .post('/v1/uploads')
      .set(auth(tokenA))
      .attach('file', PNG_1PX, { filename: 'a.png', contentType: 'image/png' });
    expect(ok.status).toBe(201);
    expect(ok.body.url).toMatch(/^\/uploads\/[0-9a-f-]{36}\.png$/);

    const staticRes = await request(app.getHttpServer()).get(ok.body.url);
    expect(staticRes.status).toBe(200);
    expect(staticRes.headers['content-type']).toContain('image/png');
  });

  it('uploads：非法类型 415 / 超限 413', async () => {
    const badType = await request(app.getHttpServer())
      .post('/v1/uploads')
      .set(auth(tokenA))
      .attach('file', Buffer.from('hello'), {
        filename: 'a.txt',
        contentType: 'text/plain',
      });
    expect(badType.status).toBe(415);
    expect(badType.body.code).toBe('UNSUPPORTED_TYPE');

    const tooBig = await request(app.getHttpServer())
      .post('/v1/uploads')
      .set(auth(tokenA))
      .attach('file', Buffer.alloc(10 * 1024 * 1024 + 1), {
        filename: 'big.png',
        contentType: 'image/png',
      });
    expect(tooBig.status).toBe(413);
    expect(tooBig.body.code).toBe('UPLOAD_TOO_LARGE');
  });

  it('DELETE /items/:id：204 逻辑删除，records/images 物理保留，已删除对外 404', async () => {
    // ① 删除带记录玩物 → 204（v2.3 逻辑删除）
    const res = await request(app.getHttpServer())
      .delete(`/v1/items/${itemId}`)
      .set(auth(tokenA));
    expect(res.status).toBe(204);

    // ② 数据层：item 行仍在、deleted_at 已置位；records/images 物理保留
    const [{ count: itemCount, deleted: deletedAt }] = await ds.query(
      `SELECT count(*)::int AS count, bool_and(deleted_at IS NOT NULL) AS deleted
       FROM items WHERE id = $1`,
      [itemId],
    );
    expect(itemCount).toBe(1);
    expect(deletedAt).toBe(true);
    const [{ count: recCount }] = await ds.query(
      `SELECT count(*)::int AS count FROM item_records WHERE item_id = $1`,
      [itemId],
    );
    expect(recCount).toBe(3);
    const [{ count: imgCount }] = await ds.query(
      `SELECT count(*)::int AS count FROM record_images ri
       WHERE ri.record_id IN (SELECT id FROM item_records WHERE item_id = $1)`,
      [itemId],
    );
    expect(imgCount).toBe(2);

    // ③ 重复删除 → 404（v2.3：未命中=已删除）
    const again = await request(app.getHttpServer())
      .delete(`/v1/items/${itemId}`)
      .set(auth(tokenA));
    expect(again.status).toBe(404);
    expect(again.body.code).toBe('NOT_FOUND');

    // ④ 已删除玩物对所有正常接口视为不存在
    const detail = await request(app.getHttpServer())
      .get(`/v1/items/${itemId}`)
      .set(auth(tokenA));
    expect(detail.status).toBe(404);

    const records = await request(app.getHttpServer())
      .get(`/v1/items/${itemId}/records`)
      .set(auth(tokenA));
    expect(records.status).toBe(404);

    const patch = await request(app.getHttpServer())
      .patch(`/v1/items/${itemId}`)
      .set(auth(tokenA))
      .send({ name: '删除后改名' });
    expect(patch.status).toBe(404);

    const list = await request(app.getHttpServer())
      .get('/v1/items')
      .set(auth(tokenA));
    expect(list.status).toBe(200);
    expect(list.body.items).toEqual([]);
  });
});
