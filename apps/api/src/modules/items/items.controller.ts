import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Req,
} from '@nestjs/common';
import { AuthedRequest } from '../../common/auth.guard';
import { CreateItemDto } from './dto/create-item.dto';
import { UpdateItemDto } from './dto/update-item.dto';
import { ItemFullDto, ItemListItemDto, ItemsService } from './items.service';

@Controller('items')
export class ItemsController {
  constructor(private readonly itemsService: ItemsService) {}

  @Get()
  list(@Req() req: AuthedRequest): Promise<{ items: ItemListItemDto[] }> {
    return this.itemsService.list(req.user.id);
  }

  @Post()
  create(
    @Req() req: AuthedRequest,
    @Body() dto: CreateItemDto,
  ): Promise<{ item: ItemFullDto }> {
    return this.itemsService
      .create(req.user.id, dto)
      .then((item) => ({ item }));
  }

  @Get(':id')
  getById(
    @Req() req: AuthedRequest,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
  ): Promise<{ item: ItemFullDto }> {
    return this.itemsService
      .getById(req.user.id, id)
      .then((item) => ({ item }));
  }

  @Patch(':id')
  update(
    @Req() req: AuthedRequest,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
    @Body() dto: UpdateItemDto,
  ): Promise<{ item: ItemFullDto }> {
    return this.itemsService
      .update(req.user.id, id, dto)
      .then((item) => ({ item }));
  }

  @Delete(':id')
  @HttpCode(204)
  async remove(
    @Req() req: AuthedRequest,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
  ): Promise<void> {
    await this.itemsService.remove(req.user.id, id);
  }
}
