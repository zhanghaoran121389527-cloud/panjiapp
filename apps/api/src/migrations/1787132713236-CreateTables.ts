import { MigrationInterface, QueryRunner } from "typeorm";

export class CreateTables1787132713236 implements MigrationInterface {
    name = 'CreateTables1787132713236'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`CREATE TABLE "users" ("id" uuid NOT NULL, "nickname" text, "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "CHK_5f2f075b2b04eb0ad0f6f58adf" CHECK ("nickname" IS NULL OR char_length("nickname") BETWEEN 1 AND 20), CONSTRAINT "PK_a3ffb1c0c8416b9fc6f907b7433" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "auth_identities" ("id" uuid NOT NULL, "user_id" uuid NOT NULL, "provider" text NOT NULL, "identifier" text NOT NULL, "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "uq_auth_identities_provider_identifier" UNIQUE ("provider", "identifier"), CONSTRAINT "PK_63a29aebcddd09448dbeee4666b" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "categories" ("id" uuid NOT NULL, "name" text NOT NULL, "sort_order" integer NOT NULL, CONSTRAINT "UQ_8b0be371d28245da6e4f4b61878" UNIQUE ("name"), CONSTRAINT "PK_24dbc6126a28ff948da33e97d3b" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "items" ("id" uuid NOT NULL, "user_id" uuid NOT NULL, "category_id" uuid NOT NULL, "name" text NOT NULL, "cover_image_url" text, "subcategory" text, "size_spec" text, "acquired_date" date, "notes" text, "deleted_at" TIMESTAMP WITH TIME ZONE, "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "CHK_41ea9d71690efe4d3e6851bc12" CHECK (char_length("name") BETWEEN 1 AND 50), CONSTRAINT "PK_ba5885359424c15ca6b9e79bcf6" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE INDEX "idx_items_user_id" ON "items" ("user_id") `);
        await queryRunner.query(`CREATE TABLE "item_records" ("id" uuid NOT NULL, "item_id" uuid NOT NULL, "content" text NOT NULL, "duration_minutes" integer, "method" text, "recorded_date" date NOT NULL, "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "CHK_824b64ef8d494ec9a44558e6cc" CHECK ("method" IS NULL OR char_length("method") BETWEEN 1 AND 20), CONSTRAINT "CHK_66a405210d408fcfc574ef77b8" CHECK ("duration_minutes" IS NULL OR "duration_minutes" BETWEEN 1 AND 1440), CONSTRAINT "CHK_7149e2952eb2961d84a3376b09" CHECK (char_length("content") BETWEEN 1 AND 500), CONSTRAINT "PK_31687d003dae289e279b4b7433f" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE INDEX "idx_item_records_item_id" ON "item_records" ("item_id") `);
        await queryRunner.query(`CREATE TABLE "record_images" ("id" uuid NOT NULL, "record_id" uuid NOT NULL, "image_url" text NOT NULL, "sort_order" integer NOT NULL, "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "uq_record_images_record_sort" UNIQUE ("record_id", "sort_order"), CONSTRAINT "CHK_97e41af786f795ba6bd83dd0fc" CHECK ("sort_order" >= 0), CONSTRAINT "PK_8da97547c56544ed29d9e60c728" PRIMARY KEY ("id"))`);
        await queryRunner.query(`ALTER TABLE "auth_identities" ADD CONSTRAINT "FK_c06a980d83c42611d27a294e55c" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "items" ADD CONSTRAINT "FK_3b934e62fb52bac909e0ddf5422" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "items" ADD CONSTRAINT "FK_0c4aa809ddf5b0c6ca45d8a8e80" FOREIGN KEY ("category_id") REFERENCES "categories"("id") ON DELETE RESTRICT ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "item_records" ADD CONSTRAINT "FK_cff4e76e0e1bb5d110a6c8244bc" FOREIGN KEY ("item_id") REFERENCES "items"("id") ON DELETE RESTRICT ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "record_images" ADD CONSTRAINT "FK_c992d73dd3fed857df16386e636" FOREIGN KEY ("record_id") REFERENCES "item_records"("id") ON DELETE CASCADE ON UPDATE NO ACTION`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "record_images" DROP CONSTRAINT "FK_c992d73dd3fed857df16386e636"`);
        await queryRunner.query(`ALTER TABLE "item_records" DROP CONSTRAINT "FK_cff4e76e0e1bb5d110a6c8244bc"`);
        await queryRunner.query(`ALTER TABLE "items" DROP CONSTRAINT "FK_0c4aa809ddf5b0c6ca45d8a8e80"`);
        await queryRunner.query(`ALTER TABLE "items" DROP CONSTRAINT "FK_3b934e62fb52bac909e0ddf5422"`);
        await queryRunner.query(`ALTER TABLE "auth_identities" DROP CONSTRAINT "FK_c06a980d83c42611d27a294e55c"`);
        await queryRunner.query(`DROP TABLE "record_images"`);
        await queryRunner.query(`DROP INDEX "public"."idx_item_records_item_id"`);
        await queryRunner.query(`DROP TABLE "item_records"`);
        await queryRunner.query(`DROP INDEX "public"."idx_items_user_id"`);
        await queryRunner.query(`DROP TABLE "items"`);
        await queryRunner.query(`DROP TABLE "categories"`);
        await queryRunner.query(`DROP TABLE "auth_identities"`);
        await queryRunner.query(`DROP TABLE "users"`);
    }

}
