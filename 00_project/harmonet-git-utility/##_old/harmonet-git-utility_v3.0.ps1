# ==========================================================
# HarmoNet Git Utility v3.0 (GUI)
# Author : Tachikoma
# Purpose: Visual Git launcher for HarmoNet Phase9
# Windows PowerShell / .NET WinForms
# ==========================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ▼ リポジトリ設定（必要に応じて編集可）
$Repos = @(
    @{ Name = "設計書リポジトリ (01_docs)"; Path = "D:\AIDriven\01_docs"; Remote = "https://github.com/komogomo/01_docs.git" },
    @{ Name = "開発資材リポジトリ (Projects-HarmoNet)"; Path = "D:\Projects\HarmoNet"; Remote = "https://github.com/komogomo/Projects-HarmoNet.git" }
)

# ▼ ログファイル（スクリプトと同じ場所）
$LogFile = Join-Path $PSScriptRoot "harmonet_git_log.txt"

# =============== 共通ユーティリティ ===============
function Write-Log {
    param($repoName, $action, $message)
    $entry = "{0} : [{1}] {2} - {3}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $repoName, $action, $message
    Add-Content -Path $LogFile -Value $entry
}

function Append-Output {
    param($text)
    $OutputBox.AppendText($text + [Environment]::NewLine)
    $OutputBox.ScrollToCaret()
}

function Run-Git {
    param(
        [string]$Arguments,
        [string]$WorkDir,
        [switch]$ReturnText # 戻り値として標準出力を返す（画面にも表示）
    )
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $p.StartInfo.FileName = "git"
    $p.StartInfo.Arguments = $Arguments
    $p.StartInfo.WorkingDirectory = $WorkDir
    $p.StartInfo.RedirectStandardOutput = $true
    $p.StartInfo.RedirectStandardError  = $true
    $p.StartInfo.UseShellExecute = $false
    $p.StartInfo.CreateNoWindow = $true
    $null = $p.Start()

    $stdOut = New-Object System.Text.StringBuilder
    $stdErr = New-Object System.Text.StringBuilder

    while (-not $p.HasExited) {
        $o = $p.StandardOutput.ReadToEnd()
        $e = $p.StandardError.ReadToEnd()
        if ($o) { $stdOut.Append($o) | Out-Null; Append-Output $o.TrimEnd() }
        if ($e) { $stdErr.Append($e) | Out-Null; Append-Output $e.TrimEnd() }
        Start-Sleep -Milliseconds 100
    }
    # 残りを読み切る
    $o2 = $p.StandardOutput.ReadToEnd()
    $e2 = $p.StandardError.ReadToEnd()
    if ($o2) { $stdOut.Append($o2) | Out-Null; Append-Output $o2.TrimEnd() }
    if ($e2) { $stdErr.Append($e2) | Out-Null; Append-Output $e2.TrimEnd() }

    if ($ReturnText) { return $stdOut.ToString() + $stdErr.ToString() }
}

# =============== フォーム構築 ===============
$Form               = New-Object System.Windows.Forms.Form
$Form.Text          = "HarmoNet Git Utility v3.0"
$Form.Width         = 980
$Form.Height        = 640
$Form.StartPosition = "CenterScreen"
$Form.BackColor     = [System.Drawing.ColorTranslator]::FromHtml("#FAFAFA")
$Form.Font          = New-Object System.Drawing.Font("Segoe UI", 10)

# タイトル
$Title = New-Object System.Windows.Forms.Label
$Title.Text = "HarmoNet Git Utility"
$Title.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$Title.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#333333")
$Title.AutoSize = $true
$Title.Location = New-Object System.Drawing.Point(20, 15)
$Form.Controls.Add($Title)

# リポ選択
$RepoLabel = New-Object System.Windows.Forms.Label
$RepoLabel.Text = "現在のリポジトリ:"
$RepoLabel.AutoSize = $true
$RepoLabel.Location = New-Object System.Drawing.Point(22, 60)
$Form.Controls.Add($RepoLabel)

