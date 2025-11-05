# HarmoNet Technical Stack Definition v3.3
HarmoNet プロジェクト 技術スタック定義書（Phase8 運用構成対応版）

---

## 🧭 Purpose（目的）

本書は Phase7 における監査完了設計を基に、Phase8 で実運用可能な技術スタックを確定する。  
MVP スタートアップ段階における実装と運用の再現性・安定性を保証し、  
Supabase を中核とする統合開発環境を正式に採用する。

目的は以下の通り：

1. 開発・運用環境を統一し、再現性を保証する。  
2. Supabase を中核としたバックエンド構成を正式採用する。  
3. Docker Desktop（Hyper-V構成）上で全環境を完結させる。  
4. VS Code + Copilot による人間・AI共通の実装支援体制を構築する。  
5. CI/CD 等の自動化を排除し、MVPフェーズに最適化した手動運用を明示する。

---

## ⚙️ System Overview（環境構成）

### 🧩 基本構成方針
- すべての開発・実行環境は **Docker Desktop (Hyper-V構成)** 上で稼働する。  
- **WSL2およびUbuntuを含むすべてのWSLディストリビューションは使用禁止。**  
- 開発環境は本番構成の縮小コピーとし、検証環境は設けない。  
- **Supabase を常設**し、DB・Auth・Storageを統合管理する。  

---

### 🧱 開発基盤構成

| コンポーネント | バージョン | 用途 / 備考 |
|----------------|-------------|--------------|
| **Docker Desktop** | v4.35.0 (Engine v27.1.2) | Hyper-V構成、WSL2統合OFF |
| **Compose** | v2.27+ (`docker compose` コマンド) | 旧 `docker-compose` 非対応 |
| **Node.js** | 20.17.1 LTS（固定） | Next.js / Supabase CLI安定動作版 |
| **npm** | 10.8.2 | LTS同梱安定版 |
| **pnpm** | 9.6.0 | パッケージキャッシュ最適化、推奨PM |
| **Next.js** | 15.0.3 | App Router完全移行構成（`pages/`不使用） |
| **React / ReactDOM** | 19.0.0 | Next.js 15対応版 |
| **Prisma** | 6.0.1 | Supabase Adapter利用、スキーマ直結 |
| **PostgreSQL (Supabase内)** | 15.6 | RLS / pg_graphql安定組み合わせ |
| **Supabase OSS Stack** | 2025-09安定タグ | Cloud互換構成（詳細下表） |
| **GitHub Copilot** | 1.228.0 | コード補完、Chat統合型 |
| **GitHub Copilot Chat** | 0.21.0 | 実装補助（コメント→コード生成） |
| **VS Code** | 1.96.1 | 2025-10安定版、手動更新モード |
| **Python** | 3.12+ | AI連携スクリプト用（任意） |

---

### 🧬 Supabase Stack 内訳

| サービス | イメージ | バージョン | 用途 |
|-----------|-----------|-------------|------|
| Postgres | supabase/postgres | 15.6.1 | DB本体 |
| GoTrue | supabase/gotrue | 2.139.0 | Auth |
| PostgREST | supabase/postgrest | 11.2.1 | REST API |
| Realtime | supabase/realtime | 2.31.1 | WebSocket通知 |
| Storage API | supabase/storage-api | 1.43.0 | ファイル保存 |
| Studio | supabase/studio | 0.23.4 | 管理UI |
| Kong | kong | 3.8 | API Gateway |

> Supabase 公式 Compose (2025年9月安定リリース) を使用。  
> 本番移行時は `.env.production` の接続URLおよびAPIキー切替のみで対応。

---

## 🧠 開発支援環境（VS Code + 拡張機能）

### 🧩 VS Code 環境
- **更新モード:** 手動 (`"update.mode": "manual"`)  
- **拡張自動更新:** 無効 (`"extensions.autoUpdate": false"`)  
- **バージョン固定:** 1.96.1

