@echo off
rem Interstate '76 Gold - enable force feedback (FOR THE WINDOWS BOX).
rem
rem The Gold Edition ships with FFB code (Nitro Pack) but looks for its settings under
rem the key name "Interstate '76"; the installer writes "Interstate'76FRC" instead, so
rem FFB stays dormant. Copying the key under the expected name switches it on
rem (PCGamingWiki: "Enabling force feedback on the Gold Edition"). We COPY rather than
rem rename so it's trivially reversible (delete the new key to revert).
rem
rem RUN AS ADMINISTRATOR (HKLM). Works on 64-bit Windows (WOW6432Node) and 32-bit.
rem NOTE: no effect on the Mac port - Wine has no macOS force-feedback backend
rem (see docs/FORCE-FEEDBACK-AND-VISUALS.md).

reg copy "HKLM\SOFTWARE\WOW6432Node\ACTIVISION\Interstate'76FRC" "HKLM\SOFTWARE\WOW6432Node\ACTIVISION\Interstate '76" /s /f 2>nul && (
    echo Force feedback enabled ^(WOW6432Node^). Plug in the wheel and launch the game.
    goto :done
)
reg copy "HKLM\SOFTWARE\ACTIVISION\Interstate'76FRC" "HKLM\SOFTWARE\ACTIVISION\Interstate '76" /s /f && (
    echo Force feedback enabled. Plug in the wheel and launch the game.
) || (
    echo FAILED - is the game installed, and is this window running as Administrator?
)
:done
pause
