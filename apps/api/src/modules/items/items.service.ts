import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';
import { ApiError } from '../../common/api-error';
import { dayCount, isValidDateString, todayBeijing } from '../../common/dates';
import { Category } from '../../entities/category.entity';
import { ItemRecord } from '../../entities/item-record.entity';
import { Item } from '../../entities/item.entity';
import { CreateItemDto } from './dto/create-item.dto';
import { UpdateItemDto } from './dto/update-item.dto';

export interface ItemFullDto {
  id: string;
  name: string;
  coverImageUrl: string | null;
  categoryId: string;
  subcategory: string | null;
  sizeSpec: string | null;
  acquiredDate: string | null;
  notes: string | null;
  dayCount: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface ItemListItemDto {
  id: string;
  name: string;
  coverImageUrl: string | null;
  categoryId: string;
  dayCount: number;
  createdAt: Date;
}

@Injectable()
export class ItemsService {
  constructor(
    @InjectRepository(Item)
    private readonly items: Repository<Item>,
    @InjectRepository(ItemRecord)
    private readonly records: Repository<ItemRecord>,
    @InjectRepository(Category)
    private readonly categories: Repository<Category>,
  ) {}

  /** 契约 3.6：创建玩物；categoryId 必须存在；dayCount 恒为 0。 */
  async create(userId: string, dto: CreateItemDto): Promise<ItemFullDto> {
    await this.ensureCategoryExists(dto.categoryId);
    if (dto.acquiredDate && !isValidDateString(dto.acquiredDate)) {
      throw new ApiError(400, 'VALIDATION_ERROR', '入手日期不是有效日期');
    }
    const item = await this.items.save(
      this.items.create({
        userId,
        categoryId: dto.categoryId,
        name: dto.name,
        coverImageUrl: dto.coverImageUrl ?? null,
        subcategory: dto.subcategory ?? null,
        sizeSpec: dto.sizeSpec ?? null,
        acquiredDate: dto.acquiredDate ?? null,
        notes: dto.notes ?? null,
      }),
    );
    return this.toFullDto(item, 0);
  }

  /** 契约 3.5：仅当前用户；createdAt 倒序；已删除玩物不出现（v2.3）。 */
  async list(userId: string): Promise<{ items: ItemListItemDto[] }> {
    const rows = await this.items.find({
      where: { userId, deletedAt: IsNull() },
      order: { createdAt: 'DESC' },
    });
    const firstDates = await this.minRecordedDates(rows.map((r) => r.id));
    const today = todayBeijing();
    const items = rows.map((item) => ({
      id: item.id,
      name: item.name,
      coverImageUrl: item.coverImageUrl,
      categoryId: item.categoryId,
      dayCount: dayCount(firstDates.get(item.id) ?? null, today),
      createdAt: item.createdAt,
    }));
    return { items };
  }

  /** 契约 3.7：详情（不含 records）；归属校验，越权 404。 */
  async getById(userId: string, id: string): Promise<ItemFullDto> {
    const item = await this.findOwned(userId, id);
    const firstDates = await this.minRecordedDates([id]);
    return this.toFullDto(
      item,
      dayCount(firstDates.get(id) ?? null, todayBeijing()),
    );
  }

  /** 契约 3.8：部分更新；可传 null 清空选填字段。 */
  async update(
    userId: string,
    id: string,
    dto: UpdateItemDto,
  ): Promise<ItemFullDto> {
    const item = await this.findOwned(userId, id);
    // 注意：DTO 实例上未提供的字段是 undefined 自有属性，'in' 判断不可靠
    const provided = Object.keys(dto).filter(
      (k) => (dto as Record<string, unknown>)[k] !== undefined,
    );
    if (provided.length === 0) {
      throw new ApiError(400, 'VALIDATION_ERROR', '至少提供一个要更新的字段');
    }
    if (dto.categoryId !== undefined) {
      await this.ensureCategoryExists(dto.categoryId);
    }
    if (dto.acquiredDate && !isValidDateString(dto.acquiredDate)) {
      throw new ApiError(400, 'VALIDATION_ERROR', '入手日期不是有效日期');
    }

    if (dto.name !== undefined) item.name = dto.name;
    if (dto.categoryId !== undefined) item.categoryId = dto.categoryId;
    if (dto.coverImageUrl !== undefined) item.coverImageUrl = dto.coverImageUrl ?? null;
    if (dto.subcategory !== undefined) item.subcategory = dto.subcategory ?? null;
    if (dto.sizeSpec !== undefined) item.sizeSpec = dto.sizeSpec ?? null;
    if (dto.acquiredDate !== undefined) item.acquiredDate = dto.acquiredDate ?? null;
    if (dto.notes !== undefined) item.notes = dto.notes ?? null;

    await this.items.save(item);
    const firstDates = await this.minRecordedDates([id]);
    return this.toFullDto(
      item,
      dayCount(firstDates.get(id) ?? null, todayBeijing()),
    );
  }

  /**
   * 契约 3.9（v2.3）：逻辑删除。
   * 命中 → 204（controller 层）；未命中（不存在/他人/已删除）→ 404。
   * item_records / record_images 物理保留；M1 无恢复接口。
   */
  async remove(userId: string, id: string): Promise<void> {
    const result = await this.items
      .createQueryBuilder()
      .update()
      .set({ deletedAt: () => 'now()' })
      .where('id = :id AND user_id = :userId AND deleted_at IS NULL', {
        id,
        userId,
      })
      .execute();
    if (!result.affected) {
      throw new ApiError(404, 'NOT_FOUND', '玩物不存在');
    }
  }

  /**
   * 归属校验：不存在、不属于当前用户、或已逻辑删除一律 404，不泄露存在性。
   * getById / update / records 入口（RecordsService.findOwned 调用）均经此过滤。
   */
  async findOwned(userId: string, id: string): Promise<Item> {
    const item = await this.items.findOne({
      where: { id, userId, deletedAt: IsNull() },
    });
    if (!item) throw new ApiError(404, 'NOT_FOUND', '玩物不存在');
    return item;
  }

  private async ensureCategoryExists(categoryId: string): Promise<void> {
    const category = await this.categories.findOneBy({ id: categoryId });
    if (!category) {
      throw new ApiError(400, 'VALIDATION_ERROR', '品类不存在');
    }
  }

  /** 每个 item 的最早记录日期；无记录 → null。 */
  private async minRecordedDates(
    ids: string[],
  ): Promise<Map<string, string | null>> {
    const result = new Map<string, string | null>();
    if (ids.length === 0) return result;
    const rows = await this.records
      .createQueryBuilder('r')
      .select('r.itemId', 'itemId')
      .addSelect('MIN(r.recordedDate)', 'firstDate')
      .where('r.itemId IN (:...ids)', { ids })
      .groupBy('r.itemId')
      .getRawMany<{ itemId: string; firstDate: string | null }>();
    for (const row of rows) result.set(row.itemId, row.firstDate);
    return result;
  }

  private toFullDto(item: Item, count: number): ItemFullDto {
    return {
      id: item.id,
      name: item.name,
      coverImageUrl: item.coverImageUrl,
      categoryId: item.categoryId,
      subcategory: item.subcategory,
      sizeSpec: item.sizeSpec,
      acquiredDate: item.acquiredDate,
      notes: item.notes,
      dayCount: count,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    };
  }
}
