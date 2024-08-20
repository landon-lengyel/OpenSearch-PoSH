[CmdletBinding()]
Param (

)

# Dot source nested script files
# Public functions
Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 | ForEach-Object {
    . $_.FullName
}

# Private (internal) functions
Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 | ForEach-Object {
    . $_.FullName
}

