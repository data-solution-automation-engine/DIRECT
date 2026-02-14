@ECHO OFF

REM A post-build utility script. This cmd is called from the build process.
REM Perform any required cmd-type tasks here,
REM Add any pwsh-type tasks in the called PostBuild script.

REM Accept build configuration as first argument
SET CONFIGURATION=%1
IF "%CONFIGURATION%"=="" SET CONFIGURATION=Debug

ECHO *** CMD - Post-Build Event: Starting

REM Run the post-build PowerShell script in the correct directory, send the configuration as parameter
pwsh -ExecutionPolicy Bypass -NoProfile -NonInteractive -file "%~dp0\PostBuild.ps1" -WorkingDirectory "%~dp0" -Configuration "%CONFIGURATION%"

ECHO *** CMD - Post-Build Event: Completed
