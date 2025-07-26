<#
.SYNOPSIS
  Writes a separator line to the host.
.DESCRIPTION
  Outputs a line of repeated separator characters in a specified color, useful for visual separation in script output.
.PARAMETER Separator
  The character to repeat (default: '=').
.PARAMETER Length
  The number of times to repeat the separator (default: 80).
.PARAMETER Color
  The color to use for the line (default: 'Cyan').
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
  Outputs a heading surrounded by separator lines for emphasis.
.PARAMETER Heading
  The heading text to display.
.PARAMETER Color
  The color to use for the heading and lines (default: 'Cyan').
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
  Outputs a success message in green text,
  useful for indicating successful operations.
.PARAMETER Message
  The message to display (default: "Success").
.EXAMPLE
  Write-Success -Message "Deployment completed successfully."
.NOTES
  Uses plain Write-Host and -ForegroundColor,
  suited for more scenarios than the ansi bold one.
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
  Outputs a warning message in yellow text,
  useful for indicating operations and states that need special attention.
.PARAMETER Message
  The message to display (default: "Warning").
.EXAMPLE
  Write-Warning -Message "Container already exists, overwrite?"
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
  Outputs an info message in blue text,
  useful for writing messages that don't need special attention.
.PARAMETER Message
  The message to display (default: "").
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
  Outputs a result message in cyan text,
  useful for indicating result or output from operations and states
  that need a common appearance.
.PARAMETER Message
  The message to display (default: "").
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
  Outputs a success message in bold green text,
  useful for indicating successful operations.
.PARAMETER Message
  The message to display (default: "Success").
.EXAMPLE
  Write-Success -Message "Deployment completed successfully."
.NOTES
  Uses ANSI escape codes for formatting. Write-Host and -ForegroundColor
  doesn't do bold prints at the moment.
  Write-Output writes to the output stream, not directly to the console.
  This is useful for scenarios that need to capture output or redirect it,
  or when there is no piping or redirection at all.
#>
function Write-Output-Success {
  param(
    [string]$Message = "Success"
  )
  # Green + bold ansi codes to output
  # Note: uses output and ansi to support bold
  Write-Output "`e[32m`e[1m$Message`e[0m"
}
