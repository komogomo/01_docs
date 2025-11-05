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
