# ============================================================
# HarmoNet Chapter Sort Prefix Script v1.0
# Author: タチコマ（HarmoNet AI Architect）
# Purpose:
#   各ディレクトリ（章）内で人間が読む順にファイルを並べるため、
#   ファイル名の先頭に2桁の章内ソート番号を付与する。
# ============================================================

# 作業ディレクトリ（HarmoNetドキュメントルート）
Set-Location "D:\AIDriven\##_成果物\01_プロダクト開発\03_HarmoNetDoc"

# 対象ディレクトリ一覧
$targetDirs = @(
  "00_project",
  "01_requirements",
  "02_design",
  "03_tenant",
  "04_admin",
  "05_implementation",
  "06_audit",
  "07_architecture"
)

# 章ごとに順序制御（指定なしならアルファベット順）
$customOrder = @{
  "00_project"        = @(
    "harmonet-docs-directory-definition", 
    "team", "file-naming", "document-policy",
    "ai-operation", "buddy", "collaboration",
    "workflow", "communication", "update", "dev"
  )
  "01_requirements"   = @("functional", "additional", "nonfunctional", "impact")
  "02_design"         = @("ui-common", "style", "board", "facility", "schema", "template")
  "03_tenant"         = @("idea", "list", "schema", "bag")
  "04_admin"          = @("feature", "schema", "ui", "operation")
  "05_implementation" = @("technical", "api", "test", "deploy")
  "06_audit"          = @("bag", "qa", "release", "anomaly")
  "07_architecture"   = @("system", "environment", "network", "security")
}

foreach ($dir in $targetDirs) {
    Write-Host "`n📂 処理中: $dir"
    $files = Get-ChildItem -Path ".\$dir" -File

    # 章内で独自順序定義がある場合、それを優先
    $order = $customOrder[$dir]
    if ($order) {
        $sorted = $files | Sort-Object {
            $name = $_.BaseName.ToLower()
            $idx = ($order | ForEach-Object { if ($name -like "*$_*") { return [array]::IndexOf($order, $_) } })
            if ($idx -ne $null) { return $idx } else { return 99 }
        }
    } else {
        $sorted = $files | Sort-Object Name
    }

    # ソート順に番号を振る
    $i = 1
    foreach ($file in $sorted) {
        $num = "{0:D2}" -f $i
        if ($file.Name -notmatch "^\d{2}_") {
            $newName = "${num}_$($file.Name)"
            Rename-Item -Path $file.FullName -NewName $newName
            Write-Host "   ✅ $file → $newName"
        } else {
            Write-Host "   ⚠ 既に番号付き: $($file.Name)"
        }
        $i++
    }
}

Write-Host "`n✅ 章内ソート番号付与完了。"
Write-Host "すべてのディレクトリ内のファイルが読解順に並びました。"
