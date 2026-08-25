import { Module } from '@nestjs/common';
import { APP_FILTER, APP_GUARD } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthGuard } from './common/auth.guard';
import { HttpExceptionFilter } from './common/http-exception.filter';
import { config } from './config';
import { buildDataSourceOptions } from './data-source';
import { HealthModule } from './health/health.module';
import { AuthModule } from './modules/auth/auth.module';
import { CategoriesModule } from './modules/categories/categories.module';
import { ItemsModule } from './modules/items/items.module';
import { RecordsModule } from './modules/records/records.module';
import { UploadsModule } from './modules/uploads/uploads.module';
import { UsersModule } from './modules/users/users.module';

@Module({
  imports: [
    JwtModule.register({
      global: true,
      secret: config.jwtSecret,
      signOptions: { expiresIn: '365d' },
    }),
    TypeOrmModule.forRoot({ ...buildDataSourceOptions(), autoLoadEntities: true }),
    HealthModule,
    AuthModule,
    UsersModule,
    CategoriesModule,
    ItemsModule,
    RecordsModule,
    UploadsModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: AuthGuard },
    { provide: APP_FILTER, useClass: HttpExceptionFilter },
  ],
})
export class AppModule {}
