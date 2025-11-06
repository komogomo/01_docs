# HarmoNet Naming Matrix v2.0  
**Category:** /01_docs/03_rules  
**Created:** 2025-11-06  
**Author:** タチコマ（PMO / Architect）  
**Reviewers:** Claude（整形）・Gemini（監査）  
**Approved by:** TKD  

---

## 第1章　命名体系の基本原則（Naming System Fundamentals）

### 1.1　目的  
HarmoNetプロジェクト全体で、AIエージェント（Windsurf, Claude, Gemini）および人間開発者が  
同一の命名体系で動作・解析・生成を行えるよう統一ルールを定義する。  

この命名マトリクスは、`harmonet-coding-standard_v1.1.md` 第2章を上位規約とし、  
命名の衝突防止・再利用性・型安全性の確保を目的とする。  

---

### 1.2　命名体系の分類

| レイヤ | 形式 | 主な対象 | 命名例 |
|--------|------|----------|--------|
| **UI層（Component）** | PascalCase | Reactコンポーネント | `BoardList`, `LoginForm` |
| **ロジック層（Hook / Service）** | camelCase | Hook関数 / ビジネスロジック | `useBoardFetch`, `handleSubmit` |
| **型／インターフェース層（Type / DTO）** | PascalCase | 型・スキーマ・DTO | `UserSchema`, `FacilityBookingDTO` |
| **定数／Enum層** | ALL_CAPS | 環境定数・固定値 | `API_BASE_URL`, `DEFAULT_LANG` |
| **DB層（Prisma Schema）** | PascalCase / snake_case | モデル名・フィールド名 | `User`, `tenant_id` |
| **翻訳キー／トークン層** | kebab-case | i18n / Design Tokens | `text-primary`, `bg-surface`, `aria-label-login` |

---

### 1.3　命名構成の優先順位
1. **設計書準拠:** 設計書内の命名を最優先。AIは自動生成を行わない。  
2. **マトリクス参照:** 未定義の場合、Windsurfは `// TODO: require name` コメントを出力。  
3. **Claude補完:** Claudeが命名候補を提示、タチコマ承認後に採用。  
4. **Gemini監査:** 命名重複・多義性・誤翻訳を検出し報告。  

---

### 1.4　命名の評価基準
- 一貫性（Consistency）：UI⇔DB⇔APIで表記揺れがないこと。  
- 明確性（Clarity）：誰が見ても機能・役割を推測できる。  
- 可搬性（Portability）：多言語化・多テナント構成でも意味が通じる。  
- AI整合性（AI Alignment）：AIが構造解析しやすい接頭辞・形式を採用。  

---

### 1.5　予約接頭辞一覧

| 接頭辞 | 用途 | 例 |
|--------|------|----|
| `use` | React Hook / カスタムHook | `useBoardFetch` |
| `get` / `set` | データ取得・設定関数 | `getTenantInfo`, `setUserLocale` |
| `handle` | イベントハンドラ | `handleLogin`, `handleSubmit` |
| `is` / `has` / `can` | 状態・真偽値表現 | `isActive`, `hasPermission`, `canEdit` |
| `fetch` | API通信関数 | `fetchBoardList` |
| `render` | 描画補助関数 | `renderSurveyCard` |
| `mutate` | Supabase更新処理 | `mutatePostStatus` |

---

### 1.6　命名禁止・制限事項
- 意味を持たない略語（`tmp`, `obj`, `data1` など）の禁止。  
- 同一スコープ内で類似語尾の重複 (`user`, `userData`, `userInfo`) 禁止。  
- コンポーネント名と関数名の重複禁止。  
- 日本語・絵文字・全角文字の使用禁止。  
- AIによる自動命名生成の禁止（必ず参照照会経由）。  

---

## 第2章　レイヤ別命名ルール（Layer-specific Naming Rules）

### 2.1　UI層（Component）

| 区分 | 命名形式 | 命名例 | 補足 |
|------|-----------|--------|------|
| ページ | PascalCase | `BoardPage`, `FacilityPage` | `/app/` 直下 |
| 部品（共通） | PascalCase | `Header`, `Footer`, `LanguageSwitcher` | `/components/common/` |
| 機能別部品 | PascalCase | `PostCard`, `SurveyForm` | `/components/[feature]/` |
| レイアウト | PascalCase | `LayoutContainer`, `SectionWrapper` | ページ枠・グリッド構造用 |
| 状態表示 | PascalCase | `EmptyState`, `LoadingSpinner` | 汎用ステート表示 |

