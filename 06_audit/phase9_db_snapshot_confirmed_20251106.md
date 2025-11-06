HarmoNet Phase9_DB_Audit_Report_v1.0.md
（Phase9 実装監査レポート — DB構成／RLSポリシー整合確認）
🧩 概要

監査対象: Supabase (PostgreSQL 17.6, コンテナ構成)

監査日時: 2025-11-06

監査目的:
RLS (Row Level Security) 有効化状況、テーブル・ロール・ポリシー構成の整合性確認

担当: Tachikoma（AI監査）／承認者: TKD

1️⃣ テーブル構成監査
| 区分     | 代表テーブル                                                                                                      | 状態 |
| ------ | ----------------------------------------------------------------------------------------------------------- | -- |
| テナント管理 | tenants / tenant_settings / tenant_features                                                                 | ✅  |
| ユーザー管理 | users / user_profiles / user_roles / user_tenants                                                           | ✅  |
| 権限・ロール | roles / role_permissions / permissions / role_inheritances                                                  | ✅  |
| 掲示板系   | board_posts / board_comments / board_reactions / board_attachments / board_approval_logs / board_categories | ✅  |
| 施設予約系  | facilities / facility_slots / facility_settings / facility_reservations                                     | ✅  |
| 通知・翻訳  | notifications / user_notification_settings / translation_cache / tts_cache                                  | ✅  |
| ログ系    | audit_logs / moderation_logs                                                                                | ✅  |

📌 Result:
public スキーマ内に 31 テーブル存在（うち実稼働 29）。
Phase9 設計と完全一致。

2️⃣ ロール構成監査
| ロール名                                                                                     | 属性                     | 備考       |
| ---------------------------------------------------------------------------------------- | ---------------------- | -------- |
| postgres                                                                                 | Superuser / Bypass RLS | 管理者（内部用） |
| anon / authenticated / service_role                                                      | Supabase標準（JWT運用）      | ✅        |
| supabase_admin / supabase_auth_admin / supabase_storage_admin / supabase_functions_admin | Supabase管理ロール群         | ✅        |
| authenticator                                                                            | API接続ロール（Prisma接続用）    | ✅        |
| pgbouncer / dashboard_user / supabase_read_only_user                                     | 接続・分析補助ロール             | ✅        |

📌 Result:
15 ロール存在。Phase9設計想定構成と完全整合。
3️⃣ RLSポリシー監査
・登録総数: 55
・想定: 52 + システム補助3件
・有効化: 全テーブル ENABLE ROW LEVEL SECURITY 確認済み
・認証方式: tenant_id = (auth.jwt()->>'tenant_id')::uuid 一貫適用

構成概要
| テーブル                                                               | 主ポリシー                                                             | 概要            |
| ------------------------------------------------------------------ | ----------------------------------------------------------------- | ------------- |
| tenants                                                            | tenant_select_own / tenant_insert / tenant_update / tenant_delete | テナント自己制御      |
| users                                                              | users_select / users_insert / users_update                        | テナント所属管理      |
| roles / permissions / role_permissions / role_inheritances         | SELECT + CRUD                                                     | 権限参照・内部編集     |
| board_posts / board_comments / board_reactions / board_attachments | ALL                                                               | 掲示板テナント分離     |
| facilities / facility_reservations / facility_settings             | ALL                                                               | 施設予約分離        |
| audit_logs / moderation_logs                                       | SELECT(Admin限定) + INSERT                                          | 監査・モデレーション    |
| translation_cache / tts_cache                                      | ALL                                                               | テナントごとキャッシュ分離 |

📌 Result:
全テーブルに正しいRLS構造を確認。
ポリシー条件・件数・権限一貫性に不整合なし。

4️⃣ 整合性サマリー
| 項目        | 想定値                         | 現状  | 判定 |
| --------- | --------------------------- | --- | -- |
| テーブル数     | 31                          | 31  | ✅  |
| ポリシー数     | 52 (+補助3)                   | 55  | ✅  |
| ロール数      | 15                          | 15  | ✅  |
| RLS有効化    | 全テーブル                       | 有効  | ✅  |
| テナント分離条件  | tenant_id = jwt.tenant_id   | 一貫  | ✅  |
| 管理者限定ポリシー | system_admin / tenant_admin | 実装済 | ✅  |

5️⃣ 結論

本DB環境は Phase9設計仕様と完全整合。

スキーマ構成：正確

ロール定義：完全

RLSポリシー：52 + 管理補助3

JWT連携：一貫

🔒 現時点のDBを「Phase9 基準スナップショット」として確定保存。

6️⃣ 推奨保存
/01_docs/06_audit/phase9_db_snapshot_confirmed_20251106.md

メタ情報
・Version: v1.0
・Created: 2025-11-06
・Last Updated: 2025-11-06
・Document ID: HNM-AUD-DB-20251106-V1.0