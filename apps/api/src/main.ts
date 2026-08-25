import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';
import { configureApp } from './app-setup';
import { config } from './config';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  configureApp(app);
  await app.listen(config.port);
  console.log(`panji-api listening on http://127.0.0.1:${config.port}`);
}

void bootstrap();