---

### 2.2　ロジック層（Hook / Service）

| 区分 | 命名形式 | 命名例 | 補足 |
|------|-----------|--------|------|
| Hook（取得） | `use` + 名詞 | `useBoardList`, `useTenantInfo` | データフェッチ用 |
| Hook（操作） | `use` + 動詞 | `useUpdateProfile`, `useSubmitForm` | 副作用を伴う操作 |
| APIサービス | 動詞＋名詞 | `fetchBoardList`, `createReservation` | Supabase SDK 経由 |
| 汎用関数 | camelCase | `formatDate`, `parseLocale` | `/lib/utils/` 配下 |

---

### 2.3　型／DTO層（Type / Interface / Entity）

| 区分 | 命名形式 | 命名例 | 補足 |
|------|-----------|--------|------|
| 型 | PascalCase | `UserSchema`, `FacilityBooking` | Prismaと整合させる |
| DTO | PascalCase＋`DTO` | `PostDTO`, `SurveyDTO` | APIレスポンス用 |
| Enum | PascalCase＋単語 | `PostStatus`, `UserRole` | 値は全大文字 |
| Prisma Model | PascalCase | `User`, `Tenant`, `Post` | DBモデル名 |
| Prisma Field | snake_case | `created_at`, `tenant_id` | DB物理名 |

---

### 2.4　デザイン／トークン層（Design Tokens / i18n）

| 区分 | 命名形式 | 命名例 | 備考 |
|------|-----------|--------|------|
| カラートークン | kebab-case | `text-primary`, `bg-surface` | `/styles/tokens.css` |
| フォント | kebab-case | `font-body`, `font-heading` | 同上 |
| 言語キー | kebab-case | `label-login`, `msg-error-required` | i18n用 |
| 音声キー | kebab-case | `voice-welcome`, `voice-read-post` | VOICEBOX用 |

---

（次章：第3章 機能別命名マトリクス 以降に続く）

## 第3章　機能別命名マトリクス（Feature-specific Naming Matrix）

### 3.1　掲示板（Board）

| カテゴリ | 種別 | 命名 | 用途 |
|-----------|------|------|------|
| コンポーネント | Page | `BoardPage` | 掲示板トップ画面（投稿一覧） |
| コンポーネント | Component | `PostCard`, `BoardFilter`, `BoardSearchBar` | 投稿一覧、絞込UI |
| コンポーネント | Detail | `PostDetail`, `PdfPreviewModal` | 投稿詳細・添付PDFプレビュー |
| Hook | Fetch | `useBoardList`, `usePostDetail` | Supabase取得 |
| Hook | Action | `useCreatePost`, `useDeletePost`, `useTogglePin` | 投稿操作 |
| 型／DTO | Type | `BoardPost`, `BoardTag`, `BoardComment` | Prisma連動 |
| API | Service | `fetchBoardList`, `createPost`, `deletePost` | Supabase RPC呼出 |
| Enum | 定義 | `PostStatus`, `TagType` | ステータス、分類タグ |
| トークン | i18n | `label-post`, `msg-delete-confirm`, `tag-important` | 多言語ラベル |
| 音声 | VOICEBOX | `voice-read-post`, `voice-reply-complete` | 読み上げタグ |

---

### 3.2-A 会議室・集会所（Facility）

| カテゴリ    | 種別        | 命名                                                             | 用途             |
| ------- | --------- | -------------------------------------------------------------- | -------------- |
| コンポーネント | Page      | `FacilityPage`                                                 | 集会所・会議室予約トップ   |
| コンポーネント | Component | `FacilityCard`, `RoomCalendar`, `FacilityForm`                 | 予約・空き状況UI      |
| Hook    | Fetch     | `useFacilityList`, `useFacilityDetail`                         | 施設情報取得         |
| Hook    | Action    | `useCreateFacilityReservation`, `useCancelFacilityReservation` | 時間単位予約         |
| 型／DTO   | Type      | `Facility`, `FacilityReservation`, `FacilitySlot`              | Prisma Model対応 |
| API     | Service   | `fetchFacilityReservations`, `createFacilityReservation`       | Supabase RPC   |
| Enum    | 定義        | `FacilityType`, `FacilityStatus`                               | 種別・状態          |
| トークン    | i18n      | `label-facility`, `msg-facility-booked`                        | 表示ラベル          |
| 音声      | VOICEBOX  | `voice-book-room`, `voice-cancel-room`                         | 音声対応           |

