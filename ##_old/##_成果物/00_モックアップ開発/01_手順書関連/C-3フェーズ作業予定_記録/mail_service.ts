import { Injectable, Logger } from '@nestjs/common';
import * as nodemailer from 'nodemailer';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private transporter: nodemailer.Transporter;

  constructor() {
    // SMTP設定（環境変数から取得）
    this.transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST || 'smtp.mailtrap.io',
      port: parseInt(process.env.SMTP_PORT || '2525'),
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
    });
  }

  /**
   * マジックリンクメール送信（多言語対応）
   */
  async sendMagicLink(
    email: string,
    token: string,
    language: string = 'JP',
    name?: string,
  ): Promise<boolean> {
    try {
      const magicLink = `${process.env.APP_URL}/auth/verify?token=${token}`;
      const { subject, htmlContent } = this.getEmailTemplate(
        language,
        name || 'User',
        magicLink,
      );

      await this.transporter.sendMail({
        from: process.env.MAIL_FROM || 'noreply@securecity.app',
        to: email,
        subject,
        html: htmlContent,
        text: `Click here to login: ${magicLink}`,
      });

      this.logger.log(`✅ マジックリンクメール送信成功: ${email}`);
      return true;
    } catch (error) {
      this.logger.error(`❌ メール送信失敗: ${email}`, error);
      throw error;
    }
  }

  /**
   * 多言語メールテンプレート
   */
  private getEmailTemplate(
    language: string,
    userName: string,
    magicLink: string,
  ): { subject: string; htmlContent: string } {
    const templates = {
      JP: {
        subject: 'セキュレアシティ - ログインリンク',
        htmlContent: `
          <div style="font-family: Arial, sans-serif; max-width: 600px;">
            <h2>ログインのご案内</h2>
            <p>${userName}様</p>
            <p>セキュレアシティアプリへのログインリンクをお送りします。</p>
            <p>以下のボタンをクリックしてログインしてください。</p>
            <div style="margin: 20px 0;">
              <a href="${magicLink}" style="
                background-color: #667eea;
                color: white;
                padding: 12px 30px;
                text-decoration: none;
                border-radius: 5px;
                display: inline-block;
              ">ログインする</a>
            </div>
            <p style="color: #999; font-size: 12px;">
              ※このリンクは15分間有効です。<br>
              ※このメールに心当たりがない場合は、このメールを無視してください。
            </p>
          </div>
        `,
      },
      EN: {
        subject: 'Secure City - Login Link',
        htmlContent: `
          <div style="font-family: Arial, sans-serif; max-width: 600px;">
            <h2>Login Link</h2>
            <p>Dear ${userName},</p>
            <p>We send you a login link for Secure City app.</p>
            <p>Please click the button below to login.</p>
            <div style="margin: 20px 0;">
              <a href="${magicLink}" style="
                background-color: #667eea;
                color: white;
                padding: 12px 30px;
                text-decoration: none;
                border-radius: 5px;
                display: inline-block;
              ">Login</a>
            </div>
            <p style="color: #999; font-size: 12px;">
              ※This link is valid for 15 minutes.<br>
              ※If you did not request this email, please ignore it.
            </p>
          </div>
        `,
      },
      CN: {
        subject: '安全城市 - 登录链接',
        htmlContent: `
          <div style="font-family: Arial, sans-serif; max-width: 600px;">
            <h2>登录链接</h2>
            <p>尊敬的${userName}，</p>
            <p>我们为您发送安全城市应用的登录链接。</p>
            <p>请点击下面的按钮登录。</p>
            <div style="margin: 20px 0;">
              <a href="${magicLink}" style="
                background-color: #667eea;
                color: white;
                padding: 12px 30px;
                text-decoration: none;
                border-radius: 5px;
                display: inline-block;
              ">登录</a>
            </div>
            <p style="color: #999; font-size: 12px;">
              ※此链接有效期为15分钟。<br>
              ※如果您没有请求此电子邮件，请忽略它。
            </p>
          </div>
        `,
      },
    };

    return templates[language] || templates['EN'];
  }

  /**
   * テストメール送信（デバッグ用）
   */
  async sendTestEmail(email: string): Promise<boolean> {
    try {
      await this.transporter.sendMail({
        from: process.env.MAIL_FROM,
        to: email,
        subject: 'Test Email',
        text: 'This is a test email from Secure City API',
      });
      this.logger.log(`✅ テストメール送信成功: ${email}`);
      return true;
    } catch (error) {
      this.logger.error(`❌ テストメール送信失敗: ${email}`, error);
      throw error;
    }
  }
}