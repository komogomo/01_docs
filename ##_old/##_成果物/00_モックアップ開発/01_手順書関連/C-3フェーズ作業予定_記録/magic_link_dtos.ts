// ========================================
// File: src/auth/dto/request-magic-link.dto.ts
// ========================================

import { IsEmail, IsNotEmpty, IsString, MaxLength, MinLength } from 'class-validator';

export class RequestMagicLinkDto {
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(2)
  @MaxLength(50)
  name?: string; // 初回登録時のみ必須

  @IsString()
  @IsNotEmpty()
  language?: string = 'JP'; // JP, EN, CN
}

// ========================================
// File: src/auth/dto/verify-token.dto.ts
// ========================================

import { IsNotEmpty, IsString, Length } from 'class-validator';

export class VerifyTokenDto {
  @IsString()
  @IsNotEmpty()
  @Length(128, 128) // トークンの長さを固定
  token: string;

  @IsString()
  deviceId?: string; // デバイス識別子（オプション）
}

// ========================================
// File: src/auth/dto/auth-response.dto.ts
// ========================================

export class MagicLinkResponseDto {
  statusCode: number;
  message: string;
  data?: {
    email: string;
    expiresIn: number; // 秒単位（900秒 = 15分）
    sent: boolean;
  };
}

export class VerifyTokenResponseDto {
  statusCode: number;
  message: string;
  data?: {
    id: string;
    email: string;
    name: string;
    language: string;
    accessToken: string;
    expiresIn: number;
  };
}

export class UserProfileDto {
  id: string;
  email: string;
  name: string;
  language: string;
  isActive: boolean;
  createdAt: Date;
  lastLoginAt: Date;
}

// ========================================
// File: src/auth/dto/index.ts
// ========================================

export * from './request-magic-link.dto';
export * from './verify-token.dto';
export * from './auth-response.dto';