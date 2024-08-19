function Get-OSConfig {
    <#
    .SYNOPSIS
        Gets all options from the config file.

    .DESCRIPTION
        Internal function that returns contents of the config file. Preference order:
          1. .\PoSHOpenSearchConfig.json (Current directory)
          2. $env:USERPROFILE\Documents\PoSHOpenSearchConfig.json
          3. C:\ProgramData\PoSHOpenSearchConfig.json

    .PARAMETER ReturnOptions
        Specify an array of options to limit returned data.
    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    param(
        [Array]$ReturnOptions
    )

    # Retreive config file
    $ConfigFilePath = $null
    if (Test-Path -Path '.\PoSHOpenSearchConfig.json'){
        $ConfigFilePath = '.\PoSHOpenSearchConfig.json'
    }
    elseif (Test-Path -Path "$env:USERPROFILE\Documents\PoSHOpenSearchConfig.json"){
        $ConfigFilePath = "$env:USERPROFILE\Documents\PoSHOpenSearchConfig.json"
    }
    elseif (Test-Path -Path 'C:\ProgramData\PoSHOpenSearchConfig.json'){
        $ConfigFilePath = 'C:\ProgramData\PoSHOpenSearchConfig.json'
    }
    else {
        #throw [System.IO.FileNotFoundException] "Could not find a config file in any pre-defined directory. You can create a blank one with New-OSConfigFile and edit it's contents, or specify the required options when calling the function."
        return $null
    }

    $ConfigData = Get-Content -Path $ConfigFilePath | ConvertFrom-Json -Depth 100

    # Filter to specific options, if applicable
    if ($null -ne $ReturnOptions){
        $ConfigData = $ConfigData | Select-Object $ReturnOptions
    }
    else {
        $ConfigData = $ConfigData
    }

    return $ConfigData
}
