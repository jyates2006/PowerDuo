$Public  = Get-ChildItem $PSScriptRoot\Public\*.ps1 -Recurse -ErrorAction SilentlyContinue
$Private = Get-ChildItem $PSScriptRoot\Private\*.ps1 -Recurse -ErrorAction SilentlyContinue

Foreach($Import in @($Public + $Private)) {. $Import.fullname }