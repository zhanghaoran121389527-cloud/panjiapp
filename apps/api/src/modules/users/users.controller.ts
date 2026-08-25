import { Body, Controller, Get, Patch, Req } from '@nestjs/common';
import { AuthedRequest } from '../../common/auth.guard';
import { UpdateNicknameDto } from './dto/update-nickname.dto';
import { UsersService, UserDto } from './users.service';

@Controller('me')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  getMe(@Req() req: AuthedRequest): Promise<{ user: UserDto }> {
    return this.usersService.getById(req.user.id).then((user) => ({ user }));
  }

  @Patch()
  updateMe(
    @Req() req: AuthedRequest,
    @Body() dto: UpdateNicknameDto,
  ): Promise<{ user: UserDto }> {
    return this.usersService
      .updateNickname(req.user.id, dto)
      .then((user) => ({ user }));
  }
}
