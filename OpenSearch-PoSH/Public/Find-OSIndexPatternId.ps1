function Find-OSIndexPatternId {
    <#
    .SYNOPSIS
        Finds an Index Pattern's random ID based on the name

    .DESCRIPTION
        Takes the user-visible name of an OpenSearch Dashboards Index Pattern, and performs a search on the Dashboards index for it.
        Returns a string containing the id. Returns $null if there were no results.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.

    .PARAMETER IndexPatternName
        User visible name of an existing Index Pattern.

    .PARAMETER DashboardsIndexName
        Specify name of the OpenSearch Dashboards index, if not .kibana
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL,

        [Parameter(Mandatory=$true)]
        [string]$IndexPatternName,

        [string]$DashboardsIndexName='.kibana'
    )

    # Build search body
    $Body = @{
        '_source' = @{
            'includes' = @('index-pattern.title')
        }
        'stored_fields' = '_id'
        'query' = @{
            'match' = @{
                'index-pattern.title' = $IndexPatternName
            }
        }
    } | ConvertTo-Json -Depth 100

    $Request = $DashboardsIndexName + '/_search'
    $Response = Invoke-OSCustomWebRequest -OpenSearchUrls $OpenSearchURL -Request $Request -Method "GET" -Credential $Credential -Certificate $Certificate -Body $Body

    # Return the full response if there was an error so it may be handled
    if ($Response.StatusCode -ne 200){
        throw $Response
    }

    # Process the response
    $Response = $Response.Content | ConvertFrom-Json -Depth 100

    # No results returned
    if ($Response.hits.hits.count -eq 0){
        return $null
    }
    # Find the matching search results
    elseif ($Response.hits.hits.count -ge 1){
        foreach ($Result in $Response.hits.hits){
            if ($Result._source.'index-pattern'.title -eq $IndexPatternName){
                # Remove text in front
                $ID = ($Response.hits.hits._id -split ':')[1]
                return $ID
            }
        }
    }
    # Some other error
    else {
        throw $Response
    }
}

Export-ModuleMember -Function Find-OSIndexPatternId
