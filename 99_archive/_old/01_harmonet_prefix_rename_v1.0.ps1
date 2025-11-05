# =========================================================
# HarmoNet Prefix Rename Script v1.0
# Author: タチコマ（HarmoNet AI Architect）
# Purpose:
#   ファイル名の先頭に章番号プレフィックスを付与して
#   論理順でソート可能な構成に統一する。
# =========================================================

# 作業ディレクトリ（HarmoNetDocルートに変更）
Set-Location "D:\AIDriven\##_成果物\01_プロダクト開発\03_HarmoNetDoc"

# マッピング定義（ディレクトリ階層と番号帯）
$prefixMap = @{
  "00_project"        = "01"
  "01_requirements"   = "02"
  "02_design"         = "03"
  "03_tenant"         = "04"
  "04_admin"          = "05"
  "05_implementation" = "06"
  "06_audit"          = "07"
  "07_architecture"   = "08"
  "99_archive"        = "99"
}

# 除外対象（バックアップなど）
$ignoreDirs = @("99_BACKUP_inactive_20251031")

foreach ($dir in $prefixMap.Keys) {

    if ($ignoreDirs -contains $dir) { continue }
    $prefix = $prefixMap[$dir]

    $path = ".\$dir"
    if (-not (Test-Path $path)) { continue }

    Write-Host "`n📂 処理中: $dir"

    # ファイルごとに番号付与（サブ番号2桁カウント）
    $count = 1
    Get-ChildItem -Path $path -File | ForEach-Object {
        $file = $_.Name
        if ($file -match "^\d{2}_") {
            Write-Host "   ⚠ 既に番号付与済: $file"
        }
        else {
            $num = "{0:D2}" -f $count
            $newName = "${prefix}_${num}_$file"
            Rename-Item -Path $_.FullName -NewName $newName
            Write-Host "   ✅ $file → $newName"
            $count++
        }
    }
}

Write-Host "`n✅ プレフィックス付与完了！"
Write-Host "ファイルが章番号順（01〜99）でソートされるようになりました。"
