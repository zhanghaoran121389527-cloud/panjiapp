import { Controller, Get } from '@nestjs/common';
import { Public } from '../../common/public.decorator';
import { CategoriesService } from './categories.service';

@Controller('categories')
export class CategoriesController {
  constructor(private readonly categoriesService: CategoriesService) {}

  @Public()
  @Get()
  list(): Promise<{ categories: { id: string; name: string }[] }> {
    return this.categoriesService.list();
  }
}
