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
