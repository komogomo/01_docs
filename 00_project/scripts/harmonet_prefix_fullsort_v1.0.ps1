# ============================================================
# HarmoNet Prefix FullSort v1.0
# Author: タチコマ（HarmoNet AI Architect）
# Purpose:
#   docs配下のすべてのディレクトリとファイルに順序番号を付与し、
#   人間が理解しやすい読解順に並ぶ完全プレフィックス構造を実現する。
# ============================================================

# === 基準パス ===
$root = "D:\AIDriven\##_成果物\01_プロダクト開発\03_HarmoNetDoc"
$docsRoot = Join-Path $root "docs"
Set-Location $docsRoot

# === 除外対象 ===
$exclude = @("99_archive", "99_BACKUP_inactive_20251031", "merge")

# === 章ディレクトリ順序（読解順） ===
$chapters = @(
    "project",
    "requirements",
    "basic_design",
    "integration",
    "operation_preparation",
    "tenant",
    "audit",
    "common",
    "archive",
    "backup_inactive_20251031"
)

# === 1. ディレクトリ名に章番号を付与 ===
Write-Host "`n📁 ディレクトリ番号付与開始..."
$i = 1
foreach ($chapter in $chapters) {
    $num = "{0:D2}" -f $i
    $old = Get-ChildItem -Directory | Where-Object { $_.Name -match $chapter -and ($exclude -notcontains $_.Name) }
    if ($old) {
        foreach ($dir in $old) {
            $newName = "${num}_$chapter"
            if ($dir.Name -ne $newName) {
                Rename-Item -Path $dir.FullName -NewName $newName -Force
                Write-Host "✅ $($dir.Name) → $newName"
            } else {
                Write-Host "⚙ $($dir.Name) 変更なし"
            }
        }
    }
    $i++
}

# === 2. 各章内のファイルに番号付与 ===
Write-Host "`n📄 ファイル番号付与開始..."

# 工程キーワード（読解順）を補助として利用
$phaseOrder = @("pre", "lite", "full", "quality", "summary", "report", "approval", "release", "manual")

# ファイル番号処理関数
function Assign-FileNumbers($dirPath) {
    $files = Get-ChildItem -Path $dirPath -File
    if ($files.Count -eq 0) { return }

    # 工程キーワードがあればそれで並べ替え、なければ名前順
    $sorted = $files | Sort-Object {
        $name = $_.BaseName.ToLower()
        $match = $phaseOrder | Where-Object { $name -match $_ }
        if ($match) { [array]::IndexOf($phaseOrder, $match[0]) } else { 99 }
    }, Name

    $n = 1
    foreach ($f in $sorted) {
        $num = "{0:D2}" -f $n
        $newName = "$num" + "_" + ($f.Name -replace '^\d{2}_', '')
        if ($f.Name -ne $newName) {
            Rename-Item -Path $f.FullName -NewName $newName -Force
            Write-Host "   ✅ [$((Split-Path $dirPath -Leaf))] $($f.Name) → $newName"
        } else {
            Write-Host "   ⚙ [$((Split-Path $dirPath -Leaf))] $($f.Name) 変更なし"
        }
        $n++
    }
}

# 章ディレクトリ内を走査
Get-ChildItem -Directory | Where-Object { $exclude -notcontains $_.Name } | ForEach-Object {
    Assign-FileNumbers $_.FullName
}

Write-Host "`n🏁 完了：ディレクトリとファイルすべてに順序プレフィックスを付与しました。"
Write-Host "   ExplorerやGitHub上でも完全な読解順に整列しています。"
