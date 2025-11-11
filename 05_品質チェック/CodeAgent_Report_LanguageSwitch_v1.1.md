[CodeAgent_Report]
Agent: Windsurf
Component: LanguageSwitch (C-02)
Attempt: 1
AverageScore: 9.3/10
TypeCheck: Passed
Lint: Passed
Tests: 100% Passed
Comment: 依存衝突により next-intl を未採用（Next 16 と peer 不一致のため）。UI/振る舞い仕様は next/navigation + currentLocale props で満たし、AppHeader 依存での動作・UT・Lint を完了。

[Generated_Files]
- src/components/common/LanguageSwitch/LanguageSwitch.tsx
- src/components/common/LanguageSwitch/LanguageSwitch.types.ts
- src/components/common/LanguageSwitch/LanguageSwitch.test.tsx
- src/components/common/LanguageSwitch/index.ts
- src/components/common/LanguageSwitch/index.tsx
- src/components/common/LanguageSwitch/LanguageSwitch.stories.tsx
- jest.config.mjs
- setupTests.ts
- .eslintrc.json
- .prettierrc
- .storybook/main.ts
- .storybook/preview.ts
