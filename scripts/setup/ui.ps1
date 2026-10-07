# Terminal UI for setup.ps1 (TASK-021): RGB gradient, logo, step headers, spinner and
# gradient progress bar in the style of busy.js. Only draws; every state shown comes
# from setup.ps1 (real check / install results).

$script:ESC = [char]27
$script:RESET = "$ESC[0m"
$script:DIM = "$ESC[2m"
$script:BOLD = "$ESC[1m"
$script:GREEN = "$ESC[32m"
$script:YELLOW = "$ESC[33m"
$script:RED = "$ESC[31m"
$script:CYAN = "$ESC[36m"
$script:CL = "`r$ESC[2K"

# Windows Terminal (and other modern terminals) render braille; the legacy console does not.
$script:Fancy = [bool]($env:WT_SESSION -or $env:TERM_PROGRAM)
$script:SPIN = if ($Fancy) { [char[]]'⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' } else { [char[]]'|/-\' }
$script:PART = @('', '▏', '▎', '▍', '▌', '▋', '▊', '▉')
$script:MARK_OK = "$GREEN✔$RESET"
$script:MARK_FAIL = "$RED✖$RESET"
$script:MARK_SKIP = "$DIM─$RESET"

$script:PAL_LOGO = @(@(0, 255, 200), @(0, 120, 255), @(170, 0, 255))
$script:PAL_HEAD = @(@(0, 255, 200), @(0, 120, 255), @(170, 0, 255))
# Bars use the logo's hues too: neighbouring hues stay clear when mixed (a warm -> cool
# rainbow turns muddy olive in the middle) and running / finished bars look the same.
$script:PAL_BAR = $PAL_LOGO
$script:PAL_FAIL = @(@(255, 80, 80), @(255, 160, 60))

function Write-Ui([string]$s) { [Console]::Out.Write($s) }

# The legacy console only interprets ANSI sequences with this mode on (Windows Terminal always does).
function Enable-VirtualTerminal {
  if (-not ('SinbinNative.Console' -as [type])) {
    Add-Type -Namespace SinbinNative -Name Console -MemberDefinition @'
[DllImport("kernel32.dll")] public static extern IntPtr GetStdHandle(int n);
[DllImport("kernel32.dll")] public static extern bool GetConsoleMode(IntPtr h, out uint m);
[DllImport("kernel32.dll")] public static extern bool SetConsoleMode(IntPtr h, uint m);
'@
  }
  $h = [SinbinNative.Console]::GetStdHandle(-11)
  $mode = [uint32]0
  if ([SinbinNative.Console]::GetConsoleMode($h, [ref]$mode)) {
    [void][SinbinNative.Console]::SetConsoleMode($h, $mode -bor 0x4)
  }
}

function Rgb($c) { "$ESC[38;2;$($c[0]);$($c[1]);$($c[2])m" }

function Get-GradAt($stops, [double]$t) {
  # Double literals: with an int first argument PowerShell picks Min(int, int) and rounds $t.
  $t = [Math]::Max(0.0, [Math]::Min(1.0, $t))
  $s = $t * ($stops.Count - 1)
  $i = [Math]::Min([Math]::Floor($s), $stops.Count - 2)
  $f = $s - $i
  $a = $stops[$i]; $b = $stops[$i + 1]
  , @(0..2 | ForEach-Object { [int][Math]::Round($a[$_] + ($b[$_] - $a[$_]) * $f) })
}

function Format-Grad([string]$str, $stops) {
  $n = [Math]::Max(1, $str.Length - 1)
  $sb = New-Object Text.StringBuilder
  for ($i = 0; $i -lt $str.Length; $i++) {
    [void]$sb.Append((Rgb (Get-GradAt $stops ($i / $n)))).Append($str[$i])
  }
  $sb.ToString() + $RESET
}

# Gradient bar like busy.js gbar(): full blocks, one partial block, dim dots.
function Format-Bar([double]$pct, [int]$width, $stops = $PAL_BAR) {
  $total = ($pct / 100) * $width
  $full = [Math]::Floor($total)
  $rem = [int][Math]::Floor(($total - $full) * 8)
  $sb = New-Object Text.StringBuilder
  for ($i = 0; $i -lt $width; $i++) {
    $col = Rgb (Get-GradAt $stops ($i / [Math]::Max(1, $width - 1)))
    if ($i -lt $full) { [void]$sb.Append($col).Append('█') }
    elseif ($i -eq $full -and $rem -gt 0) { [void]$sb.Append($col).Append($PART[$rem]) }
    else { [void]$sb.Append($RESET).Append($DIM).Append('·') }
  }
  $sb.ToString() + $RESET
}

function Get-UiWidth {
  # No console window when the output is redirected.
  $w = try { [Console]::WindowWidth } catch { 100 }
  if ($w -le 0) { $w = 100 }
  [Math]::Min([Math]::Max($w, 60), 120)
}
function Get-BarWidth { if ((Get-UiWidth) -ge 100) { 32 } else { 22 } }

# Display width: ANSI codes take none, Hangul / CJK / fullwidth take two columns.
function Get-VisWidth([string]$s) {
  $plain = $s -replace "$ESC\[[0-9;?]*[A-Za-z]", ''
  $w = 0
  foreach ($ch in $plain.ToCharArray()) {
    $c = [int]$ch
    if (($c -ge 0x1100 -and $c -le 0x115F) -or ($c -ge 0x2E80 -and $c -le 0xA4CF) -or
        ($c -ge 0xAC00 -and $c -le 0xD7A3) -or ($c -ge 0xF900 -and $c -le 0xFAFF) -or
        ($c -ge 0xFE30 -and $c -le 0xFE4F) -or ($c -ge 0xFF00 -and $c -le 0xFF60) -or
        ($c -ge 0xFFE0 -and $c -le 0xFFE6)) { $w += 2 } else { $w += 1 }
  }
  $w
}

# Cut plain text (no ANSI) to a display width.
function Limit-Text([string]$s, [int]$width) {
  if ($width -le 1) { return '' }
  if ((Get-VisWidth $s) -le $width) { return $s }
  $sb = New-Object Text.StringBuilder
  $w = 0
  foreach ($ch in $s.ToCharArray()) {
    $cw = Get-VisWidth ([string]$ch)
    if ($w + $cw -gt $width - 1) { break }
    [void]$sb.Append($ch); $w += $cw
  }
  $sb.ToString() + '…'
}

function Format-Duration([double]$sec) {
  if ($sec -lt 60) { return ('{0:0.0}s' -f $sec) }
  '{0}m {1}s' -f [Math]::Floor($sec / 60), [Math]::Floor($sec % 60)
}

$script:GLYPHS = @{
  'S' = @('███████╗', '██╔════╝', '███████╗', '╚════██║', '███████║', '╚══════╝')
  'I' = @('██╗', '██║', '██║', '██║', '██║', '╚═╝')
  'N' = @('███╗   ██╗', '████╗  ██║', '██╔██╗ ██║', '██║╚██╗██║', '██║ ╚████║', '╚═╝  ╚═══╝')
  'B' = @('██████╗ ', '██╔══██╗', '██████╔╝', '██╔══██╗', '██████╔╝', '╚═════╝ ')
  'D' = @('██████╗ ', '██╔══██╗', '██║  ██║', '██║  ██║', '██████╔╝', '╚═════╝ ')
  'E' = @('███████╗', '██╔════╝', '█████╗  ', '██╔══╝  ', '███████╗', '╚══════╝')
  'T' = @('████████╗', '╚══██╔══╝', '   ██║   ', '   ██║   ', '   ██║   ', '   ╚═╝   ')
  'U' = @('██╗   ██╗', '██║   ██║', '██║   ██║', '██║   ██║', '╚██████╔╝', ' ╚═════╝ ')
  'P' = @('██████╗ ', '██╔══██╗', '██████╔╝', '██╔═══╝ ', '██║     ', '╚═╝     ')
  ' ' = @('  ', '  ', '  ', '  ', '  ', '  ')
}

function Format-Logo([string]$word) {
  0..5 | ForEach-Object {
    $r = $_
    -join ($word.ToCharArray() | ForEach-Object { $GLYPHS[[string]$_][$r] })
  }
}

function Show-Banner([string]$subtitle) {
  Write-Ui "`n"
  # Side by side when it fits (98 columns), else stacked.
  $a = Format-Logo 'SINBIN'
  $b = Format-Logo 'IDE SETUP'
  if ((Get-UiWidth) -ge ($a[0].Length + $b[0].Length + 6)) {
    $rows = 0..5 | ForEach-Object { $a[$_] + '  ' + $b[$_] }
  } else {
    $rows = $a + @('') + $b
  }
  foreach ($row in $rows) { Write-Ui ('  ' + (Format-Grad $row $PAL_LOGO) + "`n") }
  Write-Ui "`n  $DIM$subtitle$RESET`n"
}

function Show-Header([string]$title, [int]$no, [int]$total) {
  $label = " $title "
  $tag = " $no/$total "
  $rest = [Math]::Max(4, (Get-UiWidth) - 4 - $label.Length - $tag.Length - 1)
  Write-Ui ("`n" + (Format-Grad '━━━━' $PAL_HEAD) + $BOLD + $label + $RESET + (Format-Grad ('━' * $rest) $PAL_HEAD) + $DIM + $tag + $RESET + "`n")
}

# One item row: mark, name column, version column, note (plain text, cut to the width).
function Format-Row([string]$mark, [string]$name, [string]$version, [string]$note, [string]$color = $DIM) {
  $width = Get-UiWidth
  $head = "  $mark {0,-20} {1,-14} " -f $name, $version
  $room = $width - (Get-VisWidth $head) - 1
  $head + $color + (Limit-Text $note $room) + $RESET
}

function Format-Spin([int]$frame) { "$CYAN$($SPIN[$frame % $SPIN.Count])$RESET" }
