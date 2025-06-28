@ECHO OFF

REM Debug cmd for post-build event
ECHO *** CMD - Pre-Build Event: Building 'Direct_Framework' project...

REM Run the pre-build PowerShell script
pwsh -ExecutionPolicy Bypass -NoProfile -NonInteractive -File %~dp0\PreBuild.ps1 -path %~dp0
