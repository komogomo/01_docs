# HarmoNet 実装運用ガイド _latest  
**Phase 9.8 構成対応版（Prisma + Supabase + Docker 統一運用）**

---

## 第1章　目的と適用範囲
本書は HarmoNet Phase9.8 における開発実行環境および運用ルールを定義する。  
Prisma ORM・Supabase CLI・Docker 環境の実行ディレクトリ、構築手順、操作基準を明確にし、開発者間の環境差異を排除する。

---

## 第2章　実行ディレクトリルール

| 項目 | 内容 |
|------|------|
| ルートディレクトリ | `D:\Projects\HarmoNet` |
| 実行環境 | Windows 11 + Docker Desktop + Node.js 22 LTS |
| 原則 | **すべての CLI コマンドはルートで実行する** |
| 禁止事項 | `src/` 配下で Prisma/Supabase コマンドを実行しない |
| 理由 | `.env` / `.env.local` がルートにあるため、パス解決と認証に依存 |

---

## 第3章　環境構築手順（Phase9.8）

### Step 1: Supabase 起動

```powershell
cd D:\Projects\HarmoNet
npx supabase start

・8モジュール構成（DB / Auth / Realtime / Storage / Mailpit 等）を一括起動
・実行後、http://localhost:54323 で Supabase Studio にアクセス可能

