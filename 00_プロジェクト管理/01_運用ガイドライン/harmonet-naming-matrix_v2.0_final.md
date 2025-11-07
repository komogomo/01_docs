# HarmoNet Naming Matrix v2.0 (Final)
**Category:** /01_docs/03_rules  
**Created:** 2025-11-06  
**Author:** Tachikoma（PMO / Architect）  
**Reviewed by:** Claude（整形）・Gemini（監査）  
**Approved by:** TKD  
**Status:** Phase9 Final / Ready for Placement  

---

## 第1章〜第4章
（内容は v2.0_consolidated に準拠。構文・整形・DBマッピングは変更なし）

---

## 第5章　AI命名照会構文とVOICEBOXキー体系

### 5.1　AI命名照会構文（Windsurf / Claude連携）

HarmoNetのAI実装フローでは、Windsurf が自律命名を行わず、  
未定義の名称を検出した際には以下のコメント構文を出力する。

```tsx
// TODO: require name(<context>)

<context> は対象機能と用途を英語で簡潔に記述する。
例:
// TODO: require name(Board delete confirmation modal)
・Claude が候補 DeletePostConfirmModal を提案し、Tachikoma 承認後に命名マトリクスへ登録。
・Claude は提案時に harmonet-naming-matrix_v2.0.md を参照し、既存命名との衝突を検知する。
・Gemini は AI照会ログを監査し、命名プロセスの一貫性を保証する。

責務分担
| AIエージェント  | 役割   | 出力例                                                      |
| --------- | ---- | -------------------------------------------------------- |
| Windsurf  | 実装AI | `// TODO: require name(Board delete confirmation modal)` |
| Claude    | 設計補完 | `提案: DeletePostConfirmModal`                             |
| Tachikoma | PMO  | `承認: DeletePostConfirmModal`                             |
| Gemini    | 監査   | 命名照会ログの妥当性検証                                             |

5.2　VOICEBOXキー体系（TTS / 多言語音声出力）
Phase9では、UIテキスト（i18nキー）と並列して
音声再生用キー（voice-*）を設計し、
Supabaseの tts_cache テーブルでキャッシュする。

基本仕様
・テーブル: tts_cache
・主キー: (lang, key)
・言語コードは BCP-47 に準拠（例: ja, en, zh-Hans, yue）
・音声エンジンの例：
　・ja → VOICEBOX (Zundamon系)
　・en → English Native TTS
　・zh-Hans → Mandarin（普通話）
　・yue → Cantonese（広東語）
・キャッシュ衝突なし。キー体系は全言語で共通。

共通音声キー（Global Voice Tokens）
| 機能 | キー                  | 用途         |
| -- | ------------------- | ---------- |
| 全体 | `voice-tts-play`    | 読み上げ開始     |
| 全体 | `voice-tts-stop`    | 読み上げ停止     |
| 全体 | `voice-tts-loading` | 音声データ読込中表示 |

機能別音声キー
| 機能    | キー                                             | 用途              |
| ----- | ---------------------------------------------- | --------------- |
| 掲示板   | `voice-read-post`, `voice-read-comment`        | 投稿・コメント読み上げ     |
| お知らせ  | `voice-read-announcement`                      | お知らせ本文読み上げ      |
| 施設予約  | `voice-read-facility`, `voice-read-parking`    | 集会所・駐車場情報読み上げ   |
| アンケート | `voice-read-question`, `voice-submit-complete` | 質問文・送信完了通知      |
| マイページ | `voice-read-profile`, `voice-change-lang`      | プロフィール・言語変更通知   |
| 管理者   | `voice-read-auditlog`, `voice-read-userlist`   | 監査ログ・ユーザー一覧読み上げ |

実装上の備考
・各音声キーは i18nキーと同じプレフィックス階層に配置。
・翻訳キャッシュ (translation_cache) とTTSキャッシュ (tts_cache) は別管理。
・Gemini監査時には tts_cache.lang + key の重複を検証対象とする。

5.3　運用指針（AI照会＋TTS統合）
1.Windsurfは新命名・新音声キーを生成せず、照会コメントを出力。
2.Claudeが候補名／キー名を提案。
3.Tachikomaが命名承認し、命名マトリクスへ登録。
4.Geminiが監査で整合・衝突検証。
5.Supabaseは translation_cache と tts_cache の両キャッシュを同期管理。

第6章　ChangeLog / メタ情報
| Version           | Date       | Description                        | Author    |
| ----------------- | ---------- | ---------------------------------- | --------- |
| v2.0_consolidated | 2025-11-06 | Claude＋Gemini統合反映                  | Tachikoma |
| v2.0_final        | 2025-11-06 | Gemini指摘対応：AI命名照会構文・VOICEBOXキー体系追記 | Tachikoma |

Document ID: HNM-NAMING-MATRIX-20251106-FINAL
Supersedes: harmonet-naming-matrix_v2.0_consolidated.md
Placement: /01_docs/03_rules/
Next Step: TKD承認 → 正式配置