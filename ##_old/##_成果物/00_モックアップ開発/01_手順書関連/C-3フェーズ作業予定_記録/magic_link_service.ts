import {
  Injectable,
  Logger,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { MailService } from './mail.service';
import * as crypto from 'crypto';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class MagicLinkService {
  private readonly logger = new Logger(MagicLinkService.name);
  private readonly TOKEN_EXPIRY_MINUTES = 15;
  private readonly TOKEN_LENGTH = 128;
  private readonly RATE_LIMIT_MINUTES = 5;
  private readonly MAX_REQUESTS_PER_LIMIT = 3;

  constructor(
    private prisma: PrismaService,
    private mailService: MailService,
    private jwtService: JwtService,
  ) {}

  /**
   * マジックリンク要求
   * - トークン生成
   * - レート制限チェック
   * - メール送信
   */
  async requestMagicLink(
    email: string,
    requestIp: string,
    userAgent: string,
    deviceId?: string,
    name?: string,
    language: string = 'JP',
  ): Promise<{ success: boolean; expiresIn: number }> {
    try {
      // レート制限チェック
      await this.checkRateLimit(email, requestIp);

      // ユーザー取得または新規作成
      let user = await this.prisma.user.findUnique({
        where: { email },
      });

      if (!user) {
        // 新規ユーザー作成
        user = await this.prisma.user.create({
          data: {
            email,
            name: name || email.split('@')[0],
            language,
          },
        });
        this.logger.log(`✅ 新規ユーザー作成: ${email}`);
      } else if (!user.isActive) {
        throw new BadRequestException(
          'このアカウントは無効化されています',
        );
      }

      // 既存の有効なトークンを無効化
      await this.prisma.magicLinkToken.updateMany({
        where: {
          userId: user.id,
          isUsed: false,
          expiresAt: { gt: new Date() },
        },
        data: { isUsed: true, usedAt: new Date() },
      });

      // 新しいトークン生成
      const token = this.generateToken();
      const expiresAt = new Date(
        Date.now() + this.TOKEN_EXPIRY_MINUTES * 60 * 1000,
      );

      // トークン保存
      await this.prisma.magicLinkToken.create({
        data: {
          userId: user.id,
          token,
          expiresAt,
          requestIp,
          userAgent,
          deviceId,
        },
      });

      // 監査ログ
      await this.logAudit(user.id, 'REQUEST_MAGIC_LINK', 'SUCCESS', {
        email,
        requestIp,
      });

      // メール送信
      await this.mailService.sendMagicLink(
        email,
        token,
        language,
        user.name,
      );

      this.logger.log(`✅ マジックリンク要求成功: ${email}`);

      return {
        success: true,
        expiresIn: this.TOKEN_EXPIRY_MINUTES * 60, // 秒単位
      };
    } catch (error) {
      this.logger.error(`❌ マジックリンク要求失敗: ${email}`, error);
      await this.logAudit(null, 'REQUEST_MAGIC_LINK', 'FAILED', {
        email,
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * トークン検証・ログイン
   */
  async verifyToken(
    token: string,
    deviceId?: string,
  ): Promise<{
    user: any;
    accessToken: string;
    expiresIn: number;
  }> {
    try {
      // トークン検証
      const magicToken = await this.prisma.magicLinkToken.findUnique({
        where: { token },
        include: { user: true },
      });

      if (!magicToken) {
        throw new UnauthorizedException('無効なトークンです');
      }

      if (magicToken.isUsed) {
        throw new UnauthorizedException(
          'このトークンは既に使用されています',
        );
      }

      if (magicToken.expiresAt < new Date()) {
        throw new UnauthorizedException('トークンの有効期限が切れています');
      }

      // トークンを使用済みにマーク
      await this.prisma.magicLinkToken.update({
        where: { id: magicToken.id },
        data: {
          isUsed: true,
          usedAt: new Date(),
        },
      });

      // ユーザーのログイン情報を更新
      const user = await this.prisma.user.update({
        where: { id: magicToken.userId },
        data: { lastLoginAt: new Date() },
        select: {
          id: true,
          email: true,
          name: true,
          language: true,
          isActive: true,
          createdAt: true,
        },
      });

      // JWTトークン生成
      const payload = {
        sub: user.id,
        email: user.email,
      };
      const accessToken = this.jwtService.sign(payload, {
        expiresIn: '24h',
      });

      // 監査ログ
      await this.logAudit(user.id, 'VERIFY_TOKEN', 'SUCCESS', {
        email: user.email,
      });

      this.logger.log(`✅ トークン検証成功: ${user.email}`);

      return {
        user,
        accessToken,
        expiresIn: 24 * 60 * 60, // 秒単位（24時間）
      };
    } catch (error) {
      this.logger.error(`❌ トークン検証失敗`, error);
      await this.logAudit(null, 'VERIFY_TOKEN', 'FAILED', {
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * ランダムトークン生成
   */
  private generateToken(): string {
    return crypto.randomBytes(this.TOKEN_LENGTH / 2).toString('hex');
  }

  /**
   * レート制限チェック
   */
  private async checkRateLimit(
    email: string,
    requestIp: string,
  ): Promise<void> {
    const withinMinutes = new Date(
      Date.now() - this.RATE_LIMIT_MINUTES * 60 * 1000,
    );

    const recentRequests = await this.prisma.magicLinkToken.count({
      where: {
        user: { email },
        createdAt: { gte: withinMinutes },
      },
    });

    if (recentRequests >= this.MAX_REQUESTS_PER_LIMIT) {
      this.logger.warn(
        `⚠️ レート制限: ${email} (IP: ${requestIp})`,
      );
      throw new BadRequestException(
        `${this.RATE_LIMIT_MINUTES}分以内にリクエストが多すぎます。後で試してください。`,
      );
    }
  }

  /**
   * 監査ログ記録
   */
  private async logAudit(
    userId: string | null,
    action: string,
    result: string,
    detail: any,
  ): Promise<void> {
    try {
      await this.prisma.auditLog.create({
        data: {
          userId,
          action,
          result,
          detail: JSON.stringify(detail),
        },
      });
    } catch (error) {
      this.logger.error('監査ログ記録失敗', error);
    }
  }
}