### 3.2-B 駐車場（Parking）
| カテゴリ    | 種別        | 命名                                                            | 用途             |
| ------- | --------- | ------------------------------------------------------------- | -------------- |
| コンポーネント | Page      | `ParkingPage`                                                 | 駐車場予約トップ       |
| コンポーネント | Component | `ParkingCard`, `ParkingForm`, `ParkingMap`                    | 駐車場予約UI        |
| Hook    | Fetch     | `useParkingList`, `useParkingDetail`                          | 駐車場情報取得        |
| Hook    | Action    | `useCreateParkingReservation`, `useCancelParkingReservation`  | 日単位予約操作        |
| 型／DTO   | Type      | `Parking`, `ParkingReservation`, `ParkingSlot`                | Prisma Model対応 |
| API     | Service   | `fetchParkingReservations`, `createParkingReservation`        | Supabase RPC   |
| Enum    | 定義        | `ParkingType`, `ParkingStatus`                                | 状態・区分          |
| トークン    | i18n      | `label-parking`, `msg-parking-reserved`, `msg-parking-cancel` | ラベル            |
| 音声      | VOICEBOX  | `voice-read-parking`, `voice-book-parking`                    | 読み上げ           |

---

### 3.3　アンケート（Survey）

| カテゴリ | 種別 | 命名 | 用途 |
|-----------|------|------|------|
| コンポーネント | Page | `SurveyPage` | アンケート一覧画面 |
| コンポーネント | Component | `SurveyList`, `SurveyCard`, `SurveyForm` | 各種UI部品 |
| Hook | Fetch | `useSurveyList`, `useSurveyDetail` | データ取得 |
| Hook | Action | `useSubmitSurvey`, `useCloseSurvey` | 回答送信・終了操作 |
| 型／DTO | Type | `Survey`, `SurveyOption`, `SurveyResult` | Prisma Model対応 |
| API | Service | `fetchSurveyList`, `submitSurvey` | Supabase操作 |
| Enum | 定義 | `SurveyStatus` | 実施中・終了など |
| トークン | i18n | `label-survey`, `msg-submit-success`, `msg-expired` | 翻訳キー |
| 音声 | VOICEBOX | `voice-read-question`, `voice-submit-complete` | 音声再生用 |

---

### 3.4　マイページ（MyPage）

| カテゴリ | 種別 | 命名 | 用途 |
|-----------|------|------|------|
| コンポーネント | Page | `MyPage` | ユーザー個別情報ページ |
| コンポーネント | Component | `ProfileCard`, `TenantInfo`, `LanguageSetting` | 個人情報表示／言語設定 |
| Hook | Fetch | `useUserInfo`, `useTenantInfo` | ユーザー／テナント情報取得 |
| Hook | Action | `useUpdateProfile`, `useChangeLanguage` | ユーザー操作 |
| 型／DTO | Type | `UserProfile`, `TenantInfo`, `LanguageSetting` | 型定義 |
| API | Service | `fetchUserInfo`, `updateProfile`, `changeLanguage` | Supabase呼出 |
| Enum | 定義 | `UserRole`, `Locale` | 権限・言語 |
| トークン | i18n | `label-profile`, `msg-update-complete`, `label-language` | 多言語対応 |
| 音声 | VOICEBOX | `voice-read-profile`, `voice-change-lang` | 音声出力タグ |

---

### 3.5　共通要素（Common）

| カテゴリ | 種別 | 命名 | 用途 |
|-----------|------|------|------|
| コンポーネント | 共通UI | `Header`, `Footer`, `LanguageSwitcher`, `PrimaryButton`, `LayoutContainer` | 全画面共通 |
| Hook | 共通処理 | `useAuth`, `useSession`, `useScrollLock`, `useResponsive` | 汎用ロジック |
| 型 | 共通型 | `Tenant`, `Session`, `ApiResponse` | 共通スキーマ |
| 定数 | 環境定義 | `API_BASE_URL`, `SUPPORTED_LANGS` | Supabase / 多言語設定 |
| トークン | i18n共通 | `msg-error-network`, `label-logout`, `msg-session-expired` | エラーメッセージ共通 |
| 音声 | VOICEBOX共通 | `voice-welcome`, `voice-logout` | 標準読み上げ音声 |

