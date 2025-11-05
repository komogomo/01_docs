# ============================================================
# HarmoNet File Reorganizer v1.0
# Author: タチコマ（HarmoNet AI Architect）
# Purpose:
#   rename_suggestions.txt の結果をもとに、
#   未分類ファイルを正しいディレクトリへ再配置する。
#   HarmoNet Docs 正式構成 v3.1 に整理。
# ============================================================

Set-Location "D:\AIDriven\##_成果物\01_プロダクト開発\03_HarmoNetDoc"

# === 設定パス ===
$projectRoot = (Get-Location).Path
$archiveDir  = Join-Path $projectRoot "99_archive\_old"
$scriptsDir  = Join-Path $projectRoot "00_project\scripts"
$docsDir     = Join-Path $projectRoot "00_project\docs"

# === フォルダ存在チェック＆生成 ===
foreach ($dir in @($archiveDir, $scriptsDir, $docsDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
        Write-Host "📁 Created: $dir"
    }
}

# === 移動対象定義 ===
$rules = @(
    @{pattern="##_old";        dest=$archiveDir; reason="旧作業ファイル群"},
    @{pattern="harmonet_chapter_sort"; dest=$scriptsDir; reason="命名監査スクリプト"},
    @{pattern="reorg_v1.0.sh"; dest=$scriptsDir; reason="再構成スクリプト"},
    @{pattern="FileNaming";    dest=$docsDir;    reason="命名規則文書"},
    @{pattern="Document_Management_Policy"; dest=$docsDir; reason="文書管理方針"}
)

# === 再配置処理 ===
Write-Host "`n🚀 Reorganizing files..."
$moveLog = @()

foreach ($rule in $rules) {
    $files = Get-ChildItem -Recurse -File | Where-Object {
        $_.FullName -match $rule.pattern -and
        $_.FullName -notmatch "99_archive|scripts|docs"
    }

    foreach ($f in $files) {
        $destPath = Join-Path $rule.dest $f.Name
        try {
            Move-Item -Path $f.FullName -Destination $destPath -Force
            $moveLog += "✅ [$($rule.reason)] $($f.Name) → $($rule.dest)"
            Write-Host "✅ Moved: $($f.Name) → $($rule.dest)"
        } catch {
            $moveLog += "⚠ Failed: $($f.Name) → $($_.Exception.Message)"
            Write-Host "⚠ Failed to move: $($f.Name)"
        }
    }
}

# === ログ出力 ===
$logPath = ".\reorganize_log.txt"
$moveLog | Out-File -FilePath $logPath -Encoding UTF8

Write-Host "`n📄 再配置完了ログ: $logPath"
Write-Host "✅ HarmoNet Docs 構造が正式版 v3.1 に整いました。"
Write-Host "   - 旧作業ファイルは 99_archive/_old/ に退避"
Write-Host "   - スクリプトは 00_project/scripts/ に統合"
Write-Host "   - ルール文書は 00_project/docs/ に統合"