$RepoSelect = New-Object System.Windows.Forms.ComboBox
$RepoSelect.DropDownStyle = 'DropDownList'
$RepoSelect.Width = 520
$RepoSelect.Location = New-Object System.Drawing.Point(140, 56)
foreach ($r in $Repos) { [void]$RepoSelect.Items.Add($r.Name) }
$RepoSelect.SelectedIndex = 0
$Form.Controls.Add($RepoSelect)

# ボタン群
$btnStatus = New-Object System.Windows.Forms.Button
$btnStatus.Text = "ステータス確認"
$btnStatus.Location = New-Object System.Drawing.Point(22, 100)
$btnStatus.Width = 140

$btnPull = New-Object System.Windows.Forms.Button
$btnPull.Text = "リモート取得 (pull)"
$btnPull.Location = New-Object System.Drawing.Point(172, 100)
$btnPull.Width = 160

$btnCommitPush = New-Object System.Windows.Forms.Button
$btnCommitPush.Text = "コミット + Push"
$btnCommitPush.Location = New-Object System.Drawing.Point(342, 100)
$btnCommitPush.Width = 160

$btnOpenLog = New-Object System.Windows.Forms.Button
$btnOpenLog.Text = "操作ログを開く"
$btnOpenLog.Location = New-Object System.Drawing.Point(512, 100)
$btnOpenLog.Width = 140

$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Text = "終了"
$btnExit.Location = New-Object System.Drawing.Point(662, 100)
$btnExit.Width = 100

$Form.Controls.AddRange(@($btnStatus, $btnPull, $btnCommitPush, $btnOpenLog, $btnExit))

# 出力ボックス
$OutputBox = New-Object System.Windows.Forms.TextBox
$OutputBox.Multiline = $true
$OutputBox.ScrollBars = 'Vertical'
$OutputBox.ReadOnly = $true
$OutputBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$OutputBox.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
$OutputBox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#333333")
$OutputBox.Location = New-Object System.Drawing.Point(22, 140)
$OutputBox.Width = 920
$OutputBox.Height = 420
$Form.Controls.Add($OutputBox)

# ステータスバー風ラベル
$StatusBar = New-Object System.Windows.Forms.Label
$StatusBar.Text = "Ready"
$StatusBar.AutoSize = $false
$StatusBar.Height = 24
$StatusBar.Width = 920
$StatusBar.Location = New-Object System.Drawing.Point(22, 570)
$StatusBar.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#F0F0F0")
$StatusBar.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#333333")
$StatusBar.Padding = New-Object System.Windows.Forms.Padding(8,4,0,0)
$Form.Controls.Add($StatusBar)

function Get-SelectedRepo {
    $idx = $RepoSelect.SelectedIndex
    return $Repos[$idx]
}

