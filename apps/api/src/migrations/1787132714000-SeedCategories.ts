import { MigrationInterface, QueryRunner } from 'typeorm';

const CATEGORIES: Array<[string, string, number]> = [
  ['a1b2c3d4-0001-4000-8000-000000000001', '核桃', 1],
  ['a1b2c3d4-0002-4000-8000-000000000002', '菩提', 2],
  ['a1b2c3d4-0003-4000-8000-000000000003', '木质', 3],
  ['a1b2c3d4-0004-4000-8000-000000000004', '玉石', 4],
  ['a1b2c3d4-0005-4000-8000-000000000005', '其他', 5],
];

/** DATABASE_SCHEMA §3.1 / §8.2：固定 UUID，ON CONFLICT (id) DO NOTHING 幂等。 */
export class SeedCategories1787132714000 implements MigrationInterface {
  name = 'SeedCategories1787132714000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `INSERT INTO "categories" ("id", "name", "sort_order") VALUES ${CATEGORIES.map(
        (c) => `('${c[0]}', '${c[1]}', ${c[2]})`,
      ).join(', ')} ON CONFLICT ("id") DO NOTHING`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DELETE FROM "categories" WHERE "id" IN (${CATEGORIES.map(
        (c) => `'${c[0]}'`,
      ).join(', ')})`,
    );
  }
}
