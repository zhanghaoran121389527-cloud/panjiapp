import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, In, Repository } from 'typeorm';
import { ApiError } from '../../common/api-error';
import { isValidDateString, todayBeijing } from '../../common/dates';
import { ItemRecord } from '../../entities/item-record.entity';
import { RecordImage } from '../../entities/record-image.entity';
import { ItemsService } from '../items/items.service';
import { CreateRecordDto } from './dto/create-record.dto';

export interface RecordDto {
  id: string;
  photoUrls: string[];
  content: string;
  durationMinutes: number | null;
  method: string | null;
  recordedDate: string;
  createdAt: Date;
}

@Injectable()
export class RecordsService {
  constructor(
    @InjectRepository(ItemRecord)
    private readonly records: Repository<ItemRecord>,
    @InjectRepository(RecordImage)
    private readonly images: Repository<RecordImage>,
    private readonly dataSource: DataSource,
    private readonly itemsService: ItemsService,
  ) {}

  /** 契约 3.11：当日记录与历史补录同一接口；photoUrls 落 record_images。 */
  async create(
    userId: string,
    itemId: string,
    dto: CreateRecordDto,
  ): Promise<RecordDto> {
    await this.itemsService.findOwned(userId, itemId);

    const recordedDate = dto.recordedDate ?? todayBeijing();
    if (!isValidDateString(recordedDate)) {
      throw new ApiError(400, 'VALIDATION_ERROR', '记录日期不是有效日期');
    }
    if (recordedDate > todayBeijing()) {
      throw new ApiError(400, 'VALIDATION_ERROR', '记录日期不能晚于今天');
    }

    const photoUrls = dto.photoUrls ?? [];
    const record = await this.dataSource.transaction(async (em) => {
      const created = em.create(ItemRecord, {
        itemId,
        content: dto.content,
        durationMinutes: dto.durationMinutes ?? null,
        method: dto.method ?? null,
        recordedDate,
      });
      await em.save(created);
      if (photoUrls.length > 0) {
        const images = photoUrls.map((url, index) =>
          em.create(RecordImage, {
            recordId: created.id,
            imageUrl: url,
            sortOrder: index,
          }),
        );
        await em.save(images);
      }
      return created;
    });

    return this.toDto(record, photoUrls);
  }

  /** 契约 3.12：时间轴；recordedDate 倒序、同日期 createdAt 倒序。 */
  async list(
    userId: string,
    itemId: string,
  ): Promise<{ records: RecordDto[] }> {
    await this.itemsService.findOwned(userId, itemId);

    const rows = await this.records.find({
      where: { itemId },
      order: { recordedDate: 'DESC', createdAt: 'DESC' },
    });
    if (rows.length === 0) return { records: [] };

    const images = await this.images.find({
      where: { recordId: In(rows.map((r) => r.id)) },
      order: { sortOrder: 'ASC' },
    });
    const byRecord = new Map<string, string[]>();
    for (const image of images) {
      const list = byRecord.get(image.recordId) ?? [];
      list.push(image.imageUrl);
      byRecord.set(image.recordId, list);
    }

    return {
      records: rows.map((r) => this.toDto(r, byRecord.get(r.id) ?? [])),
    };
  }

  private toDto(record: ItemRecord, photoUrls: string[]): RecordDto {
    return {
      id: record.id,
      photoUrls,
      content: record.content,
      durationMinutes: record.durationMinutes,
      method: record.method,
      recordedDate: record.recordedDate,
      createdAt: record.createdAt,
    };
  }
}
