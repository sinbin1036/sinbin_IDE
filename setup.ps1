<#
.SYNOPSIS
  sinbin_IDE Windows setup (TASK-021): tools, config link, Neovim plugins,
  Treesitter parsers and LSP / debug packages. Installed items are only checked.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\setup.ps1
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\setup.ps1 -With python,node
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\setup.ps1 -CheckOnly
#>
[CmdletBinding()]
param(
  # Language runtimes to install when missing (never installed otherwise).
  [ValidateSet('python', 'node', 'java')]
  [string[]]$With = @(),
  # Only check and report, install nothing.
  [switch]$CheckOnly,
  # Do not ask which runtimes to install.
  [switch]$NoPrompt
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
. (Join-Path $Root 'scripts\setup\ui.ps1')
. (Join-Path $Root 'scripts\setup\proc.ps1')

[Console]::OutputEncoding = [Text.Encoding]::UTF8
$OutputEncoding = [Text.Encoding]::UTF8
Enable-VirtualTerminal

$script:Clock = [Diagnostics.Stopwatch]::StartNew()
$script:LogPath = Join-Path $env:TEMP ('sinbin-setup-{0:yyyyMMdd-HHmmss}.log' -f (Get-Date))
$script:Log = New-Object IO.StreamWriter($LogPath, $false, (New-Object Text.UTF8Encoding($false)))
$script:Log.AutoFlush = $true
function Write-SetupLog([string]$s) { $script:Log.WriteLine($s) }

$script:Results = New-Object Collections.Generic.List[object]
$script:SectionNo = 0
$SECTION_COUNT = 8
$script:Section = ''

function Add-Result([string]$name, [string]$status, [string]$version = '', [string]$stage = '', [string[]]$detail = @()) {
  $script:Results.Add([pscustomobject]@{
      Section = $script:Section; Name = $name; Status = $status
      Version = $version; Stage = $stage; Detail = $detail
    })
  Write-SetupLog "[result] $($script:Section) / $name : $status $version $stage"
}

function Start-Section([string]$title) {
  $script:SectionNo++
  $script:Section = $title
  Show-Header $title $script:SectionNo $SECTION_COUNT
  Write-SetupLog "== $title"
}

# ───────────────────────── 확인 ─────────────────────────

# PATH as stored in the registry, so tools installed a moment ago are found.
function Update-Path {
  $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
  $user = [Environment]::GetEnvironmentVariable('Path', 'User')
  $env:Path = "$machine;$user"
}

function Find-Exe([string[]]$names) {
  foreach ($n in $names) {
    $cmd = Get-Command $n -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    # The Microsoft Store python.exe stub only opens the Store.
    if ($cmd -and -not ($cmd.Source -like '*\WindowsApps\python*')) { return $cmd.Source }
  }
  $null
}

function Get-ToolVersion([string]$exe, [string[]]$arguments, [string]$regex) {
  $ErrorActionPreference = 'Continue'
  try { $out = & $exe @arguments 2>&1 | Out-String } catch { return $null }
  if ($out -match $regex) { $Matches[1] } else { $null }
}

# @{ Path; Version } of a tool, or $null.
function Test-Tool($tool) {
  if ($tool.Check) { return & $tool.Check }
  $exe = Find-Exe $tool.Cmd
  if (-not $exe) { return $null }
  $v = Get-ToolVersion $exe $tool.Args $tool.Regex
  @{ Path = $exe; Version = $(if ($v) { $v } else { '?' }) }
}

function Test-NerdFont {
  $keys = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts', 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
  foreach ($k in $keys) {
    $props = Get-ItemProperty -Path $k -ErrorAction SilentlyContinue
    if ($props -and ($props.PSObject.Properties.Name -match 'JetBrainsMono.*(Nerd|NF)')) {
      return @{ Path = $k; Version = 'JetBrainsMono NF' }
    }
  }
  $null
}

$CoreTools = @(
  @{ Name = 'Git'; Cmd = @('git'); Args = @('--version'); Regex = 'version (\d+\.\d+\.\d+)'; Id = 'Git.Git'; Key = 'git' }
  @{ Name = 'Neovim'; Cmd = @('nvim'); Args = @('--version'); Regex = 'NVIM v(\d+\.\d+\.\d+)'; Id = 'Neovim.Neovim'; Key = 'nvim'; Min = '0.12.0' }
  @{ Name = 'ripgrep'; Cmd = @('rg'); Args = @('--version'); Regex = 'ripgrep (\d+\.\d+\.\d+)'; Id = 'BurntSushi.ripgrep.MSVC'; Key = 'rg' }
  @{ Name = 'fd'; Cmd = @('fd'); Args = @('--version'); Regex = 'fd (\d+\.\d+\.\d+)'; Id = 'sharkdp.fd'; Key = 'fd' }
)

$HelperTools = @(
  @{ Name = 'tree-sitter CLI'; Cmd = @('tree-sitter'); Args = @('--version'); Regex = 'tree-sitter (\d+\.\d+\.\d+)'; Id = 'tree-sitter.tree-sitter-cli'; Key = 'treesitter' }
  @{ Name = 'C compiler'; Cmd = @('gcc', 'clang'); Args = @('--version'); Regex = '(\d+\.\d+\.\d+)'; Id = 'BrechtSanders.WinLibs.POSIX.UCRT'; Key = 'cc' }
  @{ Name = 'lazygit'; Cmd = @('lazygit'); Args = @('--version'); Regex = 'version=(\d+\.\d+\.\d+)'; Id = 'JesseDuffield.lazygit'; Key = 'lazygit' }
  @{ Name = 'Nerd Font'; Check = { Test-NerdFont }; Id = 'DEVCOM.JetBrainsMonoNerdFont'; Key = 'font' }
)

$Runtimes = @(
  @{ Name = 'Python'; Cmd = @('python', 'python3'); Args = @('--version'); Regex = 'Python (\d+\.\d+\.\d+)'; Id = 'Python.Python.3.13'; Key = 'python' }
  @{ Name = 'Node.js'; Cmd = @('node'); Args = @('--version'); Regex = 'v(\d+\.\d+\.\d+)'; Id = 'OpenJS.NodeJS.LTS'; Key = 'node' }
  @{ Name = 'Java (JDK)'; Cmd = @('java'); Args = @('-version'); Regex = 'version "([^"]+)"'; Id = 'EclipseAdoptium.Temurin.21.JDK'; Key = 'java' }
  @{ Name = 'Flutter / Dart'; Cmd = @('dart'); Args = @('--version'); Regex = 'version: (\d+\.\d+\.\d+)'; Key = 'dart'; Guide = 'https://docs.flutter.dev/get-started/install/windows' }
)

# Mason packages (PROJECT Phase 13) and the runtime each one needs.
$MasonPackages = @(
  @{ Name = 'clangd'; Needs = $null }
  @{ Name = 'vtsls'; Needs = 'node' }
  @{ Name = 'js-debug-adapter'; Needs = 'node' }
  @{ Name = 'basedpyright'; Needs = 'python' }
  @{ Name = 'ruff'; Needs = 'python' }
  @{ Name = 'debugpy'; Needs = 'python' }
  @{ Name = 'jdtls'; Needs = 'java' }
  @{ Name = 'java-debug-adapter'; Needs = 'java' }
)
$RuntimeNames = @{ python = 'Python'; node = 'Node.js'; java = 'Java' }

# What later steps depend on: key -> path / $true.
$script:Have = @{}

# ───────────────────────── 설치 ─────────────────────────

function Write-ItemFail([string]$name, [string]$stage, [string[]]$tail) {
  Write-Ui ($CL + (Format-Row $MARK_FAIL $name 'failed' $stage $RED) + "`n")
  $room = (Get-UiWidth) - 8
  foreach ($l in ($tail | Select-Object -Last 3)) {
    Write-Ui ("      $DIM│ " + (Limit-Text $l.Trim() $room) + "$RESET`n")
  }
}

# winget install / upgrade with a live row: spinner, elapsed time and winget's real last
# output line (winget prints no percentage when its output is redirected).
function Invoke-Winget($tool, [string]$verb) {
  $winget = Find-Exe @('winget')
  if (-not $winget) {
    return @{ Ok = $false; Stage = 'winget 없음 (Microsoft Store에서 App Installer 설치)'; Tail = @() }
  }
  $st = @{ Frame = 0; Detail = "winget $verb $($tool.Id)"; T0 = [Diagnostics.Stopwatch]::StartNew(); Name = $tool.Name }
  $draw = {
    $elapsed = Format-Duration $st.T0.Elapsed.TotalSeconds
    Write-Ui ($CL + (Format-Row (Format-Spin $st.Frame) $st.Name $elapsed $st.Detail))
  }
  & $draw
  $r = Invoke-Tracked -File $winget -LogName $tool.Name -ArgumentList @(
    $verb, '--id', $tool.Id, '--exact', '--silent',
    '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity'
  ) -OnLine {
    param($line)
    $t = $line.Text.Trim()
    if ($t -and $t -notmatch '^[-\\|/ ]+$') { $st.Detail = $t }
    & $draw
  } -OnTick { $st.Frame++; & $draw }
  if ($r.ExitCode -ne 0) {
    return @{ Ok = $false; Stage = ('winget {0} 실패 (exit 0x{1:X8})' -f $verb, $r.ExitCode); Tail = $r.Tail; Seconds = $st.T0.Elapsed.TotalSeconds }
  }
  @{ Ok = $true; Tail = $r.Tail; Seconds = $st.T0.Elapsed.TotalSeconds }
}

# Check a tool; install it with winget when missing (or older than Min).
function Install-Tool($tool, [switch]$Optional) {
  $found = Test-Tool $tool
  $old = $found -and $tool.Min -and $found.Version -ne '?' -and ([version]$found.Version -lt [version]$tool.Min)
  if ($found -and -not $old) {
    Write-Ui ((Format-Row $MARK_OK $tool.Name $found.Version '이미 설치됨') + "`n")
    Add-Result $tool.Name 'present' $found.Version
    $script:Have[$tool.Key] = $found.Path
    return
  }
  $why = if ($old) { "$($found.Version) → $($tool.Min) 이상 필요" } else { '없음' }
  if ($CheckOnly) {
    Write-Ui ((Format-Row "$YELLOW!$RESET" $tool.Name '' "$why (설치 안 함: -CheckOnly)" $YELLOW) + "`n")
    Add-Result $tool.Name 'missing' '' $why
    return
  }
  $verb = if ($old) { 'upgrade' } else { 'install' }
  $r = Invoke-Winget $tool $verb
  if (-not $r.Ok) {
    Write-ItemFail $tool.Name $r.Stage $r.Tail
    Add-Result $tool.Name 'failed' '' $r.Stage $r.Tail
    return
  }
  Update-Path
  $found = Test-Tool $tool
  if (-not $found) {
    $stage = '설치 후 확인 실패 (PATH에서 찾을 수 없음, 새 터미널에서 다시 실행)'
    Write-ItemFail $tool.Name $stage $r.Tail
    Add-Result $tool.Name 'failed' '' $stage $r.Tail
    return
  }
  Write-Ui ($CL + (Format-Row $MARK_OK $tool.Name $found.Version ('설치됨 ({0})' -f (Format-Duration $r.Seconds)) $GREEN) + "`n")
  Add-Result $tool.Name 'installed' $found.Version
  $script:Have[$tool.Key] = $found.Path
}

function Install-Runtimes {
  $missing = @()
  foreach ($rt in $Runtimes) {
    $found = Test-Tool $rt
    if ($found) {
      Write-Ui ((Format-Row $MARK_OK $rt.Name $found.Version '있음') + "`n")
      Add-Result $rt.Name 'present' $found.Version
      $script:Have[$rt.Key] = $found.Path
    } elseif ($rt.Id) {
      $missing += $rt
    } else {
      Write-Ui ((Format-Row $MARK_SKIP $rt.Name '' "없음 · 필요하면 수동 설치: $($rt.Guide)") + "`n")
      Add-Result $rt.Name 'skipped' '' '없음 (수동 설치)'
    }
  }
  if (-not $missing) { return }

  $chosen = @($With)
  $interactive = [Environment]::UserInteractive -and -not [Console]::IsInputRedirected
  if (-not $With -and -not $NoPrompt -and -not $CheckOnly -and $interactive) {
    Write-Ui "`n  ${BOLD}설치할 Runtime$RESET $DIM(필요한 것만 · LSP / 디버거가 이 Runtime을 씀)$RESET`n"
    for ($i = 0; $i -lt $missing.Count; $i++) {
      Write-Ui ("    $CYAN{0})$RESET {1}`n" -f ($i + 1), $missing[$i].Name)
    }
    Write-Ui "$ESC[?25h"
    $answer = Read-Host '  번호 (예: 1,3 · Enter = 설치 안 함)'
    Write-Ui "$ESC[?25l"
    $chosen = @($answer -split '[,\s]+' | Where-Object { $_ -match '^\d+$' } |
        ForEach-Object { [int]$_ - 1 } | Where-Object { $_ -ge 0 -and $_ -lt $missing.Count } |
        ForEach-Object { $missing[$_].Key })
  }
  foreach ($rt in $missing) {
    if ($chosen -contains $rt.Key) {
      Install-Tool $rt
    } else {
      Write-Ui ((Format-Row $MARK_SKIP $rt.Name '' "없음 · 건너뜀 (설치: -With $($rt.Key))") + "`n")
      Add-Result $rt.Name 'skipped' '' '없음 (선택 안 함)'
    }
  }
}

function Install-ConfigLink {
  $link = Join-Path $env:LOCALAPPDATA 'nvim'
  $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd('\')
  $item = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
  if ($item -and $item.LinkType) {
    $dest = [IO.Path]::GetFullPath(@($item.Target)[0]).TrimEnd('\')
    if ($dest -ieq $rootFull) {
      Write-Ui ((Format-Row $MARK_OK 'config link' $item.LinkType "$link → 이 저장소") + "`n")
      Add-Result 'config link' 'present' $item.LinkType
      $script:Have['link'] = $true
      return
    }
  }
  if ($CheckOnly) {
    $why = if ($item) { "$link 가 다른 곳을 가리킴" } else { "$link 없음" }
    Write-Ui ((Format-Row "$YELLOW!$RESET" 'config link' '' "$why (설치 안 함: -CheckOnly)" $YELLOW) + "`n")
    Add-Result 'config link' 'missing' '' $why
    return
  }
  try {
    $note = ''
    if ($item) {
      $backup = 'nvim.backup-{0:yyyyMMdd-HHmmss}' -f (Get-Date)
      Rename-Item -LiteralPath $link -NewName $backup
      $note = " (기존 → $backup)"
    }
    New-Item -ItemType Junction -Path $link -Target $Root | Out-Null
    Write-Ui ((Format-Row $MARK_OK 'config link' 'Junction' "$link → 이 저장소$note" $GREEN) + "`n")
    Add-Result 'config link' 'installed' 'Junction'
    $script:Have['link'] = $true
  } catch {
    Write-ItemFail 'config link' 'Junction 생성 실패' @($_.Exception.Message)
    Add-Result 'config link' 'failed' '' 'Junction 생성 실패' @($_.Exception.Message)
  }
}

# ───────────────────────── Neovim 단계 ─────────────────────────

function Invoke-NvimStep([string]$step, [hashtable]$extraEnv, [scriptblock]$OnEvent, [scriptblock]$OnOther, [scriptblock]$OnTick) {
  $helper = (Join-Path $Root 'scripts\setup\nvim_setup.lua') -replace '\\', '/' -replace ' ', '\ '
  $envs = @{ SINBIN_SETUP = '1'; SINBIN_SETUP_STEP = $step }
  if ($extraEnv) { foreach ($k in $extraEnv.Keys) { $envs[$k] = $extraEnv[$k] } }
  Invoke-Tracked -File $script:Have['nvim'] -LogName "nvim:$step" -Environment $envs -ArgumentList @(
    '--headless', '-c', "luafile $helper", '-c', 'qa!'
  ) -OnLine {
    param($line)
    if ($line.Text -match '^@@sinbin\|([^|]*)\|([^|]*)\|?(.*)$') {
      & $OnEvent $Matches[1] $Matches[2] $Matches[3]
    } elseif ($OnOther) {
      & $OnOther $line
    }
  } -OnTick $OnTick
}

function Get-Missing([string[]]$keys) {
  @($keys | Where-Object { -not $script:Have[$_] })
}

function Write-StepSkip([string]$name, [string]$why) {
  Write-Ui ((Format-Row $MARK_SKIP $name '' "건너뜀 · $why" $YELLOW) + "`n")
  Add-Result $name 'skipped' '' $why
}

# vim.pack installs missing plugins while the config loads and reports
# "vim.pack:  14% Installing plugins (3/21) - name" on stderr: a real progress bar.
function Install-Plugins {
  $st = @{ Frame = 0; Done = 0; Total = 0; Current = '설정 로드 중'; New = @{}; Items = @(); Fails = @() }
  $draw = {
    $pct = if ($st.Total) { 100 * $st.Done / $st.Total } else { 0 }
    $count = if ($st.Total) { "$($st.Done)/$($st.Total)" } else { '' }
    $line = "  $(Format-Spin $st.Frame) {0,-20} $(Format-Bar $pct (Get-BarWidth)) {1,-7} " -f 'vim.pack', $count
    Write-Ui ($CL + $line + $DIM + (Limit-Text $st.Current ((Get-UiWidth) - (Get-VisWidth $line) - 1)) + $RESET)
  }
  & $draw
  $r = Invoke-NvimStep 'plugins' $null -OnEvent {
    param($event, $name, $info)
    switch ($event) {
      'present' { $st.Items += , @($name, $info) }
      'fail' { $st.Fails += , @($name, $info) }
    }
  } -OnOther {
    param($line)
    if ($line.Text -match 'vim\.pack:\s+\d+%.*\((\d+)/(\d+)\)(?:\s+-\s+(.+))?') {
      $st.Done = [int]$Matches[1]; $st.Total = [int]$Matches[2]
      if ($Matches[3]) { $st.Current = $Matches[3].Trim(); $st.New[$st.Current] = $true }
    } elseif ($line.Text.Trim()) {
      $st.Current = $line.Text.Trim()
    }
    & $draw
  } -OnTick { $st.Frame++; & $draw }

  foreach ($it in $st.Items) {
    $status = if ($st.New.ContainsKey($it[0])) { 'installed' } else { 'present' }
    Add-Result $it[0] $status $it[1]
  }
  foreach ($f in $st.Fails) { Add-Result $f[0] 'failed' '' "vim.pack 설치 실패: $($f[1])" $r.Tail }
  $newCount = @($st.Items | Where-Object { $st.New.ContainsKey($_[0]) }).Count
  if ($st.Fails.Count -or -not $st.Items.Count) {
    $stage = if ($st.Items.Count) { "$($st.Fails.Count)개 실패: " + (($st.Fails | ForEach-Object { $_[0] }) -join ', ') } else { 'Neovim 실행 / 설정 로드 실패' }
    if (-not $st.Items.Count -and -not $st.Fails.Count) { Add-Result 'vim.pack' 'failed' '' $stage $r.Tail }
    Write-ItemFail 'vim.pack' $stage $r.Tail
    return
  }
  $note = if ($newCount) { "새로 $newCount · 기존 $($st.Items.Count - $newCount)" } else { '모두 설치되어 있음' }
  $line = "  $MARK_OK {0,-20} $(Format-Bar 100 (Get-BarWidth) $PAL_BAR) {1,-7} " -f 'vim.pack', "$($st.Items.Count)/$($st.Items.Count)"
  Write-Ui ($CL + $line + $GREEN + $note + $RESET + "`n")
  $script:Have['plugins'] = $true
}

# Parallel installs (parsers, Mason) as one row per item under a live count bar,
# redrawn in place like busy.js multiDownload. Rows come from the helper's events.
function Install-Group([string]$title, [string]$step, [hashtable]$extraEnv, $preRows) {
  $g = @{ Frame = 0; Rows = New-Object Collections.ArrayList; Index = @{}; Drawn = 0; T0 = [Diagnostics.Stopwatch]::StartNew() }
  foreach ($p in $preRows) { $g.Index[$p.Name] = $g.Rows.Add(@{ Name = $p.Name; State = 'skip'; Info = $p.Info }) }
  $draw = {
    $finished = @($g.Rows | Where-Object { $_.State -ne 'run' -and $_.State -ne 'skip' }).Count
    $total = @($g.Rows | Where-Object { $_.State -ne 'skip' }).Count
    $running = @($g.Rows | Where-Object { $_.State -eq 'run' }).Count
    $pct = if ($total) { 100 * $finished / $total } else { 100 }
    $out = New-Object Text.StringBuilder
    if ($g.Drawn) { [void]$out.Append("$ESC[$($g.Drawn)F") }
    $failed = @($g.Rows | Where-Object { $_.State -eq 'fail' }).Count
    $mark = if ($running) { Format-Spin $g.Frame } elseif ($failed) { $MARK_FAIL } else { $MARK_OK }
    $head = "$ESC[2K  $mark {0,-20} $(Format-Bar $pct (Get-BarWidth)) $finished/$total $DIM{1}$RESET`n" -f $title, (Format-Duration $g.T0.Elapsed.TotalSeconds)
    [void]$out.Append($head)
    foreach ($row in $g.Rows) {
      $line = switch ($row.State) {
        'present' { Format-Row "  $MARK_OK" $row.Name $row.Info '이미 설치됨' }
        'done' { Format-Row "  $MARK_OK" $row.Name $row.Info '설치됨' $GREEN }
        'fail' { Format-Row "  $MARK_FAIL" $row.Name 'failed' $row.Info $RED }
        'skip' { Format-Row "  $MARK_SKIP" $row.Name '' $row.Info $YELLOW }
        default { Format-Row "  $(Format-Spin ($g.Frame + $row.Name.Length))" $row.Name '' '설치 중' $CYAN }
      }
      [void]$out.Append("$ESC[2K$line`n")
    }
    $g.Drawn = 1 + $g.Rows.Count
    Write-Ui $out.ToString()
  }
  & $draw
  $r = Invoke-NvimStep $step $extraEnv -OnEvent {
    param($event, $name, $info)
    if ($event -eq 'total') { return }
    if (-not $g.Index.ContainsKey($name)) { $g.Index[$name] = $g.Rows.Add(@{ Name = $name; State = 'run'; Info = '' }) }
    $row = $g.Rows[$g.Index[$name]]
    switch ($event) {
      'present' { $row.State = 'present'; $row.Info = $info }
      'start' { $row.State = 'run' }
      'done' { $row.State = 'done'; $row.Info = $info }
      'fail' { $row.State = 'fail'; $row.Info = $info }
    }
    & $draw
  } -OnTick { $g.Frame++; & $draw }
  # Rows still running when Neovim exited did not finish.
  foreach ($row in $g.Rows) { if ($row.State -eq 'run') { $row.State = 'fail'; $row.Info = 'Neovim 종료 (완료 안 됨)' } }
  & $draw
  foreach ($row in $g.Rows) {
    switch ($row.State) {
      'present' { Add-Result $row.Name 'present' $row.Info }
      'done' { Add-Result $row.Name 'installed' $row.Info }
      'skip' { Add-Result $row.Name 'skipped' '' $row.Info }
      'fail' {
        $mine = @($r.Tail | Where-Object { $_ -match [regex]::Escape($row.Name) })
        $tail = if ($mine) { $mine } else { $r.Tail }
        Add-Result $row.Name 'failed' '' "$title › $($row.Info)" $tail
      }
    }
  }
  if (-not $g.Rows.Count) {
    Write-ItemFail $title 'Neovim helper 출력 없음' $r.Tail
    Add-Result $title 'failed' '' 'Neovim helper 출력 없음' $r.Tail
  }
}

# ───────────────────────── 요약 ─────────────────────────

function Show-Summary {
  $by = @{}
  foreach ($s in 'installed', 'present', 'skipped', 'failed', 'missing') { $by[$s] = @($script:Results | Where-Object { $_.Status -eq $s }) }
  $fails = $by['failed']
  $total = $script:Results.Count
  $ok = $by['installed'].Count + $by['present'].Count
  $secs = $script:Clock.Elapsed.TotalSeconds

  Write-Ui "`n"
  $title = if ($CheckOnly) { 'SINBIN IDE CHECK' } elseif ($fails.Count) { 'SINBIN IDE SETUP INCOMPLETE' } else { 'SINBIN IDE READY' }
  $pal = if ($fails.Count) { $PAL_FAIL } else { $PAL_BAR }
  $bar = Format-Bar (100 * $ok / [Math]::Max(1, $total)) ((Get-BarWidth) + 6) $pal
  Write-Ui ("  " + (Format-Grad "■ $title" $pal) + "`n")
  Write-Ui ("  $bar $ok/$total`n")
  Write-Ui ("  {0}새로 설치 {1}{2}  ·  이미 있음 {3}  ·  건너뜀 {4}  ·  {5}실패 {6}{2}{7}  ·  총 소요 {8}`n" -f `
      $GREEN, $by['installed'].Count, $RESET, $by['present'].Count, $by['skipped'].Count,
    $(if ($fails.Count) { $RED } else { '' }), $fails.Count,
    $(if ($by['missing'].Count) { "  ·  ${YELLOW}없음 $($by['missing'].Count)$RESET" } else { '' }),
    (Format-Duration $secs))

  if ($fails.Count) {
    Write-Ui "`n  ${RED}실패 항목$RESET`n"
    foreach ($f in $fails) {
      Write-Ui ("  $MARK_FAIL " + (Limit-Text "$($f.Section) › $($f.Name) › $($f.Stage)" ((Get-UiWidth) - 6)) + "`n")
    }
    Write-Ui "`n  ${DIM}전체 로그: $LogPath$RESET`n"
    Write-Ui "  ${DIM}고친 뒤 다시 실행하면 설치된 항목은 건너뛰고 나머지만 진행합니다.$RESET`n"
  } elseif (-not $CheckOnly) {
    Write-Ui "`n  ${DIM}새 터미널에서$RESET ${BOLD}nvim$RESET ${DIM}실행 · 로그: $LogPath$RESET`n"
  }
  if ($by['missing'].Count) {
    Write-Ui "`n  ${DIM}설치: powershell -ExecutionPolicy Bypass -File .\setup.ps1$RESET`n"
  }
  Write-Ui "`n"
  $fails.Count
}

# ───────────────────────── 실행 ─────────────────────────

# Dot-sourced (tests): functions only.
if ($MyInvocation.InvocationName -eq '.') { return }

$failCount = 0
try {
  Write-Ui "$ESC[?25l"
  $psv = $PSVersionTable.PSVersion
  Show-Banner ("Windows bootstrap · PowerShell {0}.{1} · {2}" -f $psv.Major, $psv.Minor, $Root)

  Start-Section 'Preflight'
  Update-Path
  $os = [Environment]::OSVersion.Version
  Write-Ui ((Format-Row $MARK_OK 'Windows' "$($os.Major).$($os.Minor).$($os.Build)" '') + "`n")
  if (-not (Test-Path (Join-Path $Root 'init.lua'))) {
    throw "init.lua 없음: setup.ps1을 sinbin_IDE 저장소 루트에서 실행하세요 ($Root)"
  }
  Write-Ui ((Format-Row $MARK_OK 'repository' '' $Root) + "`n")
  $winget = Find-Exe @('winget')
  if ($winget) {
    Write-Ui ((Format-Row $MARK_OK 'winget' (Get-ToolVersion $winget @('--version') 'v?(\d+\.\d+\.\d+)') '설치 도구') + "`n")
  } else {
    Write-Ui ((Format-Row "$YELLOW!$RESET" 'winget' '' '없음 · 설치가 필요한 항목은 실패로 표시 (Microsoft Store: App Installer)' $YELLOW) + "`n")
  }
  if ($CheckOnly) { Write-Ui "  ${DIM}-CheckOnly: 확인만 하고 설치하지 않음$RESET`n" }

  Start-Section 'Core tools'
  foreach ($t in $CoreTools) { Install-Tool $t }

  Start-Section 'Build & helper tools'
  foreach ($t in $HelperTools) { Install-Tool $t }

  Start-Section 'Language runtimes'
  Install-Runtimes

  Start-Section 'Config link'
  Install-ConfigLink

  $nvimReady = $script:Have['nvim'] -and $script:Have['link'] -and $script:Have['git']
  $nvimWhy = (@(
      $(if (-not $script:Have['nvim']) { 'Neovim 없음' }),
      $(if (-not $script:Have['git']) { 'Git 없음' }),
      $(if (-not $script:Have['link']) { 'config link 없음' })
    ) | Where-Object { $_ }) -join ', '

  Start-Section 'Neovim plugins'
  if ($CheckOnly) { Write-StepSkip 'vim.pack' '-CheckOnly' }
  elseif (-not $nvimReady) { Write-StepSkip 'vim.pack' $nvimWhy }
  else { Install-Plugins }

  Start-Section 'Treesitter parsers'
  $tsWhy = (@(
      $(if (-not $script:Have['plugins']) { 'Plugin 없음' }),
      $(if (-not $script:Have['treesitter']) { 'tree-sitter CLI 없음' }),
      $(if (-not $script:Have['cc']) { 'C compiler 없음' })
    ) | Where-Object { $_ }) -join ', '
  if ($CheckOnly) { Write-StepSkip 'parsers' '-CheckOnly' }
  elseif ($tsWhy) { Write-StepSkip 'parsers' $tsWhy }
  else { Install-Group 'parsers' 'parsers' $null @() }

  Start-Section 'LSP / Debug (Mason)'
  if ($CheckOnly) { Write-StepSkip 'Mason' '-CheckOnly' }
  elseif (-not $script:Have['plugins']) { Write-StepSkip 'Mason' 'Plugin 없음' }
  else {
    $wanted = @($MasonPackages | Where-Object { -not $_.Needs -or $script:Have[$_.Needs] } | ForEach-Object { $_.Name })
    $pre = @($MasonPackages | Where-Object { $_.Needs -and -not $script:Have[$_.Needs] } |
        ForEach-Object { @{ Name = $_.Name; Info = "$($RuntimeNames[$_.Needs]) 없음 (-With $($_.Needs))" } })
    Install-Group 'Mason' 'mason' @{ SINBIN_SETUP_MASON = ($wanted -join ',') } $pre
  }

  $failCount = Show-Summary
} catch {
  Write-Ui "`n  $MARK_FAIL $RED$($_.Exception.Message)$RESET`n"
  Write-SetupLog "[fatal] $($_ | Out-String)"
  Write-Ui "  ${DIM}로그: $LogPath$RESET`n`n"
  $failCount = 1
} finally {
  Write-Ui "$ESC[?25h$RESET"
  $script:Log.Dispose()
}
exit $(if ($failCount) { 1 } else { 0 })
