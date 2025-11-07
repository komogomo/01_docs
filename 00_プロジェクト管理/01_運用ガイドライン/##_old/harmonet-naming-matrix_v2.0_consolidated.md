# HarmoNet Naming Matrix v2.0 (Consolidated Draft)
**Category:** /01_docs/03_rules  
**Created:** 2025-11-06  
**Author:** タチコマ（PMO / Architect）  
**Sources:** Claude v2.0 Review / Gemini Completeness Analysis  
**Status:** Consolidated Draft (pre-placement)  

---

## 第1章　命名体系の基本原則
（※Claude版から変更なし。PascalCase / camelCase / snake_case / kebab-case の統一原則を継承）

---

## 第2章　レイヤ別命名ルール
（※Claude版から変更なし。Component / Hook / Type / Token の区分を保持）

---

## 第3章　機能別命名マトリクス（Feature-specific Naming Matrix）

### 3.0　ホーム（Home）

| カテゴリ | 種別 | 命名 | 用途 |
|----------|------|------|------|
| コンポーネント | Page | `HomePage` | ホーム画面トップ |
| コンポーネント | Component | `AnnouncementPreview`, `BoardPreview`, `QuickAccessPanel` | 新着情報・ショートリンク |
| Hook | Fetch | `useHomeData` | ホーム画面データ一括取得 |
| 型／DTO | Type | `HomeData`, `PreviewItem` | 表示データ構造 |

---

### 3.1　掲示板（Board）

（Claude版＋Gemini追補）

| カテゴリ | 種別 | 命名 | 用途 |
|----------|------|------|------|
| コンポーネント | Page | `BoardPage` | 投稿一覧画面 |
| コンポーネント | Component | `PostCard`, `PostDetail`, `PdfPreviewModal`, `TagSelector`, `AttachmentUploader`, `ModerationAlert`, `ReportModal`, `ApprovalIndicator` | 各UI要素 |
| Hook | Fetch | `useBoardList`, `usePostDetail`, `useTagList` | データ取得 |
| Hook | Action | `useCreatePost`, `useDeletePost`, `useReportPost`, `useApprovePost`, `useBookmarkPost` | 投稿操作 |
| 型／DTO | Type | `BoardPost`, `BoardComment`, `BoardAttachment`, `ModerationResult`, `ApprovalLog` | 型定義 |
| API | Service | `fetchBoardList`, `createPost`, `uploadAttachment`, `moderateContent`, `reportPost` | API処理 |
| Enum | 定義 | `PostStatus`, `ModerationDecision`, `TagType` | 状態定義 |

---

### 3.2-A　会議室・集会所（Facility）

| カテゴリ | 種別 | 命名 | 用途 |
|----------|------|------|------|
| コンポーネント | Page | `FacilityPage` | 集会所・会議室予約トップ |
| コンポーネント | Component | `FacilityCard`, `RoomCalendar`, `FacilityForm`, `ReservationCalendar` | UI部品 |
| Hook | Fetch | `useFacilityList`, `useFacilityDetail`, `useReservationList` | データ取得 |
| Hook | Action | `useCreateFacilityReservation`, `useCancelFacilityReservation`, `useBlockReservation` | 予約操作・ブロック設定 |
| 型／DTO | Type | `Facility`, `FacilityReservation`, `FacilitySlot`, `ReservationBlock` | 型定義 |
| API | Service | `fetchFacilityReservations`, `blockReservationSlot` | API処理 |
| Enum | 定義 | `FacilityType`, `FacilityStatus` | 種別・状態 |

---

### 3.2-B　駐車場（Parking）

