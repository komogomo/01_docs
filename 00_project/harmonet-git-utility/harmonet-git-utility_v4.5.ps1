# ==========================================================
# HarmoNet Git Utility v4.5 (Console / Stable)
# Author : Tachikoma + Claude
# Purpose: Safe Git operations with menu UI for HarmoNet Phase9
# Changelog v4.5:
#   - Added: Multi-line commit message support
#   - Input END on empty line to finish message
#   - Preview message before commit
#   - Inherits all v4.4 improvements
# ==========================================================

# UTF-8 encoding setup for proper Japanese display
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Set Git to use UTF-8 for Japanese characters
$env:LESSCHARSET = "utf-8"

# Auto-detect repository root
$ScriptPath = $MyInvocation.MyCommand.Path
$ScriptDir  = Split-Path -Parent $ScriptPath

function Find-GitRoot {
    param([string]$StartPath)
    
    $currentPath = $StartPath
    while ($currentPath) {
        if (Test-Path (Join-Path $currentPath ".git")) {
            return $currentPath
        }
        $parent = Split-Path -Parent $currentPath
        if ($parent -eq $currentPath) { break }
        $currentPath = $parent
    }
    return $null
}

# Detect repository configurations
$Repos = @()

# Try to find repository from script location
$detectedRepo = Find-GitRoot $ScriptDir
if ($detectedRepo) {
    $repoName = Split-Path -Leaf $detectedRepo
    $Repos += @{ 
        Name = "自動検出: $repoName"
        Path = $detectedRepo
        Remote = ""
    }
}

# Add predefined repositories if they exist
$predefinedRepos = @(
    @{ Name = "設計書リポジトリ (01_docs)"; Path = "D:\AIDriven\01_docs"; Remote = "https://github.com/komogomo/01_docs.git" },
    @{ Name = "開発資材リポジトリ (Projects-HarmoNet)"; Path = "D:\Projects\HarmoNet"; Remote = "https://github.com/komogomo/Projects-HarmoNet.git" }
)

foreach ($repo in $predefinedRepos) {
    # Skip if already detected from script location
    if ($detectedRepo -and $repo.Path -eq $detectedRepo) {
        continue
    }
    # Only add if path exists
    if (Test-Path $repo.Path) {
        $Repos += $repo
    }
}

# Fallback: If no repositories found, show error
if ($Repos.Count -eq 0) {
    Write-Host "❌ エラー: 利用可能なGitリポジトリが見つかりません。" -ForegroundColor Red
    Write-Host ""
    Write-Host "このスクリプトは以下のいずれかの場所に配置してください:"
    Write-Host "  1. Gitリポジトリ内の任意の場所"
    Write-Host "  2. D:\AIDriven\01_docs が存在する環境"
    Write-Host "  3. D:\Projects\HarmoNet が存在する環境"
    Write-Host ""
    Read-Host "Enterキーで終了します..."
    exit
}

$LogFile = Join-Path $ScriptDir "harmonet_git_log.txt"

function Pause-Menu { 
    Write-Host ""
    Read-Host "Enterキーでメニューに戻ります..." > $null
}

function Log-Action {
    param($repoName, $action, $message)
    $entry = "{0} : [{1}] {2} - {3}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $repoName, $action, $message
    Add-Content -Path $LogFile -Value $entry -Encoding UTF8
}

function Ensure-RepoPath {
    param($path)
    if (-not (Test-Path $path)) {
        Write-Host "[ERR] ディレクトリが存在しません: $path" -ForegroundColor Red
        return $false
    }
    return $true
}

function Section { param($title); Write-Host ""; Write-Host "==== $title ====" }

function Exec-Git {
    param(
        [string[]]$Arguments,
        [string]$WorkDir,
        [switch]$Paged
    )
    if (-not (Ensure-RepoPath $WorkDir)) { return $false }
    Push-Location $WorkDir
    try {
        if ($Paged) {
            & git @Arguments | more
        } else {
            & git @Arguments
        }
        return $LASTEXITCODE -eq 0
    } finally {
        Pop-Location
    }
}

