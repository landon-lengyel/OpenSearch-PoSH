function Confirm-OSFieldNamingStandard {
    <#
    .SYNOPSIS
        Helper function to verify that field names match the approved naming standard.

    .DESCRIPTION
        Keeping field names consistant accross indices can be very important for searchability, and ease of use.
        This function will verify that the field names are pre-approved. See the documentation for the full approved list.
        Returns if the names are all approved. Throws a [System.ArgumentException] error with a list of the unapproved names if not.

    .PARAMETER FieldNames
        This is a hashtable of field names and values that are desired to be sent to OpenSearch.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [Hashtable]$FieldNames

        #[Switch]$CaseSensitive
    )

    $ConfigData = Get-OSConfig
    if ($null -eq $COnfigData){
        # User has not configured any approved names. This is fine, they may not want to use that feature.
        return
    }
    if ($null -ne $ConfigData.PowerShellLogging.AllowedAttributes -and
    $ConfigData.PowerShell.AllowedAttributes.Count -ne 0){
        $ApprovedNames = [System.Collections.Generic.HashSet[String]]$ConfigData.PowerShellLogging.AllowedAttributes
    }
    elseif ($null -ne $ConfigData.PowerShellLogging.AllowedAttributesPath -and
    $ConfigData.PowerShellLogging.AllowedAttributesPath -ne ''){
        $AllowedAttributesPath = $ConfigData.PowerShellLogging.AllowedAttributesPath

        if (Test-Path -Path $AllowedAttributesPath){
            [System.Collections.Generic.HashSet[String]]$ApprovedNames = Get-Content -Path $AllowedAttributesPath | ConvertFrom-Json -Depth 100

            if ($ApprovedNames.Count -eq 0){
                throw [System.Configuration.ConfigurationException] "AllowedAttributesPath specified, but no values loaded from the file. Ensure that the file just contains a valid json array. FilePath: $AllowedAttributesPath"
            }
        }
        else {
            # Path may be on a network share which can go offline. We don't want it halt script execution if that's the case. This will just assume that all field names are valid.
            return
        }

    }
    else {
        # User has not configured any approved names. This is fine, they may not want to use that feature.
        return
    }

    # List to add unapproved names to
    $UnapprovedNames = New-Object System.Collections.Generic.List[string]

    foreach ($Name in $FieldNames.Keys){
        # Always accept -From at the end, as such remove it.
        $Name = $Name -Replace '-From$', ''
        if (-not $ApprovedNames.Contains($Name)){
            $UnapprovedNames.Add($Name)
        }
    }

    if ($UnapprovedNames.Count -gt 0){
        throw [System.ArgumentException] "Unapproved field names found: $UnapprovedNames"
    }
    else {
        return
    }
}

