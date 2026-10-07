// Korean IME helper for sinbin.ime on Windows (TASK-017), built on first use by
// sinbin/platform/windows_ime.lua with the .NET Framework csc.exe.
//
//   ime-helper.exe get <process>...          prints "ko" / "en" for the foreground window
//   ime-helper.exe to-english <process>...   Korean -> English, English: nothing
//
// Acts only when the foreground window belongs to one of <process> (the terminal
// Neovim runs in), so another application's IME is never touched. Keeps the Microsoft
// Korean IME and only clears its Hangul (native) conversion mode bit, the state the
// Han/Eng key toggles; it does not switch the keyboard layout.
// Exit codes: 0 done, 2 no IME window, 3 foreground window is not a listed process.

using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

static class ImeHelper
{
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    [DllImport("imm32.dll")] static extern IntPtr ImmGetDefaultIMEWnd(IntPtr hWnd);
    [DllImport("user32.dll")] static extern IntPtr SendMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);

    const uint WM_IME_CONTROL = 0x0283;
    const int IMC_GETCONVERSIONMODE = 0x0001;
    const int IMC_SETCONVERSIONMODE = 0x0002;
    const int IME_CMODE_NATIVE = 0x0001; // Hangul input

    static int Main(string[] args)
    {
        if (args.Length < 1) return 1;
        IntPtr hwnd = GetForegroundWindow();
        uint pid;
        GetWindowThreadProcessId(hwnd, out pid);
        string name;
        try { name = Process.GetProcessById((int)pid).ProcessName; } catch { return 3; }
        bool allowed = false;
        for (int i = 1; i < args.Length; i++)
            if (string.Equals(args[i], name, StringComparison.OrdinalIgnoreCase)) allowed = true;
        if (!allowed) return 3;

        IntPtr ime = ImmGetDefaultIMEWnd(hwnd);
        if (ime == IntPtr.Zero) return 2;
        int mode = (int)SendMessage(ime, WM_IME_CONTROL, (IntPtr)IMC_GETCONVERSIONMODE, IntPtr.Zero);
        bool korean = (mode & IME_CMODE_NATIVE) != 0;

        if (args[0] == "get")
        {
            Console.Write(korean ? "ko" : "en");
            return 0;
        }
        if (args[0] == "to-english" && korean)
            SendMessage(ime, WM_IME_CONTROL, (IntPtr)IMC_SETCONVERSIONMODE, (IntPtr)(mode & ~IME_CMODE_NATIVE));
        return 0;
    }
}
