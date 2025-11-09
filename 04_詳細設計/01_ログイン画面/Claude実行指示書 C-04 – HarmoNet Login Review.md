Claude実行指示書（C-04）
対象：HarmoNet ログイン画面 詳細設計 v1.3系
実行AI：Claude（構造・整合性レビュー担当）

🎯 タスク概要

目的:
　HarmoNet Phase9仕様に基づくログイン画面設計一式（Magic Link + Passkey対応）の構造整合性・認証フロー整合性・UI一貫性をレビューする。

対象ファイル（4章構成）
1.login-feature-design-ch00-index_v1.3.md
2.login-feature-design-ch01_v1.1.md
3.login-feature-design-ch02_v1.1.md
4.login-feature-design-ch03_v1.3.md

🧩 レビュー範囲と評価項目
| 区分        | 内容                             | 評価基準                                               |
| --------- | ------------------------------ | -------------------------------------------------- |
| 構成整合性     | 各章の論理的接続・参照リンクの整合性             | 各章間の相互依存が破綻していないこと                                 |
| 認証フロー     | Magic Link＋Passkey統合の技術的妥当性    | Supabase Auth構成（GoTrue, WebAuthn, JWT連携）が実装可能であること |
| セッション/RLS | JWT `tenant_id` を利用したRLS制御の一貫性 | DBポリシー仕様との齟齬がないこと                                  |
| UI一貫性     | 共通部品(C-01〜C-05)との結合            | 言語切替・翻訳Providerの適用ミスがないこと                          |
| セキュリティ    | コールバック検証・トークン失効動作              | Supabase Authのトークン更新機構と矛盾がないこと                     |
| ドキュメント品質  | 明確性・再現性                        | 構成が読み手にとって実装可能な粒度であること                             |

🔍 出力要求

Claudeは以下形式で出力すること：
1.構成整合性スコア（1〜10）
2.セキュリティ／データフロースコア（1〜10）
3..UI整合性スコア（1〜10）
4.章別指摘リスト
・軽微／中程度／重大 の3区分
・対象章と該当箇所を明示
5.総評コメント（300〜600字）

⚙️ 制約条件
・ドキュメントの内容修正は行わない。レビューのみ。
・出力はMarkdown整形。
・トークン消費を考慮し、各章の再掲は禁止。
・判定の根拠を明確に記述すること。

🧾 参考文書
| 参照対象                                             | 概要                                             |
| ------------------------------------------------ | ---------------------------------------------- |
| `harmonet-technical-stack-definition_v3.7.md`    | 技術スタック仕様（Supabase Auth, Next.js 15, WebAuthn）  |
| `HarmoNet_Phase9_DB_Construction_Report_v1_0.md` | DB構成とRLSポリシー定義                                 |
| `機能コンポーネント一覧.md`                                 | A-01〜A-05共通部品一覧（Magic Link, Passkey, Callback） |

🧠 補足指針
・Claudeは、Phase9技術基盤の完全適合性を重視して評価する。
・特に login-feature-design-ch03_v1.3.md の Supabase セッション確立処理と、harmonet-technical-stack-definition_v3.7.md 内 GoTrue 設定値との整合を重視する。
・テナント識別の自動化（JWT tenant_id claim）について、セキュリティ上の妥当性も必ず指摘対象に含める。

