<#
.SYNOPSIS
    Converts pipeline objects to a Markdown-formatted table.

.DESCRIPTION
    This function takes objects from the pipeline and converts them into a Markdown table format.
    It supports automatic property detection or custom property selection, handles escaping of
    special characters, and formats datetime values consistently.

.PARAMETER InputObject
    The object(s) to convert to a Markdown table. Accepts pipeline input.

.PARAMETER Property
    Optional array of property names to include in the table. If not specified,
    all NoteProperty members from the first object are used.

.EXAMPLE
    Get-Process | Select-Object -First 5 Name, Id, CPU | ConvertTo-MarkdownTable

.EXAMPLE
    $results | ConvertTo-MarkdownTable -Property 'Name', 'Status', 'Duration'

.OUTPUTS
    System.String - A Markdown-formatted table string.

.NOTES
    File Name      : ConvertTo-MarkdownTable.ps1
    Prerequisite   : PowerShell 5.1 or later
    License        : LGPL-3.0 (GNU Lesser General Public License v3.0)

.LINK
    https://github.com/data-solution-automation-engine/DIRECT

.LINK
    https://github.com/data-solution-automation-engine/DIRECT/blob/main/COPYING.txt

.COMPONENT
    DIRECT Framework - Data Integration Runtime Execution Control Tools

.FUNCTIONALITY
    Utility function for generating Markdown output from PowerShell objects.
#>
function ConvertTo-MarkdownTable {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)] $InputObject,
    [string[]] $Property
  )
  begin { $rows = @() }
  process { $rows += $InputObject }
  end {
    if (-not $rows) { return "_No data._" }

    if (-not $Property -or $Property.Count -eq 0) {
      $first = $rows | Select-Object -First 1
      $Property = ($first | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name)
    }

    $escape = {
      param([string]$s)
      if ($null -eq $s) { return '' }
      ($s -replace '\|','\|') -replace '\r?\n','<br/>'
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    # TODO: Parameterize heading and maybe add some more options/meta like datetime or ingress?
    $lines.Add("# Test Results")
    $lines.Add("")

    $lines.Add("| " + ($Property -join " | ") + " |")
    # Separator row: pad dashes to the length of each header (min 3 for Markdown)
    $sepCells = foreach ($h in $Property) {
      $len = [math]::Max(3, ([string]$h).Length)
      '-' * $len
    }
    $lines.Add("| " + ($sepCells -join " | ") + " |")

    foreach ($r in $rows) {
      $vals = foreach ($p in $Property) {
        $v = $r.$p
        if ($v -is [datetime]) { $v = $v.ToString('yyyy-MM-dd HH:mm:ss') }
        & $escape ([string]$v)
      }
      $lines.Add("| " + ($vals -join " | ") + " |")
    }

    $lines -join [Environment]::NewLine
  }
}
