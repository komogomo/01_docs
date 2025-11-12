使用指示書: /01_docs/05_製造/01_Windsurf-作業指示書/WS-A01_MagicLinkForm_v1.0.md

目的:
HarmoNet A-01 MagicLinkForm を Next.js 16 / React 19 / Supabase v2.43 / Corbado SDK v2.x 構成で
仕様通りに完全再生成・自己採点・品質レポート出力すること。

環境:
- 既存コードを再利用しない（src/components/auth/MagicLinkForm/ 以下を新規生成）
- 旧実装・中間生成物・タチコマコードは参照禁止
- 技術スタック: harmoNet-technical-stack-definition_v4.2
- i18n: StaticI18nProvider (C-03) を利用
- テスト: Jest + RTL
- ストーリー: idle / sending / sent の3状態

出力:
- src/components/auth/MagicLinkForm/MagicLinkForm.tsx
- src/components/auth/MagicLinkForm/MagicLinkForm.test.tsx
- src/components/auth/MagicLinkForm/MagicLinkForm.stories.tsx
- public/locales/{ja,en,zh}/common.json（必要キー追加）
- /01_docs/05_品質チェック/CodeAgent_Report_MagicLinkForm_v1.0.md

完了条件:
- TypeScript / ESLint / Prettier エラー 0
- Jest全項目 (T-A01-01〜T-A01-05) 成功
- Self-Score ≥ 9.0 / 10.0
- Storybookの3状態がレンダリング可能であること

特記事項:
- Supabase連携: signInWithOtp() および signInWithIdToken({ provider: 'corbado', token: id_token })
- Passkeyフロー: Corbado.passkey.login() 成功時 → Supabase連携 → /mypage 遷移
- OTPフロー: Supabase signInWithOtp() 成功時 → /auth/callback 遷移
- i18nキー追加: auth.passkey.login / success / progress / retry
