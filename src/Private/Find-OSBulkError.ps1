function Find-OSBulkError {
    <#
    .SYNOPSIS
        Takes the raw response from bulk actions, and checks for errors. Returns if no errors were found, otherwise, an array of errors.

    .DESCRIPTION
        The bulk API always returns a 200 HTTP status code. This is because with _bulk, some actions can succeed, while others fail. As such, it's necessary to have this helper function loop through each entry in the response, finding if there were any errors and singling them out.

    .PARAMETER Response
        Raw response from OpenSearch after bulk action.
    #>
    [OutputType([PSCustomObject[]])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $Response
    )

    if ($Response.GetType().Name -eq 'BasicHtmlWebResponseObject'){
        $Response = $Response | ConvertFrom-Json -Depth 100
    }
    elseif ($Response.GetType().Name -eq 'PSCustomObject'){
        continue
    }
    else{
        throw [System.Management.Automation.PSInvalidCastException] "Incorrect data type sent to Find-OSBulkError - Please only send output of Invoke-WebRequest"
    }

    # Check for any errors
    # Note: It takes time to index bulk data. Success =/= ready for search
    if ($Response.errors -eq $true){
        # Fill error store with error objects
        $ErrorStore = [System.Collections.Generic.List[PSObject]]::new()

        foreach ($IndividualItem in $Response.items){
            # Index and Create are seperate actions that can be performed with _bulk
            if ($null -ne $IndividualItem.index){
                if ($IndividualItem.index.status -notmatch '2\d\d'){
                    $ErrorStore.Add($IndividualItem)
                }
            }
            elseif ($null -ne $IndividualItem.create){
                if ($IndividualItem.create.status -notmatch '2\d\d'){
                    # Not adding due to duplicate record is fine, don't return it
                    if ($IndividualItem.create.error.reason -notmatch 'document already exists'){
                        $ErrorStore.Add($IndividualItem)
                    }
                }
            }

        }

        $ErrorStore = $ErrorStore.ToArray()
        return $ErrorStore
    }
    elseif ($Response.errors -eq $false){
        return
    }
}

