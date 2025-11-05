# Header & Footer 改善ガイド v1.1

## 改善概要

アップロードされた `header-footer-improved.html` のレビュー結果に基づき、以下2点の改善を実施します。

### ✅ 良好な点
- TailwindCSSとカスタムCSSの併用で構造が明確
- header/demo/footer の3層構造で再利用性が高い
- `max-width: 420px`でモバイル最適化
- 言語切替UIの視認性・アクセシビリティが良好
- `lang-btn--active`の影効果でクリック状態が明確

### 🔧 改善項目
1. **demo-screen部分の実装時の注意コメント追加**
2. **localStorage による言語選択の永続化実装**

---

## 改善1: demo-screen部分の実装コメント追加

### 目的
モック表示専用の `demo-screen` ブロックを、実際の実装時に `<main>` へ置き換える際の指針を明確化します。

### 追加すべきコメント例

```html
<!-- Demo Screen Area -->
<!-- 
    【実装時の注意】
    このdemo-screenブロックはモック表示専用です。
    実際の実装時には、このブロックを<main>タグに置き換えてください。
    
    例:
    <main class="page-content">
        <!-- 各画面のコンテンツをここに配置 -->
    </main>
-->
<div class="demo-screen">
    <div class="demo-content">
        <!-- モックコンテンツ -->
    </div>
</div>
```

### 実装時の注意点
- `demo-screen` のスタイルは削除または `page-content` 等にリネーム
- 高さ固定 (`height: 400px`) を削除し、コンテンツに応じた可変高に変更
- flexレイアウトの `align-items: center` / `justify-content: center` を必要に応じて調整

---

## 改善2: localStorage による言語選択の永続化

### 目的
現状はページリロードで言語選択がリセットされるため、ユーザー選択を永続化します。

### 実装方針
1. 言語ボタンクリック時に `localStorage` へ選択言語を保存
2. ページ読み込み時に `localStorage` から言語設定を復元
3. 初回アクセス時はデフォルト言語（日本語）を使用

### 実装コード例

#### JavaScript全体（置き換え）

```javascript
// ========================================
// 言語切替機能（localStorage対応）
// ========================================

// デフォルト言語
const DEFAULT_LANG = 'ja';
// localStorageキー
const LANG_STORAGE_KEY = 'harmonet_selected_language';

/**
 * 選択された言語をlocalStorageに保存
 * @param {string} lang - 言語コード（ja/en/cn）
 */
function saveLanguage(lang) {
    try {
        localStorage.setItem(LANG_STORAGE_KEY, lang);
    } catch (e) {
        console.warn('localStorage保存に失敗しました:', e);
    }
}

/**
 * localStorageから言語設定を取得
 * @returns {string} 言語コード（ja/en/cn）
 */
function loadLanguage() {
    try {
        return localStorage.getItem(LANG_STORAGE_KEY) || DEFAULT_LANG;
    } catch (e) {
        console.warn('localStorage読み込みに失敗しました:', e);
        return DEFAULT_LANG;
    }
}

/**
 * 言語ボタンのアクティブ状態を更新
 * @param {string} lang - アクティブにする言語コード
 */
function setActiveLanguage(lang) {
    document.querySelectorAll('.lang-btn').forEach(btn => {
        if (btn.dataset.lang === lang) {
            btn.classList.add('lang-btn--active');
        } else {
            btn.classList.remove('lang-btn--active');
        }
    });
}

/**
 * 言語切替処理
 * @param {string} lang - 切り替え先の言語コード
 */
function switchLanguage(lang) {
    // アクティブ状態更新
    setActiveLanguage(lang);
    
    // localStorage保存
    saveLanguage(lang);
    
    // 実際の翻訳処理はここに実装
    // 例: i18n.changeLanguage(lang);
    console.log(`言語を ${lang} に切り替えました`);
}

// ========================================
// 初期化処理
// ========================================

document.addEventListener('DOMContentLoaded', function() {
    // 保存された言語を復元
    const savedLang = loadLanguage();
    setActiveLanguage(savedLang);
    
    // 言語切替ボタンのイベント設定
    document.querySelectorAll('.lang-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            const selectedLang = this.dataset.lang;
            switchLanguage(selectedLang);
        });
    });
    
    // フッターボタンのアクティブ状態切替
    document.querySelectorAll('.footer-nav-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            // ログアウトボタンは除外
            if (this.dataset.page === 'logout') {
                return;
            }
            
            document.querySelectorAll('.footer-nav-btn').forEach(b => {
                b.classList.remove('footer-nav-btn--active');
            });
            this.classList.add('footer-nav-btn--active');
        });
    });
});
```

### 主な変更点

#### 1. localStorage操作関数
- `saveLanguage()`: 選択言語を保存
- `loadLanguage()`: 保存された言語を取得（エラー時はデフォルト値）

#### 2. 初期化処理
- ページ読み込み時に `DOMContentLoaded` イベントで自動実行
- 保存された言語設定を自動復元
- 初回アクセス時は日本語（`ja`）がデフォルト

#### 3. エラーハンドリング
- localStorage が使用できない環境（プライベートブラウジング等）でもエラーを回避
- console.warn でデバッグ情報を出力

---

## 実装チェックリスト

### 改善1: コメント追加
- [ ] `demo-screen` ブロック直前にコメント追加
- [ ] 実装時の置き換え手順を明記
- [ ] スタイル調整の注意点を記載

### 改善2: localStorage実装
- [ ] 言語切替関数を実装
- [ ] localStorage保存・読み込み関数を実装
- [ ] 初期化処理で保存された言語を復元
- [ ] エラーハンドリングを実装
- [ ] デフォルト言語設定を確認

### 動作確認
- [ ] 言語切替が正常に動作するか確認
- [ ] ページリロード後も選択言語が保持されるか確認
- [ ] 初回アクセス時にデフォルト言語（日本語）が選択されるか確認
- [ ] プライベートブラウジングモードでもエラーが発生しないか確認

### コード品質
- [ ] BEM命名規則に準拠しているか確認
- [ ] 日本語コメントが適切に記載されているか確認
- [ ] 関数が30行以内に収まっているか確認
- [ ] 不要なコードが残っていないか確認

---

## 補足: 実際の翻訳機能との統合

現状のコードは言語選択の永続化のみを実装しています。実際の翻訳機能（i18n.js等）と統合する場合は、`switchLanguage()` 関数内で以下のような処理を追加してください。

```javascript
function switchLanguage(lang) {
    setActiveLanguage(lang);
    saveLanguage(lang);
    
    // 実際の翻訳処理（実装例）
    if (window.i18n && typeof window.i18n.changeLanguage === 'function') {
        window.i18n.changeLanguage(lang);
    }
}
```

---

**ドキュメントバージョン**: v1.1  
**作成日**: 2025-10-27  
**対象ファイル**: header-footer-improved.html