# ==========================================================
# メイン処理
# ==========================================================
do {
    Clear-Host
    Write-Host "========================================="
    Write-Host "   HarmoNet Git Utility v4.4 (Console)"
    Write-Host "========================================="
    for ($i=0; $i -lt $Repos.Count; $i++) {
        Write-Host ("{0}. {1}" -f ($i+1), $Repos[$i].Name)
    }
    Write-Host "0. 終了"
    Write-Host "-----------------------------------------"
    $repoIdxInput = Read-Host "番号を入力してください"
    if ($repoIdxInput -eq "0") { break }

    if (-not ($repoIdxInput -match '^[1-9][0-9]*$') -or
        [int]$repoIdxInput -lt 1 -or
        [int]$repoIdxInput -gt $Repos.Count) {
        Write-Host "❌ 無効な番号です。"; Pause-Menu; continue
    }

    $Repo = $Repos[[int]$repoIdxInput - 1]

    do {
        Clear-Host
        Write-Host "========================================="
        Write-Host "  HarmoNet Git Utility v4.5 (Console)"
        Write-Host "  現在のリポジトリ: $($Repo.Name)"
        Write-Host "  Path: $($Repo.Path)"
        Write-Host "========================================="
        Write-Host "1. ステータス確認 (git status / diff)"
        Write-Host "2. リモートの変更を取り込む (git pull origin main)"
        Write-Host "3. コミットしてPushする"
        Write-Host "4. 操作ログを開く"
        Write-Host "0. リポジトリ選択に戻る"
        Write-Host "-----------------------------------------"
        $m = Read-Host "番号を入力してください"

        switch ($m) {

            "1" {
                Section "git status"
                Exec-Git -Arguments @("status") -WorkDir $Repo.Path -Paged
                Write-Host ""
                $ans = Read-Host "差分（git diff）も表示しますか？ (Y/N)"
                if ($ans -match "^[Yy]$") {
                    Section "git diff"
                    Exec-Git -Arguments @("diff") -WorkDir $Repo.Path -Paged
                }
                Pause-Menu
            }

            "2" {
                $ok = Read-Host "リモートの変更を取り込みます。よろしいですか？ (Y/N)"
                if ($ok -match "^[Yy]$") {
                    Section "git pull origin main"
                    $success = Exec-Git -Arguments @("pull", "origin", "main") -WorkDir $Repo.Path
                    if ($success) {
                        Log-Action $Repo.Name "Pull" "リモート更新を取得"
                    } else {
                        Write-Host "⚠ Pull操作でエラーが発生しました。" -ForegroundColor Yellow
                    }
                }
                Pause-Menu
            }

            "3" {
                if (-not (Ensure-RepoPath $Repo.Path)) { Pause-Menu; break }

                Push-Location $Repo.Path
                try {
                    $changes = & git status --porcelain
                }
                finally {
                    Pop-Location
                }

                if (-not $changes -or $changes.Count -eq 0) {
                    Write-Host "⚠ 変更がありません。コミットをスキップします。"
                    Pause-Menu; break
                }

                Write-Host "変更があります。コミットを実行します。"
                Write-Host ""
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                Write-Host "📝 コミットメッセージ入力（複数行対応）"
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                Write-Host "入力方法:"
                Write-Host "  1行目: 概要（50文字以内推奨）"
                Write-Host "  2行目: 空行"
                Write-Host "  3行目以降: 詳細説明"
                Write-Host ""
                Write-Host "入力を終了するには空行で 'END' と入力してください"
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                Write-Host ""
                
                $lines = @()
                $lineNum = 1
                while ($true) {
                    $line = Read-Host "[$lineNum]"
                    if ($line -eq "END") { break }
                    $lines += $line
                    $lineNum++
                }
                
                $msg = $lines -join "`n"
                
                if ([string]::IsNullOrWhiteSpace($msg)) {
                    Write-Host "❌ メッセージ未入力のためキャンセルしました。"
                    Pause-Menu; break
                }
                
                Write-Host ""
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                Write-Host "📋 入力されたコミットメッセージ:"
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                Write-Host $msg
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                Write-Host ""
                $ok = Read-Host "Pushまで実行します。よろしいですか？ (Y/N)"
                if ($ok -notmatch "^[Yy]$") { Write-Host "キャンセルしました。"; Pause-Menu; break }

                Section "git add ."
                $success = Exec-Git -Arguments @("add", ".") -WorkDir $Repo.Path
                if (-not $success) {
                    Write-Host "❌ git add でエラーが発生しました。" -ForegroundColor Red
                    Pause-Menu; break
                }

                Section "git commit"
                $success = Exec-Git -Arguments @("commit", "-m", $msg) -WorkDir $Repo.Path
                if (-not $success) {
                    Write-Host "❌ git commit でエラーが発生しました。" -ForegroundColor Red
                    Pause-Menu; break
                }

                Section "git push origin main"
                $success = Exec-Git -Arguments @("push", "origin", "main") -WorkDir $Repo.Path
                if ($success) {
                    Write-Host "`n✅ コミットとPushが完了しました。"
                    Log-Action $Repo.Name "Commit/Push" $msg
                } else {
                    Write-Host "❌ git push でエラーが発生しました。" -ForegroundColor Red
                }
                Pause-Menu
            }

            "4" {
                if (-not (Test-Path $LogFile)) { New-Item -Path $LogFile -ItemType File | Out-Null }
                Start-Process notepad.exe $LogFile
            }

            "0" { break }

            default {
                Write-Host "❌ 無効な番号です。"; Pause-Menu
            }
        }
    } until ($m -eq "0")

} until ($repoIdxInput -eq "0")

Write-Host "`nHarmoNet Git Utility を終了しました。"
