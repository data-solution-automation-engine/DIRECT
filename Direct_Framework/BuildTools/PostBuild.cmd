@ECHO OFF

rem Debug cmd for post-build event
ECHO *** CMD - Post-Build Event: Building 'Direct_Framework' project...

rem Run the post-build PowerShell script
pwsh -ExecutionPolicy Bypass -NoProfile -NonInteractive -file "%~dp0\PostBuild.ps1" -WorkingDirectory "%~dp0"
