@ECHO OFF

rem Debug cmd for post-build event
ECHO *** CMD - Pre-Build Event: Building 'Direct_Framework' project...

REM ECHO current directory: %CD%
REM ECHO script directory: %~dp0

rem Run the pre-build PowerShell script
pwsh -ExecutionPolicy Bypass -NoProfile -NonInteractive -File %~dp0\PreBuild.ps1 -path %~dp0
