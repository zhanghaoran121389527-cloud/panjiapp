import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Req,
} from '@nestjs/common';
import { AuthedRequest } from '../../common/auth.guard';
import { CreateRecordDto } from './dto/create-record.dto';
import { RecordDto, RecordsService } from './records.service';

@Controller('items/:itemId/records')
export class RecordsController {
  constructor(private readonly recordsService: RecordsService) {}

  @Post()
  create(
    @Req() req: AuthedRequest,
    @Param('itemId', new ParseUUIDPipe({ version: '4' })) itemId: string,
    @Body() dto: CreateRecordDto,
  ): Promise<{ record: RecordDto }> {
    return this.recordsService
      .create(req.user.id, itemId, dto)
      .then((record) => ({ record }));
  }

  @Get()
  list(
    @Req() req: AuthedRequest,
    @Param('itemId', new ParseUUIDPipe({ version: '4' })) itemId: string,
  ): Promise<{ records: RecordDto[] }> {
    return this.recordsService.list(req.user.id, itemId);
  }
}