---

（次章：第4章 Supabase・Prismaテーブル対応命名 以降に続く）

## 第4章　Supabase・Prismaテーブル対応命名  
（Database ⇔ API ⇔ UI Mapping）

### 4.1　目的  
Supabase（PostgreSQL）上のテーブルおよび Prisma ORM のモデル名、  
それに対応する API モジュール・UIコンポーネントの命名を統一し、  
データフロー上の整合性を保証する。  

---

### 4.2　命名対応マトリクス

| 機能                    | DBテーブル（Supabase） | Prismaモデル      | APIモジュール                                                                      | 型定義／DTO                               | UIコンポーネント                                      |
| --------------------- | ---------------- | -------------- | ----------------------------------------------------------------------------- | ------------------------------------- | ---------------------------------------------- |
| 掲示板                   | `posts`          | `Post`         | `fetchBoardList`, `createPost`, `deletePost`                                  | `BoardPost`, `PostDTO`                | `PostCard`, `PostDetail`                       |
| 掲示板コメント               | `comments`       | `Comment`      | `fetchComments`, `createComment`                                              | `BoardComment`                        | `CommentList`, `CommentForm`                   |
| 掲示板タグ                 | `tags`           | `Tag`          | `fetchTags`                                                                   | `BoardTag`                            | `BoardFilter`                                  |
| **集会所／会議室（Facility）** | `facilities`     | `Facility`     | `fetchFacilityList`, `createFacilityReservation`, `cancelFacilityReservation` | `FacilityReservation`, `FacilitySlot` | `FacilityCard`, `RoomCalendar`, `FacilityForm` |
| **駐車場（Parking）**      | `parkings`       | `Parking`      | `fetchParkingList`, `createParkingReservation`, `cancelParkingReservation`    | `ParkingReservation`, `ParkingSlot`   | `ParkingCard`, `ParkingForm`, `ParkingMap`     |
| アンケート                 | `surveys`        | `Survey`       | `fetchSurveyList`, `submitSurvey`                                             | `SurveyDTO`                           | `SurveyCard`, `SurveyForm`                     |
| アンケート回答               | `survey_answers` | `SurveyAnswer` | `fetchAnswers`                                                                | `SurveyResult`                        | `SurveyResultList`                             |
| ユーザー                  | `users`          | `User`         | `fetchUserInfo`, `updateProfile`                                              | `UserProfile`                         | `ProfileCard`                                  |
| テナント                  | `tenants`        | `Tenant`       | `fetchTenantInfo`                                                             | `TenantInfo`                          | `TenantInfo`                                   |
| ロール                   | `roles`          | `Role`         | `fetchRoles`                                                                  | `UserRole`                            | —                                              |


---

### 4.3　命名規則（DB⇔Prisma）

| 対象 | 命名形式 | 例 | 備考 |
|------|-----------|----|------|
| テーブル | snake_case（複数形） | `posts`, `reservations` | Supabase命名慣例 |
| モデル | PascalCase（単数形） | `Post`, `Reservation` | Prisma標準 |
| フィールド | snake_case | `tenant_id`, `created_at` | 全DB共通 |
| 関連名 | lowerCamelCase | `user`, `comments`, `reservations` | Prismaリレーション |
| Enum | PascalCase | `PostStatus`, `UserRole` | 型・状態定義 |
| マイグレーション | 時刻接頭辞＋snake_case | `20251104090633_create_initial_schema.sql` | SQL命名規約に準拠 |

---

### 4.4　データフロー命名例（掲示板）

DB: posts → Prisma: Post → API: fetchBoardList → DTO: BoardPost → UI: PostCard

- 各層で「Post」プレフィックスを維持し、整合性を確保する。  
- Windsurf / Claude は命名衝突時に Post* を最優先で継承する。  
- Gemini は Prisma スキーマと TypeScript 型の一致を監査対象とする。  

---

## 第5章　AI命名照会ルール  
（AI Naming Inquiry Protocol）

### 5.1　目的  
AIエージェントが命名マトリクスを参照・照会する際の手順を標準化し、  
未定義命名の自動生成を防止する。  

---

### 5.2　命名照会プロトコル

