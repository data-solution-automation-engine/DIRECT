<#
.SYNOPSIS
    DIRECT Framework console output utility functions.

.DESCRIPTION
    A collection of utility functions for formatted console output, including
    separator lines, headings, and color-coded message types (success, warning,
    info, result). These functions provide consistent visual formatting across
    DIRECT Framework scripts.

.NOTES
    File Name      : Write-Utils.ps1
    Prerequisite   : PowerShell 5.1 or later
    License        : LGPL-3.0 (GNU Lesser General Public License v3.0)

.LINK
    https://github.com/data-solution-automation-engine/DIRECT

.LINK
    https://github.com/data-solution-automation-engine/DIRECT/blob/main/COPYING.txt

.COMPONENT
    DIRECT Framework - Data Integration Runtime Execution Control Tools

.FUNCTIONALITY
    Console output formatting and visual presentation utilities.
#>

<#
.SYNOPSIS
    Writes a separator line to the host.

.DESCRIPTION
    Outputs a line of repeated separator characters in a specified color,
    useful for visual separation in script output.

.PARAMETER Separator
    The character to repeat. Default is '='.

.PARAMETER Length
    The number of times to repeat the separator. Default is 80.

.PARAMETER Color
    The color to use for the line. Default is 'Cyan'.

.EXAMPLE
    Write-SeparatorLine -Separator '-' -Length 60 -Color 'Yellow'
#>
function Write-SeparatorLine {
  param(
    [string]$Separator = "=",
    [int]$Length = 80,
    [string]$Color = "Cyan"
  )
  Write-Host ($Separator * $Length) -ForegroundColor $Color
}

<#
.SYNOPSIS
    Writes a formatted heading to the host.

.DESCRIPTION
    Outputs a heading surrounded by separator lines for emphasis, providing
    clear visual separation of sections in console output.

.PARAMETER Heading
    The heading text to display.

.PARAMETER Color
    The color to use for the heading and lines. Default is 'Magenta'.

.EXAMPLE
    Write-Heading -Heading "Deployment Started" -Color 'Magenta'
#>
function Write-Heading {
  param(
    [string]$Heading = "",
    [string]$Color = "Magenta"
  )
  Write-Host "`n"
  Write-SeparatorLine -Separator "=" -Length 80 -Color $Color
  Write-Host $Heading -ForegroundColor $Color
  Write-SeparatorLine -Separator "=" -Length 80 -Color $Color
  Write-Host ""
}

<#
.SYNOPSIS
    Writes a green success message to the host.

.DESCRIPTION
    Outputs a success message in green text, useful for indicating
    successful operations in script output.

.PARAMETER Message
    The message to display. Default is 'Success'.

.EXAMPLE
    Write-Success -Message "Deployment completed successfully."
#>
function Write-Success {
  param(
    [string]$Message = "Success"
  )
  Write-Host $Message -ForegroundColor Green
}

<#
.SYNOPSIS
    Writes a yellow warning message to the host.

.DESCRIPTION
    Outputs a warning message in yellow text, useful for indicating
    operations and states that need special attention.

.PARAMETER Message
    The message to display. Default is 'Warning'.

.EXAMPLE
    Write-Warn -Message "Container already exists, overwrite?"
#>
function Write-Warn {
  param(
    [string]$Message = "Warning"
  )
  Write-Host $Message -ForegroundColor Yellow
}

<#
.SYNOPSIS
    Writes an informational message to the host.

.DESCRIPTION
    Outputs an info message in blue text, useful for writing messages
    that don't require special attention or action.

.PARAMETER Message
    The message to display. Default is empty string.

.EXAMPLE
    Write-Info -Message "Looking for existing containers..."
#>
function Write-Info {
  param(
    [string]$Message = ""
  )
  Write-Host $Message -ForegroundColor Blue
}

<#
.SYNOPSIS
    Writes a result message to the host.

.DESCRIPTION
    Outputs a result message in cyan text, useful for indicating results
    or output from operations that need a consistent appearance.

.PARAMETER Message
    The message to display. Default is empty string.

.EXAMPLE
    Write-Result -Message "2319 rows affected."
#>
function Write-Result {
  param(
    [string]$Message = ""
  )
  Write-Host $Message -ForegroundColor Cyan
}

<#
.SYNOPSIS
    Writes a bold green success message to the output stream.

.DESCRIPTION
    Outputs a success message in bold green text using ANSI escape codes,
    useful for indicating successful operations. Writes to the output stream
    rather than directly to the console, making it suitable for scenarios
    that need to capture or redirect output.

.PARAMETER Message
    The message to display. Default is 'Success'.

.EXAMPLE
    Write-Output-Success -Message "Deployment completed successfully."
#>
function Write-Output-Success {
  param(
    [string]$Message = "Success"
  )
  # Green + bold ansi codes to output
  # Note: uses output and ansi to support bold
  Write-Output "`e[32m`e[1m$Message`e[0m"
}
