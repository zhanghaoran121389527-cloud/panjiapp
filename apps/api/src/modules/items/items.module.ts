import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Category } from '../../entities/category.entity';
import { ItemRecord } from '../../entities/item-record.entity';
import { Item } from '../../entities/item.entity';
import { ItemsController } from './items.controller';
import { ItemsService } from './items.service';

@Module({
  imports: [TypeOrmModule.forFeature([Item, ItemRecord, Category])],
  controllers: [ItemsController],
  providers: [ItemsService],
  exports: [ItemsService],
})
export class ItemsModule {}
