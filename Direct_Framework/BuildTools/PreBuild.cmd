@ECHO OFF

REM A pre-build utility script. This cmd is called from the build process.
REM Perform any required cmd-type tasks here,
REM Add any pwsh-type tasks in the called PreBuild script.

ECHO *** CMD - Pre-Build Event: Starting

REM Run the pre-build PowerShell script
pwsh -ExecutionPolicy Bypass -NoProfile -NonInteractive -File %~dp0\PreBuild.ps1 -path %~dp0

ECHO *** CMD - Pre-Build Event: Completed