| 状況 | AI出力例 | 意味／処理フロー |
|------|-----------|----------------|
| 未定義の命名が必要 | `// TODO: require name(Board new post button)` | Windsurf が新命名要求を出力 |
| 照会を受理 | Claude が `候補名: CreatePostButton` を提案 | 設計整合性に基づき候補生成 |
| 承認 | タチコマが `承認: CreatePostButton` を付記 | v2.0 マトリクスに登録 |
| 監査 | Gemini が命名重複・規約逸脱をチェック | BAG-lite解析レポート作成 |

---

### 5.3　AIエージェント責務

| エージェント | 役割 | 責務 |
|--------------|------|------|
| **Windsurf** | 実装AI | 未定義命名を自律生成せず、必ず照会コメントを出力 |
| **Claude** | 設計整形AI | 候補命名を提案し、タチコマ承認後マトリクスへ反映 |
| **タチコマ** | PMO | 命名の最終承認・登録・命名マトリクス更新 |
| **Gemini** | 監査AI | 命名一貫性・多義性・多言語リスクの監査 |

---

### 5.4　照会コメント構文

```tsx
// TODO: require name(<context>)
<context> には機能・用途を英語で簡潔に記述する。

例：// TODO: require name(Board delete confirmation modal)

Claudeは DeletePostConfirmModal を提案し、タチコマ承認後に採用。

5.5　AI命名更新手順
・Windsurf が未定義命名を検出し、コメントを出力。
・Claude が既存マトリクスと整合する候補を提示。
・タチコマが harmonet-naming-matrix_latest.md に追記。
・Gemini が整合性監査レポート（/06_audit/）を生成。
・TKD が最終承認し、Phaseログに反映。

5.6　照会管理表（例）
| 日付         | 要求元      | コンテキスト               | 提案名                    | 承認者  | 状況   |
| ---------- | -------- | -------------------- | ---------------------- | ---- | ---- |
| 2025-11-06 | Windsurf | Board delete modal   | DeletePostConfirmModal | タチコマ | 承認済  |
| 2025-11-08 | Claude   | Survey export button | ExportSurveyButton     | TKD  | 承認予定 |

## 第6章　ChangeLog / メタ情報  
（Document Metadata & Version Control）

---

### 6.1　文書情報
| 項目 | 内容 |
|------|------|
| Document Title | HarmoNet Naming Matrix |
| Version | 2.0 |
| Category | /01_docs/03_rules |
| Author | タチコマ（Tachikoma, PMO） |
| Reviewers | Claude（整形）・Gemini（監査） |
| Approved by | TKD |
| Created | 2025-11-06 |
| Last Updated | 2025-11-06 |

---

### 6.2　ChangeLog

| Version | Date | Description | Author |
|----------|------|-------------|--------|
| v1.0 | 2025-10-30 | 初版作成。Phase8設計統合に基づく命名定義。 | タチコマ |
| v2.0 | 2025-11-06 | Phase9対応。命名体系再構成・Prisma連動・AI命名照会ルール追加。 | タチコマ |

---

### 6.3　関連文書リンク
- [harmonet-coding-standard_v1.1.md](/01_docs/03_rules/harmonet-coding-standard_v1.1.md)  
- [harmonet-design-system_latest.md](/01_docs/03_rules/harmonet-design-system_latest.md)  
- [harmonet-technical-stack-definition_v3.5.md](/01_docs/02_design/harmonet-technical-stack-definition_v3.5.md)  
- [harmonet-phase9-implementation-agreement_v1.0.md](/01_docs/00_project/harmonet-phase9-implementation-agreement_v1.0.md)  

---

### 6.4　ファイル配置情報
**Document ID:** HARMONET-NAMING-MATRIX-V2.0  
**Supersedes:** harmonet-naming-matrix_v1.0.md  
**Location:** `/01_docs/03_rules/harmonet-naming-matrix_v2.0.md`  

---

### 6.5　運用ルール
1. `_latest.md` は Phase10 完全版公開時に差し替え。  
2. 命名の新規登録・変更はタチコマ承認後、Claudeが整形してGeminiが監査。  
3. Geminiの監査結果（/01_docs/06_audit/）をもって命名整合を正式承認。  
4. 旧バージョン（v1.0）は `/01_docs/99_archive/` に保存。  
5. 変更内容はすべて ChangeLog に明記し、ファイル名を変更しない。  

---

### 6.6　締めの声明
本命名マトリクスは、HarmoNet全AIおよび開発者が共通言語として使用する唯一の命名基準である。  
命名の統一は実装品質とチーム知能の両立を支える礎であり、  
Phase9以降のAI協
