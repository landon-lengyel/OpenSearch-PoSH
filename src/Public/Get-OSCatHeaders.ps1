function Get-OSCatHeader {
    <#
    .SYNOPSIS
        Find all possible headers for a given _cat API.

    .DESCRIPTION
        Return all optional headers that could be returned for a given _cat api.

    .PARAMETER CatApi
        The _cat API endpoint you would like to find output for. Include only what comes after '_cat/' in the API endpoint. See example(s) for more help. This is case sensitive.

    .PARAMETER OutputFormat
        How to format the output.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.

    .EXAMPLE
        Get-OSCatHelp -Certificate $Cert -OpenSearchURL 'https://os.example.com:9200' -CatApi 'indices'
    #>
    [OutputType([array])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('\w+')]
        [String]$CatApi,

        # Prefer this parameter to be 'OutputFormat' instead of 'Format' like the other functions since it's options are different, and implemented entirely differently.
        [ValidateSet('PSCustomObject','HeadersOnly','HeadersCsv')]
        [String]$OutputFormat='PSCustomObject',

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    $Request = '_cat/' + $CatApi + '?help'

    $Params = @{
        'Request' = $Request
        'Method' = 'GET'
        'Credential' = $Credential
        'Certificate' = $Certificate
        'OpenSearchUrls' = $OpenSearchURL
    }
    $Response = Invoke-OSCustomWebRequest @Params

    # Verify successful response
    if ($Response.StatusCode -ne 200){
        throw $Response
    }

    # Parse raw text output (no fomatted option with ?help endpoints) to PowerShell object
    $ResponseContent = $Response.Content

    $Lines = $ResponseContent -split '\n'

    # Fill headers to HelpList
    $HelpList = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($Line in $Lines){
        # Ignore empty lines
        if ($Line -match '^\s*\n' -or
        $Line -match '^\s*$'){
            continue
        }

        # Split on the '|' to make multiline string
        $Split = $Line -split '\|'

        # Add to HelpList array and remove excess whitespace
        $HelpEntry = [PSCustomObject]@{
            'Header' = ($Split[0].Trim())
            'Description' = ($Split[2].Trim())
        }
        [void]$HelpList.Add($HelpEntry)
    }
    $HelpList = $HelpList.ToArray()

    if ($OutputFormat -eq 'PSCustomObject'){
        # Already that format
        $ReturnArray = $HelpList
    }
    elseif ($OutputFormat -eq 'HeadersOnly'){
        $ReturnArray = $HelpList.Header
    }
    elseif ($OutputFormat -eq 'HeadersCsv') {
        # Utilize the output field seperator variable
        $ofs = ','
        $ReturnArray = [String]$HelpList.Header
    }

    if ($HelpList.count -ne 0){
        return $ReturnArray
    }
    else {
        throw 'Error processing the APIs output. Verify CatApi is valid (it is case sensitive).'
    }
}

Export-ModuleMember -Function Get-OSCatHeader

