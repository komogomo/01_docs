# ==========================================================
# HarmoNet Git Utility v4.3 (Console / Stable)
# Author : Tachikoma
# Purpose: Safe Git operations with menu UI for HarmoNet Phase9
# Changelog v4.3:
#   - Fixed: Character encoding for batch file execution (UTF-8 support)
#   - Inherits all v4.2 improvements
# ==========================================================

# UTF-8 encoding setup for proper Japanese display
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Set Git to use UTF-8 for Japanese characters
$env:LESSCHARSET = "utf-8"

$Repos = @(
    @{ Name = "設計書リポジトリ (01_docs)"; Path = "D:\AIDriven\01_docs"; Remote = "https://github.com/komogomo/01_docs.git" },
    @{ Name = "開発資材リポジトリ (Projects-HarmoNet)"; Path = "D:\Projects\HarmoNet"; Remote = "https://github.com/komogomo/Projects-HarmoNet.git" }
)

$ScriptPath = $MyInvocation.MyCommand.Path
$ScriptDir  = Split-Path -Parent $ScriptPath
$LogFile    = Join-Path $ScriptDir "harmonet_git_log.txt"

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
    Write-Host "   HarmoNet Git Utility v4.3 (Console)"
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
        Write-Host "  HarmoNet Git Utility v4.3 (Console)"
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
                $msg = Read-Host "コミットメッセージを入力してください"
                if ([string]::IsNullOrWhiteSpace($msg)) {
                    Write-Host "❌ メッセージ未入力のためキャンセルしました。"
                    Pause-Menu; break
                }
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
