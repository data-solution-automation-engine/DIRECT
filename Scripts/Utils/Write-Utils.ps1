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
  Writes a bold green success message to the host.
.DESCRIPTION
  Outputs a success message in bold green text,
  useful for indicating successful operations.
.PARAMETER Message
  The message to display (default: "Success").
.EXAMPLE
  Write-Success -Message "Deployment completed successfully."
.NOTES
  Uses ANSI escape codes for formatting. Write-Host and -ForegroundColor
  doesn't do bold prints at the moment
#>
function Write-Success {
  param(
    [string]$Message = "Success"
  )
  # Green + bold ansi codes to output
  # Note: uses output and ansi to support bold
  Write-Output "`e[32m`e[1m$Message`e[0m"
}