# =============== ボタンイベント ===============
$btnStatus.Add_Click({
    $repo = Get-SelectedRepo
    $OutputBox.Clear()
    $StatusBar.Text = "git status 実行中..."
    Append-Output ("===== " + $repo.Name + " =====")
    Append-Output ("Path: " + $repo.Path)
    Append-Output "----- git status -----"
    Run-Git -Arguments "status" -WorkDir $repo.Path | Out-Null

    # 差分確認
    $dialog = [System.Windows.Forms.MessageBox]::Show("差分（git diff）を表示しますか？","確認",[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question)
    if ($dialog -eq [System.Windows.Forms.DialogResult]::Yes) {
        Append-Output "----- git diff -----"
        Run-Git -Arguments "diff" -WorkDir $repo.Path | Out-Null
    }
    $StatusBar.Text = "Ready"
})

$btnPull.Add_Click({
    $repo = Get-SelectedRepo
    $OutputBox.Clear()
    Append-Output ("===== " + $repo.Name + " =====")
    Append-Output ("Path: " + $repo.Path)
    $dialog = [System.Windows.Forms.MessageBox]::Show("リモートの変更を取り込みますか？(git pull origin main)","確認",[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question)
    if ($dialog -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    $StatusBar.Text = "git pull 実行中..."
    Append-Output "----- git pull origin main -----"
    Run-Git -Arguments "pull origin main" -WorkDir $repo.Path | Out-Null
    Write-Log $repo.Name "Pull" "リモート更新を取得"
    $StatusBar.Text = "Ready"
})

$btnCommitPush.Add_Click({
    $repo = Get-SelectedRepo
    $OutputBox.Clear()
    Append-Output ("===== " + $repo.Name + " =====")
    Append-Output ("Path: " + $repo.Path)

    # 変更確認
    $StatusBar.Text = "変更確認中..."
    $changes = Run-Git -Arguments "status --porcelain" -WorkDir $repo.Path -ReturnText
    if ([string]::IsNullOrWhiteSpace($changes)) {
        Append-Output "⚠ 変更がありません。コミットをスキップします。"
        $StatusBar.Text = "Ready"
        return
    }

    # メッセージ入力
    $commitMsg = ""
    $promptForm = New-Object System.Windows.Forms.Form
    $promptForm.Text = "コミットメッセージ"
    $promptForm.Width = 620; $promptForm.Height = 180
    $promptForm.StartPosition = "CenterParent"
    $promptForm.Font = $Form.Font

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "コミットメッセージを入力してください："
    $lbl.AutoSize = $true
    $lbl.Location = New-Object System.Drawing.Point(12, 12)
    $tb = New-Object System.Windows.Forms.TextBox
    $tb.Width = 560
    $tb.Location = New-Object System.Drawing.Point(16, 40)
    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = "OK"; $ok.Location = New-Object System.Drawing.Point(496, 80)
    $ok.Add_Click({ $script:commitMsg = $tb.Text; $promptForm.Close() })
    $promptForm.Controls.AddRange(@($lbl,$tb,$ok))
    $promptForm.ShowDialog() | Out-Null

    if ([string]::IsNullOrWhiteSpace($commitMsg)) {
        [System.Windows.Forms.MessageBox]::Show("メッセージが未入力のためキャンセルしました。","情報",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        $StatusBar.Text = "Ready"
        return
    }

    # 実行確認
    $dialog = [System.Windows.Forms.MessageBox]::Show("以下の内容でコミット + Push を実行しますか？`n`nリポジトリ: $($repo.Name)`nメッセージ: $commitMsg","確認",[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question)
    if ($dialog -ne [System.Windows.Forms.DialogResult]::Yes) { $StatusBar.Text = "Ready"; return }

    # 実行
    $StatusBar.Text = "git add / commit / push 実行中..."
    Append-Output "----- git add . -----"
    Run-Git -Arguments "add ." -WorkDir $repo.Path | Out-Null

    Append-Output "----- git commit -----"
    Run-Git -Arguments ("commit -m " + ('"{0}"' -f $commitMsg.Replace('"','\"'))) -WorkDir $repo.Path | Out-Null

    Append-Output "----- git push origin main -----"
    Run-Git -Arguments "push origin main" -WorkDir $repo.Path | Out-Null

    Append-Output "✅ コミットとPushが完了しました。"
    Write-Log $repo.Name "Commit/Push" $commitMsg
    $StatusBar.Text = "Ready"
})

$btnOpenLog.Add_Click({
    if (-not (Test-Path $LogFile)) { New-Item -Path $LogFile -ItemType File | Out-Null }
    Start-Process notepad.exe $LogFile | Out-Null
})

$btnExit.Add_Click({ $Form.Close() })

# 初期案内
$OutputBox.Text = @"
HarmoNet Git Utility v3.0 (GUI)
- トップのコンボボックスでリポジトリを選択
- 各ボタンで操作（ステータス／Pull／コミット+Push／ログ）
- 実行結果はこのウィンドウにリアルタイム表示
- すべての操作は $LogFile にも記録
"@

[void]$Form.ShowDialog()
