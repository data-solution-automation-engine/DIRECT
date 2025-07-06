@ECHO OFF

REM A post-build utility script. This cmd is called from the build process.
REM Perform any required cmd-type tasks here,
REM Add any pwsh-type tasks in the called PostBuild script.

ECHO *** CMD - Post-Build Event: Starting

REM Run the post-build PowerShell script
pwsh -ExecutionPolicy Bypass -NoProfile -NonInteractive -file "%~dp0\PostBuild.ps1" -WorkingDirectory "%~dp0"

ECHO *** CMD - Post-Build Event: Completed