### 🧩 推奨拡張機能一覧（安定構成）
| 分類 | 拡張機能名 | 発行元 | バージョン | 備考 |
|------|-------------|---------|-------------|------|
| コード支援 | GitHub Copilot | GitHub | 1.228.0 | コード補完／AI支援 |
| コード支援 | GitHub Copilot Chat | GitHub | 0.21.0 | コード生成補助 |
| ORM補助 | Prisma | Prisma Data | 5.15.0 | Prisma 6対応版 |
| Lint | ESLint | Microsoft | 2.4.4 | Next.js / Supabase対応 |
| Formatter | Prettier - Code Formatter | Prettier | 10.7.0 | コード整形 |
| DevOps | Docker | Microsoft | 1.30.0 | Compose v2対応 |
| DevOps | Dev Containers | Microsoft | 0.334.0 | Compose統合安定版 |
| DB GUI | SQLTools | Matheus Teixeira | 0.27.2 | Supabase内DB確認用 |
| UI補助 | Tailwind CSS IntelliSense | Tailwind Labs | 0.11.30 | クラス補完 |
| 多言語 | i18n Ally | Lokalise | 3.10.1 | 多言語対応 |
| 可視化 | Error Lens | Alexander | 3.13.0 | エラー行表示 |

### 🧩 拡張機能インストール方法
```bash
code --install-extension GitHub.copilot@1.228.0
code --install-extension GitHub.copilot-chat@0.21.0
code --install-extension Prisma.prisma@5.15.0
code --install-extension ms-azuretools.vscode-docker@1.30.0
code --install-extension ms-vscode-remote.remote-containers@0.334.0
code --install-extension dbaeumer.vscode-eslint@2.4.4
code --install-extension esbenp.prettier-vscode@10.7.0
```

- `.vsix` ファイルも `/03_env/vscode-extensions/` に保存して配布可能。  
- 一括導入用 PowerShell スクリプト例：
  ```powershell
  cd D:\AIDriven\##_成果物\01_プロダクト開発\03_HarmoNetCore\03_env\vscode-extensions
  Get-ChildItem *.vsix | ForEach-Object { code --install-extension $_.FullName --force }
  ```

---

## 🔧 Deployment Policy（運用方針）

| 区分 | 方針 | 補足 |
|------|------|------|
| デプロイ方式 | 手動デプロイ | Vercel ダッシュボードから main ブランチを選択し手動実行。 |
| CI/CD | 使用しない | GitHub Actions / 自動パイプラインは導入しない。 |
| バックアップ | Gitタグ＋zip | バージョンタグ付与後、Dockerイメージをエクスポート。 |
| 本番切替 | `.env.production` 切替 | Supabase Cloud の接続キー差し替え。 |
| ドキュメント管理 | GitHub + Google Drive | 三AI共通参照ディレクトリ `/01_docs/` を使用。 |

---

## 🚫 環境制約事項

> **開発・運用環境に関する禁止事項**

1. **WSL2を含むすべてのLinuxディストリビューションは使用禁止。**  
   - Ubuntu, AlmaLinux, RockyLinux, いずれも対象。  
   - Docker Desktop（Hyper-V構成）のみを正式サポート。  
2. **旧Compose (`docker-compose`) コマンド禁止。**  
   - Compose V2 (`docker compose`) のみ使用可能。  
3. **Node.js / Next.js のメジャーバージョン変更禁止。**  
   - 指定バージョン固定で運用する。  
4. **VS Code / 拡張機能の自動更新禁止。**

---

## 🧾 Version & ChangeLog

| Version | Date | Author | Summary |
|----------|------|---------|----------|
| 3.2 | 2025-10-30 | タチコマ | Phase7実装監査完了版 |
| **3.3** | **2025-11-03** | **タチコマ** | **Phase8運用構成定義版。Supabase常設・WSL禁止・Copilot統合・CI/CD削除。** |

---

**Document ID:** HNM-TECH-STACK-DEF-20251103  
**Version:** 3.3  
**Created:** 2025-11-03  
**Last Updated:** 2025-11-03  
**Author:** タチコマ（HarmoNet AI Architect）
