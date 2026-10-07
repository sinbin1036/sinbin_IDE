# Process runner for setup.ps1 (TASK-021). The child's stdout / stderr lines and its exit
# arrive on .NET threads; they are queued and signal an AutoResetEvent, which wakes the
# PowerShell loop right away. The loop only times out to turn the spinner.

if (-not ('SinbinProc' -as [type])) {
  Add-Type -TypeDefinition @'
using System;
using System.Collections;
using System.Collections.Concurrent;
using System.Diagnostics;
using System.Text;
using System.Threading;

public class SinbinLine {
    public bool IsError;
    public string Text;
}

public class SinbinProc {
    private readonly Process proc;
    private readonly ConcurrentQueue<SinbinLine> lines = new ConcurrentQueue<SinbinLine>();
    private readonly AutoResetEvent signal = new AutoResetEvent(false);
    private int openStreams = 2;
    private volatile bool exited;
    private DateTime exitedAt;
    public int ExitCode;

    public SinbinProc(string file, string args, string workDir, IDictionary env) {
        var psi = new ProcessStartInfo(file, args);
        if (!String.IsNullOrEmpty(workDir)) psi.WorkingDirectory = workDir;
        psi.UseShellExecute = false;
        psi.CreateNoWindow = true;
        psi.RedirectStandardOutput = true;
        psi.RedirectStandardError = true;
        psi.StandardOutputEncoding = Encoding.UTF8;
        psi.StandardErrorEncoding = Encoding.UTF8;
        if (env != null) {
            foreach (DictionaryEntry e in env) psi.EnvironmentVariables[(string)e.Key] = (string)e.Value;
        }
        proc = new Process();
        proc.StartInfo = psi;
        proc.EnableRaisingEvents = true;
        proc.Exited += (s, e) => {
            ExitCode = proc.ExitCode;
            exitedAt = DateTime.UtcNow;
            exited = true;
            signal.Set();
        };
        proc.OutputDataReceived += (s, e) => OnData(e.Data, false);
        proc.ErrorDataReceived += (s, e) => OnData(e.Data, true);
        proc.Start();
        proc.BeginOutputReadLine();
        proc.BeginErrorReadLine();
    }

    private void OnData(string data, bool isError) {
        if (data == null) {
            Interlocked.Decrement(ref openStreams);
        } else {
            var line = new SinbinLine();
            line.IsError = isError;
            line.Text = data;
            lines.Enqueue(line);
        }
        signal.Set();
    }

    // Exited, and its output read to the end. A grandchild that inherited the pipes (an
    // installer started by winget) can keep them open: then stop reading shortly after.
    public bool Done {
        get {
            return exited && (openStreams <= 0 || (DateTime.UtcNow - exitedAt).TotalMilliseconds > 1000);
        }
    }

    // Blocks until a line / the exit arrives, or the timeout (for the spinner).
    public bool Wait(int ms) { return signal.WaitOne(ms); }

    public SinbinLine Next() {
        SinbinLine line;
        return lines.TryDequeue(out line) ? line : null;
    }

    public void Kill() {
        try { if (!proc.HasExited) proc.Kill(); } catch { }
    }
}
'@
}

function Join-ProcArgs([string[]]$list) {
  ($list | ForEach-Object {
    if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ }
  }) -join ' '
}

# Runs a program. $OnLine gets each SinbinLine as it arrives, $OnTick runs when the wait
# times out (spinner frame). Every line also goes to the log file.
# Returns @{ ExitCode; Tail (last lines) }.
function Invoke-Tracked {
  param(
    [Parameter(Mandatory)] [string]$File,
    [string[]]$ArgumentList = @(),
    [hashtable]$Environment,
    [string]$WorkDir = $env:TEMP,
    [scriptblock]$OnLine,
    [scriptblock]$OnTick,
    [string]$LogName = $File
  )
  Write-SetupLog "[$LogName] > $File $(Join-ProcArgs $ArgumentList)"
  $proc = New-Object SinbinProc($File, (Join-ProcArgs $ArgumentList), $WorkDir, $Environment)
  $tail = New-Object Collections.Generic.List[string]
  $tick = [Diagnostics.Stopwatch]::StartNew()
  try {
    while ($true) {
      [void]$proc.Wait(100)
      $line = $proc.Next()
      while ($null -ne $line) {
        Write-SetupLog "[$LogName] $($line.Text)"
        if ($line.Text.Trim()) {
          $tail.Add($line.Text)
          if ($tail.Count -gt 12) { $tail.RemoveAt(0) }
        }
        if ($OnLine) { & $OnLine $line }
        $line = $proc.Next()
      }
      if ($proc.Done) { break }
      if ($OnTick -and $tick.ElapsedMilliseconds -ge 100) { & $OnTick; $tick.Restart() }
    }
  } finally {
    $proc.Kill()
  }
  Write-SetupLog "[$LogName] exit $($proc.ExitCode)"
  @{ ExitCode = $proc.ExitCode; Tail = $tail.ToArray() }
}
