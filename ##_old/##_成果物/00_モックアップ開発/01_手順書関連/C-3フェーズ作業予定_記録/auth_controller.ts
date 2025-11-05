import {
  Controller,
  Post,
  Body,
  Get,
  Headers,
  UseGuards,
  Request,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { MagicLinkService } from './services/magic-link.service';
import { RequestMagicLinkDto, VerifyTokenDto } from './dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

@Controller('auth')
export class AuthController {
  private readonly logger = new Logger(AuthController.name);

  constructor(private readonly magicLinkService: MagicLinkService) {}

  /**
   * マジックリンク要求エンドポイント
   * POST /auth/request-magic-link
   */
  @Post('request-magic-link')
  async requestMagicLink(
    @Body() dto: RequestMagicLinkDto,
    @Headers('user-agent') userAgent: string,
    @Headers('x-forwarded-for') ip: string,
  ) {
    if (!dto.email) {
      throw new BadRequestException('メールアドレスが必須です');
    }

    const requestIp = ip?.split(',')[0] || 'unknown';

    const result = await this.magicLinkService.requestMagicLink(
      dto.email,
      requestIp,
      userAgent,
      undefined, // deviceId
      dto.name,
      dto.language || 'JP',
    );

    return {
      statusCode: 200,
      message: 'マジックリンクをメールで送信しました',
      data: {
        email: dto.email,
        expiresIn: result.expiresIn,
        sent: result.success,
      },
    };
  }

  /**
   * トークン検証・ログインエンドポイント
   * POST /auth/verify-token
   */
  @Post('verify-token')
  async verifyToken(@Body() dto: VerifyTokenDto) {
    if (!dto.token) {
      throw new BadRequestException('トークンが必須です');
    }

    const result = await this.magicLinkService.verifyToken(
      dto.token,
      dto.deviceId,
    );

    return {
      statusCode: 200,
      message: 'ログイン成功',
      data: {
        user: result.user,
        accessToken: result.accessToken,
        expiresIn: result.expiresIn,
      },
    };
  }

  /**
   * プロフィール取得エンドポイント（認証必須）
   * GET /auth/profile
   */
  @Get('profile')
  @UseGuards(JwtAuthGuard)
  async getProfile(@Request() req) {
    return {
      statusCode: 200,
      message: 'プロフィール取得成功',
      data: req.user,
    };
  }

  /**
   * ヘルスチェック
   * GET /auth/health
   */
  @Get('health')
  async health() {
    return {
      statusCode: 200,
      message: '認証サービスは正常に動作しています',
      timestamp: new Date().toISOString(),
    };
  }
}