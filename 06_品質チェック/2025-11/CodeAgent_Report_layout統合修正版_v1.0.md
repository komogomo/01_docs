[CodeAgent_Report]
Agent: Windsurf
Component: layout統合・StaticI18nProvider適正化
Attempt: 1
AverageScore: 9.4/10
TypeCheck: Passed
Lint: Passed
Tests: Not applicable (構成変更のみ)
Comment: app/layout.tsx 正式化、StaticI18nProvider 正規ルート適用。旧 src/app 配下の layout/I18nRootProvider を削除。ビルド成功、既存機能影響なし（i18nは既存キー運用）。
