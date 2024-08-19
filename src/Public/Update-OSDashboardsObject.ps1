function Update-OSDashboardsObject {
    <#
    .SYNOPSIS
        Updates a specific document at the requested location

    .DESCRIPTION
        Takes an value for a document located at a specific location in a specific index, and updates it to the desired value.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.

    .PARAMETER DashboardsIndexName
        Specify name of the OpenSearch Dashboards index the document is stored in. Defaults to .kibana

    .PARAMETER DocumentId
        The _id of the document to update.

    .PARAMETER NewValues
        Hashtable of property name / value pairs to update to.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL,

        [Parameter(Mandatory=$true)]
        [string]$DashboardsIndexName='.kibana',

        [Parameter(Mandatory=$true)]
        [string]$DocumentId,

        [Parameter(Mandatory=$true)]
        [hashtable]$NewValues
    )

    # Check to see if dynamic mapping is set to strict, and change it if needed
    $Request = $DashboardsIndexName + '/_mapping'
    $Response = Invoke-OSCustomWebRequest -OpenSearchUrls $OpenSearchURL -Request $Request -Method 'GET' -Credential $Credential -Certificate $Certificate

    if ($Response.StatusCode -ne '200'){ throw "Unable to get mapping for $DashboardsIndexName" }

    $DashboardsIndex = $Response.Content | ConvertFrom-Json -Depth 100
    $DashboardsIndexRealName = $DashboardsIndex.PSObject.Properties.Name
    $MappingDynamic = $DashboardsIndex.$DashboardsIndexRealName.mappings.dynamic

    if ($MappingDynamic -eq 'strict'){
        $Request = $DashboardsIndexRealName + '/_mapping'

        $Body = @{
            'dynamic' = 'false'
        } | ConvertTo-Json -Depth 100
        $Response = Invoke-OSCustomWebRequest -OpenSearchUrls $OpenSearchURL -Request $Request -Method 'PUT' -Credential $Credential -Certificate $Certificate -Body $Body

        if ($Response.StatusCode -ne '200'){
            throw "Unable to change dynamic mapping from strict for $DashboardsIndexRealName"
        }
    }

    # Perform dashboards object change
    $Body = @{
        'doc' = $NewValues
    } | ConvertTo-Json -Depth 100

    $Request = $DashboardsIndexName + '/_update/' + $Documentid
    try {
        $Response = Invoke-OSCustomWebRequest -OpenSearchUrls $OpenSearchURL -Request $Request -Method "POST" -Credential $Credential -Certificate $Certificate -Body $Body
    }
    catch {
        if ($MappingDynamic -eq 'strict'){
            # Need to continue regardless of errors so we can fix mapping
            continue
        }
        else {
            throw
        }
    }

    # Undo dynamic mapping change if needed
    if ($MappingDynamic -eq 'strict'){
        $Request = $DashboardsIndexRealName + '/_mapping'

        $Body = @{
            'dynamic' = 'strict'
        } | ConvertTo-Json -Depth 100
        $Response = Invoke-OSCustomWebRequest -OpenSearchUrls $OpenSearchURL -Request $Request -Method 'PUT' -Credential $Credential -Certificate $Certificate -Body $Body

        if ($Response.StatusCode -ne '200'){
            throw "Unable to change dynamic mapping back to strict for $DashboardsIndexRealName"
        }
    }

    if ($Response.StatusCode -eq '200'){
        return $True
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function Update-OSDashboardsObject

