import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ItemRecord } from '../../entities/item-record.entity';
import { RecordImage } from '../../entities/record-image.entity';
import { ItemsModule } from '../items/items.module';
import { RecordsController } from './records.controller';
import { RecordsService } from './records.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([ItemRecord, RecordImage]),
    ItemsModule,
  ],
  controllers: [RecordsController],
  providers: [RecordsService],
})
export class RecordsModule {}
