# Interstate '76 / Nitro Pack smart launcher (Windows + dgVoodoo recipe).
#
# The engine creates a fullscreen-size borderless popup and hit-tests menu
# clicks at raw window pixels as internal 640x480 coordinates - so any menu
# scale desyncs the mouse from the click targets, and dgVoodoo stretches the
# 2D shell to fill the popup. Fix: this launcher watches the game window and
# snaps the popup to a centered 640x480 whenever it is screen-size, giving
# pixel-perfect menus and mouse. The 3D sim is unaffected: dgVoodoo's [Glide]
# Resolution=3x resizes the window to 1920x1440 while driving.
#
# Fullscreen play: launch, then Ctrl+Alt+S (Lossless Scaling) - aspect-correct
# borderless fullscreen + LSFG frame generation on top of the physics-safe 20fps.
#
# Usage: PLAY-i76.ps1 [-GameDir "C:\Games\Interstate 76"] [-Exe i76.exe]
param(
    [string]$GameDir = "C:\Games\Interstate 76",
    [string]$Exe = "i76.exe"
)
$ErrorActionPreference = 'SilentlyContinue'

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class I76Win {
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr a, int x, int y, int w, int hh, uint f);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R r);
    public struct R { public int L, T, Rt, B; }
}
"@
Add-Type -AssemblyName System.Windows.Forms

$name = [IO.Path]::GetFileNameWithoutExtension($Exe)
$proc = Start-Process -FilePath (Join-Path $GameDir $Exe) -ArgumentList '-glide' -WorkingDirectory $GameDir -PassThru

$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$cx = $screen.X + [int](($screen.Width - 640) / 2)
$cy = $screen.Y + [int](($screen.Height - 480) / 2)

# Watchdog: whenever the game window is screen-size (the boot popup / stretched
# 2D shell state), snap it to centered 640x480. The 1920x1440 sim window is
# left alone. Exits with the game.
while (-not $proc.HasExited) {
    Start-Sleep -Milliseconds 700
    $p = Get-Process $name -ErrorAction SilentlyContinue
    if (-not $p -or $p.MainWindowHandle -eq [IntPtr]::Zero) { continue }
    $r = New-Object I76Win+R
    [I76Win]::GetWindowRect($p.MainWindowHandle, [ref]$r) | Out-Null
    $w = $r.Rt - $r.L; $h = $r.B - $r.T
    if ($w -ge $screen.Width -and $h -ge $screen.Height) {
        # SWP_NOZORDER(4) | SWP_NOACTIVATE(0x10)
        [I76Win]::SetWindowPos($p.MainWindowHandle, [IntPtr]::Zero, $cx, $cy, 640, 480, 0x14) | Out-Null
    }
}
