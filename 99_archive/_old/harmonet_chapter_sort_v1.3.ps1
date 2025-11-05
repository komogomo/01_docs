# ============================================================
# HarmoNet Chapter Sort Prefix Script v1.3
# Author: タチコマ（HarmoNet AI Architect）
# Purpose:
#   各ディレクトリ内のファイルを工程順に番号付け。
#   さらに命名規則外のファイルを検出し、推定工程を提案する。
# ============================================================

Set-Location "D:\AIDriven\##_成果物\01_プロダクト開発\03_HarmoNetDoc"

# 対象ディレクトリ自動検出（除外あり）
$targetDirs = Get-ChildItem -Directory | Where-Object {
    $_.Name -notmatch "99_BACKUP|merge|archive"
} | Select-Object -ExpandProperty Name

Write-Host "`n📂 対象ディレクトリ:"
$targetDirs | ForEach-Object { Write-Host "   - $_" }

# 工程キーワードと順序
$phaseOrder = @(
    @{key="pre";      order=1;  label="事前準備"},
    @{key="lite";     order=2;  label="簡易監査"},
    @{key="full";     order=3;  label="完全実施"},
    @{key="quality";  order=4;  label="品質承認"},
    @{key="summary";  order=5;  label="要約・まとめ"},
    @{key="report";   order=6;  label="報告書"},
    @{key="approval"; order=7;  label="承認"},
    @{key="release";  order=8;  label="リリース"},
    @{key="manual";   order=9;  label="運用マニュアル"},
    @{key="default";  order=99; label="不明"}
)

# 推定関数：ファイル名から工程順を取得
function Get-PhaseRank($filename) {
    foreach ($phase in $phaseOrder) {
        if ($filename -match $phase.key) { return $phase.order }
    }
    return 99
}

# 推定関数：ファイル名から工程ラベルを取得
function Get-PhaseLabel($filename) {
    foreach ($phase in $phaseOrder) {
        if ($filename -match $phase.key) { return $phase.label }
    }
    return "未分類"
}

# 結果レポート初期化
$report = @()
$reportPath = ".\rename_suggestions.txt"
if (Test-Path $reportPath) { Remove-Item $reportPath }

# ディレクトリ処理ループ
foreach ($dir in $targetDirs) {
    Write-Host "`n📁 処理中: $dir"
    $path = ".\$dir"
    $files = Get-ChildItem -Path $path -File
    if ($files.Count -eq 0) {
        Write-Host "   ⚠ ファイルなし: スキップ"
        continue
    }

    # 並び替え
    $sorted = $files | Sort-Object { Get-PhaseRank($_.BaseName) }, Name

    $i = 1
    foreach ($file in $sorted) {
        $num = "{0:D2}" -f $i
        $base = $file.Name -replace '^\d{2}_',''
        $newName = "${num}_$base"

        # 既に番号が違っている場合のみリネーム
        if ($file.Name -ne $newName) {
            Rename-Item -Path $file.FullName -NewName $newName -Force
            Write-Host "   ✅ $($file.Name) → $newName"
        } else {
            Write-Host "   ⚙ $($file.Name) （変更なし）"
        }

        # 未分類ファイルを検出
        $label = Get-PhaseLabel($file.BaseName)
        if ($label -eq "未分類") {
            $report += "⚠ [$dir] $($file.Name) → 推定工程: 未分類（AI補助推定必要）"
        }

        $i++
    }
}

# レポート出力
if ($report.Count -gt 0) {
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "`n⚠ 命名規則外ファイルを $reportPath に出力しました。"
} else {
    Write-Host "`n✅ すべてのファイルが命名規則に準拠しています。"
}

Write-Host "`n🏁 完了：工程順整列 + 命名監査が終了しました。"