| カテゴリ | 種別 | 命名 | 用途 |
|----------|------|------|------|
| コンポーネント | Page | `ParkingPage` | 駐車場予約トップ |
| コンポーネント | Component | `ParkingCard`, `ParkingForm`, `ParkingMap` | UI部品 |
| Hook | Fetch | `useParkingList`, `useParkingDetail` | データ取得 |
| Hook | Action | `useCreateParkingReservation`, `useCancelParkingReservation` | 日単位予約 |
| 型／DTO | Type | `Parking`, `ParkingReservation`, `ParkingSlot` | 型定義 |
| API | Service | `fetchParkingReservations`, `createParkingReservation` | API処理 |
| Enum | 定義 | `ParkingType`, `ParkingStatus` | 区分・状態 |

---

### 3.3　お知らせ（Announcement）

| カテゴリ | 種別 | 命名 | 用途 |
|----------|------|------|------|
| コンポーネント | Page | `AnnouncementPage` | 一覧画面 |
| コンポーネント | Component | `AnnouncementCard`, `AnnouncementDetail`, `ReadStatusIndicator` | UI部品 |
| Hook | Fetch | `useAnnouncementList`, `useAnnouncementDetail` | データ取得 |
| Hook | Action | `useMarkAsRead` | 既読操作 |
| 型／DTO | Type | `Announcement`, `AnnouncementRead` | 型定義 |
| API | Service | `fetchAnnouncements`, `markAnnouncementAsRead` | API処理 |
| Enum | 定義 | `AnnouncementTarget` | 対象範囲 |
| トークン | i18n | `label-announcement`, `msg-unread-count` | ラベル |

---

### 3.4　アンケート（Survey）
（既存のまま）

---

### 3.5　マイページ（MyPage）

| カテゴリ | 種別 | 命名 | 用途 |
|----------|------|------|------|
| コンポーネント | Page | `MyPage` | 個人設定画面 |
| コンポーネント | Component | `ProfileCard`, `NotificationSettings`, `ReservationHistory`, `AdminPanel`, `UserManagement` | 設定・履歴・管理 |
| Hook | Fetch | `useUserInfo`, `useNotificationSettings`, `usePostHistory` | データ取得 |
| Hook | Action | `useUpdateProfile`, `useUpdateNotificationSettings`, `useBulkRegisterUsers` | 操作 |
| 型／DTO | Type | `UserProfile`, `NotificationSettings`, `UserHistoryItem` | 型定義 |
| API | Service | `updateProfile`, `updateNotificationSettings`, `bulkRegisterUsers` | API処理 |

---

### 3.6　通知（Notification）

| カテゴリ | 種別 | 命名 | 用途 |
|----------|------|------|------|
| コンポーネント | Component | `NotificationIcon`, `NotificationBadge`, `NotificationList` | 通知UI |
| Hook | Fetch | `useNotifications` | 通知一覧取得 |
| Hook | Action | `useMarkNotificationAsRead` | 既読操作 |
| 型／DTO | Type | `Notification`, `UserNotificationSetting` | 型定義 |
| API | Service | `fetchNotifications`, `updateNotificationSettings` | API処理 |
| Enum | 定義 | `NotificationType`, `NotificationChannel` | 種別・経路 |

---

### 3.7　翻訳（Translation）

| カテゴリ | 種別 | 命名 | 用途 |
|----------|------|------|------|
| コンポーネント | Component | `TranslateButton`, `TranslationDisplay` | 翻訳UI |
| Hook | Action | `useTranslate`, `useInvalidateTranslationCache` | 翻訳処理 |
| 型／DTO | Type | `Translation`, `TranslationCache` | 型定義 |
| API | Service | `translateContent`, `invalidateSession` | API処理 |
| Enum | 定義 | `Locale` | ja/en/zh |
| トークン | i18n | `label-translate`, `msg-translation-loading` | 表示文言 |

---

### 3.8　管理者（Admin）

