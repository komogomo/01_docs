# HarmoNet Directory Sync Script v3.2 監査レポート（タチコマレビュー）
**Document Category:** scripts/review  
**Status:** Reviewed (minor fix required)  
**Target Script:** `harmonet_dir_sync_v3.2.ps1`  
**Source:** Claude (2025-11-02)

---

## 1. 目的
Claudeが生成したディレクトリ再配置用PowerShellスクリプトを、  
タチコマ(PMO/Architect)の立場で安全性・HarmoNet共通方針との整合性を確認する。

---

## 2. 対象スクリプトの概要
スクリプトの処理フローはこうなっている。

1. **カレント固定**：  
   ```ps1
   Set-Location "D:\AIDriven\##_成果物\01_プロダクト開発\03_HarmoNetDoc"

固定パスでPJルートに移動。

Phase 1: 章番号リネーム + ディレクトリマージ

01_docs\01_project → 01_docs\00_project に中身をコピーしてから
元の 01_docs\01_project を Remove-Item -Recurse -Force で削除。

その後、以下のマップで一括リネーム：

01_docs\02_requirements          → 01_docs\00_requirements
01_docs\03_basic_design          → 01_docs\01_basic_design
01_docs\04_integration           → 01_docs\02_integration
01_docs\05_operation_preparation → 01_docs\03_operation_preparation
01_docs\06_tenant                → 01_docs\04_tenant
01_docs\07_audit                 → 01_docs\06_audit
01_docs\08_common                → 01_docs\common

3.Phase 2: ルート直下ファイルの移動

HarmoNet 開発方針共有メモ(2025-11-01).md → 01_docs\00_project\harmonet-dev-shared-summary_2025-11-01.md

harmonet-document-policy_latest.md → 01_docs\00_project\...

schema-definition-overview_v1.0.md → 01_docs\01_basic_design\...

harmonet-docs-directory-definition_v3.2.md → 01_docs\00_project\...

4.Phase 3: 大文字→小文字

03_Rules → 03_rules

5.Phase 4: 必要ディレクトリ作成

01_docs\99_archive を作成

6.最後にログと手動Gitコマンドを表示

3. よかった点

すべての処理に Write-Log が入っていて、何をやったかが残る設計になっている。これはHarmoNetの「後からClaude/Geminiで追える」前提に合ってる。

参照先が存在するかどうかを都度 Test-Path で見ていて、致命的なミスには倒れにくい。

実行後にGitでスナップショットを取る手順まで書いてあるので、ロールバック可能。

4. 問題点・HarmoNet方針とのズレ

1.パスがハードコードされている

現状：
Set-Location "D:\AIDriven\##_成果物\01_プロダクト開発\03_HarmoNetDoc"

これはTKDさんのローカル専用になるので、今後ほかの環境で実行するたびに書き換えが必要。

→ 引数化する or $RootPath 変数に出すべき。

2.01_docs\01_project を即削除している

今のコードだと、マージ後に
Remove-Item -Path $Source01Project -Recurse -Force

を実行している。

でもHarmoNetでは「##_old か 99_archive に退避してから消す」が標準なので、いきなり削除はNG寄り。

→ 01_docs\99_archive\01_project_YYYYMMDD-HHMMSS にリネーム退避してから削除するのが安全。

3.最新版のタチコマ承認メモとのギャップ

タチコマの承認メモでは

「05_implementation/ を作って連番を埋める」
としたが、スクリプトは 作っていない（Phase 4で作っているのは 01_docs\99_archive だけ）。

→ このスクリプトには 01_docs\05_implementation を追加作成する行が必要。

4.リネームが「存在してたらWARNでスキップ」になっている

これは安全側ではあるが、**「途中までしか直ってない半端なディレクトリ」**が残る可能性がある。

→ 実行後のログを必ず見て、人間(TKD)が「WARN行がなかったか」チェックする前提にすればOK。

5.スクリーン統一が入っていない

これは意図通り（Phase 8に回す）なので問題なし。

→ 逆に言うと、**このスクリプトは「screensを触らない安全版」**としてClaudeに伝えておくと親切。

5. タチコマ修正版スクリプト案（v3.2r1）

以下は、上記の問題を最小修正で直した版。元のClaude版を壊さないように引数化＋05_implementation追加＋削除→退避だけにしています。
# ============================================================================
# HarmoNet Directory Sync Script v3.2r1 (tachikoma-reviewed)
# ============================================================================
param(
    [string]$RootPath = "D:\AIDriven\##_成果物\01_プロダクト開発\03_HarmoNetDoc",
    [switch]$DryRun
)

Set-Location $RootPath

$LogFile = "dir_sync_log_$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$ErrorCount = 0
$SuccessCount = 0

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $msg = "[$ts] [$Level] $Message"
    Write-Host $msg
    Add-Content -Path $LogFile -Value $msg
}

function Ensure-Dir {
    param([string]$DirPath)
    if (-not (Test-Path $DirPath)) {
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $DirPath -Force | Out-Null
        }
        Write-Log "作成: $DirPath" "INFO"
    }
}

Write-Log "========================================" "INFO"
Write-Log "HarmoNet Directory Sync v3.2r1 開始" "INFO"
Write-Log "Root: $RootPath" "INFO"

# ============================================================================
# Phase 1: 章番号リネーム + ディレクトリマージ
# ============================================================================

Write-Log "Phase 1: 章番号リネーム開始" "INFO"

$Source01Project = "01_docs\01_project"
$Dest00Project   = "01_docs\00_project"
$ArchiveRoot     = "01_docs\99_archive"

Ensure-Dir $Dest00Project
Ensure-Dir $ArchiveRoot

if (Test-Path $Source01Project) {
    # 中身を00_projectにマージ
    Get-ChildItem -Path $Source01Project -Recurse -File | ForEach-Object {
        $rel  = $_.FullName.Substring((Resolve-Path $Source01Project).Path.Length + 1)
        $dest = Join-Path $Dest00Project $rel
        $destDir = Split-Path $dest -Parent
        Ensure-Dir $destDir

        if (Test-Path $dest) {
            Write-Log "警告: 既に存在するためスキップ: $dest" "WARN"
        } else {
            if (-not $DryRun) {
                Copy-Item -Path $_.FullName -Destination $dest -Force
            }
            Write-Log "マージ: $($_.Name) → $dest" "INFO"
            $SuccessCount++
        }
    }

    # 旧01_projectは削除せずアーカイブへ退避
    $ArchiveName = Join-Path $ArchiveRoot ("01_project_" + (Get-Date -Format "yyyyMMdd-HHmmss"))
    if (-not $DryRun) {
        Rename-Item -Path $Source01Project -NewName $ArchiveName -Force
    }
    Write-Log "退避: $Source01Project → $ArchiveName" "INFO"
} else {
    Write-Log "情報: 01_docs\01_project は存在しません(スキップ)" "INFO"
}

# 章番号リネーム
$RenameMap = @{
    "01_docs\02_requirements"          = "01_docs\00_requirements"
    "01_docs\03_basic_design"          = "01_docs\01_basic_design"
    "01_docs\04_integration"           = "01_docs\02_integration"
    "01_docs\05_operation_preparation" = "01_docs\03_operation_preparation"
    "01_docs\06_tenant"                = "01_docs\04_tenant"
    "01_docs\07_audit"                 = "01_docs\06_audit"
    "01_docs\08_common"                = "01_docs\common"
}

foreach ($Old in $RenameMap.Keys) {
    $New = $RenameMap[$Old]
    if (Test-Path $Old) {
        if (Test-Path $New) {
            Write-Log "警告: $New は既に存在します。リネームをスキップします。" "WARN"
        } else {
            if (-not $DryRun) {
                Rename-Item -Path $Old -NewName (Split-Path $New -Leaf) -Force
            }
            Write-Log "リネーム: $Old → $New" "INFO"
            $SuccessCount++
        }
    } else {
        Write-Log "情報: $Old は存在しません(スキップ)" "INFO"
    }
}

# ============================================================================
# Phase 2: ルート直下ファイルの移動
# ============================================================================

Write-Log "Phase 2: ルート直下ファイルの移動開始" "INFO"

$FileMoveMap = @{
    "HarmoNet 開発方針共有メモ(2025-11-01).md"  = "01_docs\00_project\harmonet-dev-shared-summary_2025-11-01.md"
    "harmonet-document-policy_latest.md"         = "01_docs\00_project\harmonet-document-policy_latest.md"
    "schema-definition-overview_v1.0.md"         = "01_docs\01_basic_design\schema-definition-overview_v1.0.md"
    "harmonet-docs-directory-definition_v3.2.md" = "01_docs\00_project\harmonet-docs-directory-definition_v3.2.md"
}

foreach ($OldFile in $FileMoveMap.Keys) {
    $NewFile = $FileMoveMap[$OldFile]
    if (Test-Path $OldFile) {
        $DestDir = Split-Path $NewFile -Parent
        Ensure-Dir $DestDir
        if (Test-Path $NewFile) {
            Write-Log "警告: $NewFile は既に存在します。スキップ。" "WARN"
        } else {
            if (-not $DryRun) {
                Move-Item -Path $OldFile -Destination $NewFile -Force
            }
            Write-Log "移動: $OldFile → $NewFile" "INFO"
            $SuccessCount++
        }
    } else {
        Write-Log "情報: $OldFile は存在しません(スキップ)" "INFO"
    }
}

# ============================================================================
# Phase 3: ディレクトリ名修正
# ============================================================================
Write-Log "Phase 3: ディレクトリ名修正開始" "INFO"
if (Test-Path "03_Rules") {
    if (-not (Test-Path "03_rules")) {
        if (-not $DryRun) {
            Rename-Item -Path "03_Rules" -NewName "03_rules" -Force
        }
        Write-Log "リネーム: 03_Rules → 03_rules" "INFO"
    } else {
        Write-Log "警告: 03_rules が既にあるためリネームしませんでした" "WARN"
    }
} else {
    Write-Log "情報: 03_Rules は存在しません(スキップ)" "INFO"
}

# ============================================================================
# Phase 4: 必要なディレクトリの作成
# ============================================================================
Write-Log "Phase 4: 必要なディレクトリの作成開始" "INFO"

$RequiredDirs = @(
    "01_docs\05_implementation",  # ← タチコマ承認メモで追加したやつ
    "01_docs\99_archive"
)

foreach ($Dir in $RequiredDirs) {
    if (-not (Test-Path $Dir)) {
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $Dir -Force | Out-Null
        }
        Write-Log "作成: $Dir" "INFO"
    } else {
        Write-Log "情報: $Dir は既に存在します(スキップ)" "INFO"
    }
}

Write-Log "========================================" "INFO"
Write-Log "HarmoNet Directory Sync v3.2r1 完了" "INFO"
Write-Log "成功: $SuccessCount 件 / 失敗: $ErrorCount 件" "INFO"
Write-Host "`n完了しました。ログ: $LogFile"

6. 実行手順（タチコマ推奨）

1.現状をGitに保存
git add .
git commit -m "snapshot: before dir sync v3.2"

2.上の v3.2r1 スクリプトを保存して1回目はドライラン
.\harmonet_dir_sync_v3.2r1.ps1 -DryRun

→ ログを見て、意図しない移動がないか確認

3.問題なければ本番実行
.\harmonet_dir_sync_v3.2r1.ps1

4.Gitで確定
git add .
git commit -m "refactor: directory structure aligned to v3.2 (tachikoma reviewed)"
git push origin main

7. 結論

Claudeの元スクリプトは概ね安全だが、タチコマ承認メモで決めた
「05_implementationを空でも作る」「削除はアーカイブしてから」
の2点が入っていなかったので、上記のとおりr1版にして実行するのがHarmoNet流。

これをClaudeに渡すときは

「タチコマ確認で、パス引数化＋05_implementation追加＋01_projectを即削除せずアーカイブに変更、まで反映しました」
と添えておけばOK。

Document ID: HNM-DIR-SCRIPT-REVIEW-20251102
Version: 1.0
Created: 2025-11-02
Reviewed by: タチコマ
For: TKD / Claude