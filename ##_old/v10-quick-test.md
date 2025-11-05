# v10 テスト手順（シンプル版）

## 🎯 v10の特徴

**外部JavaScriptファイル（js/i18n.js）の読み込み問題を解決**

- ✅ 翻訳データをHTMLに直接埋め込み
- ✅ ブラウザで直接開いても動作
- ✅ ローカルサーバー不要

---

## 📋 テスト（1分）

### Step 1: ファイルを開く

`index-embedded.html` をダブルクリック

### Step 2: コンソールを確認（任意）

F12 → Console タブ

**成功時のログ:**
```
✅ i18nData embedded successfully
✅ Translations loaded: ja,en,zh
✅ Current language: ja
✅ Translated 11 elements
✅ Initialization complete
```

### Step 3: 言語切り替え

1. **JPボタン** → 青く光る、日本語表示
2. **ENボタン** → 青く光る、英語に変わる
3. **CNボタン** → 青く光る、中国語に変わる

### Step 4: 結果報告

```
【結果】
- JPボタン: ✅ 動作 / ❌ 動作せず
- ENボタン: ✅ 動作 / ❌ 動作せず  
- CNボタン: ✅ 動作 / ❌ 動作せず
- 翻訳: ✅ 正常 / ❌ "login.site.title"等が表示

【動作しない場合】
- ブラウザ: [Chrome / Firefox / Edge / Safari]
- コンソールのエラー: [スクリーンショット添付]
```

---

## 🎯 期待される結果

### 日本語（JP）
```
SECUREA City つくば研究学園
入居者専用Webサイト
住まいコミュニティアプリ
```

### 英語（EN）
```
SECUREA City Tsukuba Kenkyugakuen
Resident Portal
Community Living App
```

### 中国語（CN）
```
SECUREA City 筑波研究学园
住户专用网站
居住社区应用
```

---

## 💡 補足

### もし動作しない場合

**Option A: ローカルサーバーで開く**

Python 3がある場合:
```bash
cd sekurea-demo-v6-complete
python -m http.server 8000
```

ブラウザで開く: `http://localhost:8000/index-embedded.html`

**Option B: 元のindex.html**

ローカルサーバーで開けば、元の`index.html`も動作します。

詳細: `local-server-guide.md` 参照

---

**まず index-embedded.html でテストしてください。結果を報告してください。**
