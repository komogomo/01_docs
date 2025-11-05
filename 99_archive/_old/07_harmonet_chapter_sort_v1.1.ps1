# ============================================================
# HarmoNet Chapter Sort Prefix Script v1.1
# Author: タチコマ（HarmoNet AI Architect）
# Purpose:
#   現在のディレクトリ構成に基づき、存在する章内のファイルに
#   読解順番号を付与。存在しない章は自動生成してスキップ。
# ============================================================

Set-Location "D:\AIDriven\##_成果物\01_プロダクト開発\03_HarmoNetDoc"

# 現在存在するフォルダを自動検出
$targetDirs = Get-ChildItem -Directory | Where-Object {
    $_.Name -notmatch "99_BACKUP|merge"
} | Select-Object -ExpandProperty Name

Write-Host "`n📂 検出ディレクトリ一覧:"
$targetDirs | ForEach-Object { Write-Host "   - $_" }

# フォルダが存在しない場合は作成
foreach ($dir in $targetDirs) {
    $path = ".\$dir"
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
        Write-Host "📁 Created missing directory: $path"
    }
}

# ディレクトリごとの読解順ヒント
$customOrder = @{
  "00_project"              = @("docs", "team", "file-naming", "policy", "ai", "buddy", "collaboration", "workflow", "update", "dev")
  "00_requirements"         = @("functional", "additional", "nonfunctional", "impact")
  "01_basic_design"         = @("ui", "style", "schema", "template", "board", "facility")
  "02_integration"          = @("api", "interface", "flow", "sequence", "deployment")
  "03_operation_preparation"= @("operation", "manual", "flow", "rule")
  "03_tenant"               = @("idea", "list", "schema", "bag", "config")
  "06_audit"                = @("bag", "qa", "release", "anomaly")
  "common"                  = @("template", "guideline", "style", "ref")
}

# 各章を処理
foreach ($dir in $targetDirs) {
    Write-Host "`n📂 処理中: $dir"
    $files = Get-ChildItem -Path ".\$dir" -File
    if ($files.Count -eq 0) {
        Write-Host "   ⚠ ファイルなし。スキップ。"
        continue
    }

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
Write-Host "存在するすべてのディレクトリが対象になりました。"
