import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Category } from '../../entities/category.entity';

@Injectable()
export class CategoriesService {
  constructor(
    @InjectRepository(Category)
    private readonly categories: Repository<Category>,
  ) {}

  /** 契约 3.4：固定 5 品类，按 sort_order 升序，仅回 id + name。 */
  async list(): Promise<{ categories: { id: string; name: string }[] }> {
    const rows = await this.categories.find({
      order: { sortOrder: 'ASC' },
    });
    return { categories: rows.map((c) => ({ id: c.id, name: c.name })) };
  }
}