| カテゴリ | 種別 | 命名 | 用途 |
|----------|------|------|------|
| コンポーネント | Component | `AdminDashboard`, `UserAdminPanel`, `RoleManagement`, `AuditLogViewer` | 管理者UI |
| Hook | Fetch | `useAuditLogs`, `useUserList` | データ取得 |
| Hook | Action | `useUpdateRole`, `useDeleteUser` | 操作 |
| 型／DTO | Type | `AuditLog`, `RoleAssignment` | 型定義 |
| API | Service | `fetchAuditLogs`, `updateRole`, `deleteUser` | API処理 |
| Enum | 定義 | `UserRole`, `PermissionType` | 権限定義 |

---

### 3.9　共通（Common）

| カテゴリ | 種別 | 命名 | 用途 |
|----------|------|------|------|
| コンポーネント | Component | `Header`, `Footer`, `LanguageSwitcher`, `PrimaryButton`, `LayoutContainer` | 共通UI |
| Hook | 共通処理 | `useAuth`, `useSession`, `useResponsive` | 汎用ロジック |
| 型 | 共通型 | `Tenant`, `Session`, `ApiResponse` | 共通スキーマ |
| 定数 | 環境定義 | `API_BASE_URL`, `SUPPORTED_LANGS` | 設定定数 |

---

## 第4章　Supabase・Prismaテーブル対応命名（拡充版）

| 機能 | DBテーブル | Prismaモデル | APIモジュール | 型／DTO | UIコンポーネント |
|------|-------------|--------------|----------------|----------|----------------|
| 掲示板 | `posts` | `Post` | `fetchBoardList` | `BoardPost` | `PostCard` |
| 掲示板添付 | `board_attachments` | `BoardAttachment` | `uploadAttachment` | `AttachmentDTO` | `AttachmentUploader` |
| 掲示板承認ログ | `board_approval_logs` | `BoardApprovalLog` | `fetchApprovalLogs` | `ApprovalLog` | `ApprovalIndicator` |
| お知らせ | `announcements` | `Announcement` | `fetchAnnouncements` | `AnnouncementDTO` | `AnnouncementCard` |
| お知らせ既読 | `announcement_reads` | `AnnouncementRead` | `markAsRead` | `AnnouncementRead` | `ReadStatusIndicator` |
| モデレーションログ | `moderation_logs` | `ModerationLog` | `fetchModerationLogs` | `ModerationResult` | `ModerationAlert` |
| 施設 | `facilities` | `Facility` | `fetchFacilityList` | `Facility` | `FacilityCard` |
| 駐車場 | `parkings` | `Parking` | `fetchParkingList` | `Parking` | `ParkingCard` |
| 通知 | `notifications` | `Notification` | `fetchNotifications` | `NotificationDTO` | `NotificationList` |
| 通知設定 | `user_notification_settings` | `UserNotificationSetting` | `updateNotificationSettings` | `NotificationSettings` | `NotificationSettings` |
| 翻訳キャッシュ | `translation_cache` | `TranslationCache` | `translateContent` | `Translation` | `TranslateButton` |
| 監査ログ | `audit_logs` | `AuditLog` | `fetchAuditLogs` | `AuditLog` | `AuditLogViewer` |

---

## 第5章　AI命名照会ルール
（Claude版そのまま採用。構文・責務区分は既に正）

---

## 第6章　ChangeLog / メタ情報

| Version | Date | Description | Author |
|----------|------|-------------|--------|
| v2.0-draft | 2025-11-06 | Claude構文整形反映 | タチコマ |
| v2.0-consolidated | 2025-11-06 | Gemini完全性分析統合・新章追加（Home/Announcement/Notification/Translation/Admin） | タチコマ |

---

**Document ID:** HNM-NAMING-MATRIX-20251106-CONSOLIDATED  
**Supersedes:** harmonet-naming-matrix_v2.0_draft.md  
**Placement:** Before `/01_docs/03_rules/` official registration  
**Next Step:** Gemini監査 → TKD承認 → `/01_docs/03_rules/harmonet-naming-matrix_v2.0.md` 登録  

---

**End of File**
