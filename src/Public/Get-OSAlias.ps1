function Get-OSAlias {
    <#
    .SYNOPSIS
        Get alias(es) for Index names.

    .DESCRIPTION
        Aliases allow users to address an index by a different name. Use this function to see what aliases you have configured.

    .PARAMETER Alias
        Alias name(s) to limit results.

    .PARAMETER ExpandWildcards
        Expands wildcard expressions to different indexes. Combine multiple values with commas. Available values are all (match all indexes), open (match open indexes), closed (match closed indexes), hidden (match hidden indexes), and none (do not accept wildcard expressions). Default is open.

    .PARAMETER VerboseResponse
        Add headers to columns and add some formatting. Only makes a difference when format is PlainText.

    .PARAMETER Headers
        Array of column headers to display.

    .PARAMETER ListHeaders
        List all possible header options and exit. Utilizes the Get-OSCatHeaders function.

    .PARAMETER Format
        Return results in specified format.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.
    #>
    [CmdletBinding()]
    param(
        [SupportsWildcards()]
        [Array]$Alias,

        [ValidateSet('all','open','closed','hidden','none')]
        [String]$ExpandWildcards='open',

        [boolean]$VerboseResponse=$True,

        [Array]$Headers,

        [switch]$ListHeaders,

        [ValidateSet('JSON','YAML','CBOR','PSObject','Smile','PlainText')]
        [String]$Format='PSObject',

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    if ($ListHeaders -eq $True){
        $Headers = Get-OSCatHeaders -CatApi 'aliases'
        return $Headers
    }

    # Alias names must be lowercase
    if ($null -ne $Alias){
        for ($AliasCount=0; $AliasCount -lt $Alias.Count; $AliasCount++){
            $Alias[$AliasCount] = $Alias[$AliasCount].ToLower()
        }
    }

    # Use output field seperator for casting arrays to strings with comma seperation
    $OldOfs = $ofs
    $ofs = ','

    # Build URL parameters
    $UrlParameter = [System.Text.StringBuilder]::new()
    if ($VerboseResponse -eq $True){
        [Void]$Urlparameter.Append('&v')
    }
    if ($Headers.Count -ge 1){
        [Void]$Urlparameter.Append("&h=$([String]$Headers)")
    }
    if ('open' -ne $ExpandWildcards){
        [Void]$UrlParameter.Append("&expand_wildcards=$ExpandWildcards")
    }
    if ('PlainText' -eq $Format){
        # Do nothing
    }
    elseif ('PSObject' -eq $Format){    # PSObject is custom, processed later
        [Void]$Urlparameter.Append('&format=JSON')
    }
    else {
        [Void]$Urlparameter.Append("&format=$Format")
    }
    $UrlParameterString = $Urlparameter.ToString()

    # First URL parameter should be '?' not '&'
    if ($UrlParameterString -ne ''){
        $UrlParameterString = $UrlParameterString.Substring(1)
        $UrlParameterString = '?' + $UrlParameterString
    }

    # Build request
    if ($Alias.Count -ge 1){
        $Request = '/_cat/aliases/' + [String]$Alias + $UrlParameterString
    }
    else {
        $Request = '/_cat/aliases' + $UrlParameterString
    }

    $ofs = $OldOfs

    $Params = @{
        'Request' = $Request
        'Method' = 'GET'
        'Credential' = $Credential
        'Certificate' = $Certificate
        'OpenSearchUrls' = $OpenSearchURL
    }
    $Response = Invoke-OSCustomWebRequest @Params

    if ($Response.StatusCode -eq 200){
        # Handle response
        if ('PSObject' -eq $Format){
            $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100
        }
        elseif ('JSON' -eq $Format){
            $ResponseContent = $Response.Content
        }
        else {     # All other types store it in RawContent
            # Use singeline regex to remove header information
            $ResponseContent = $Response.RawContent -replace '(?s)^(.|\n)*Content-Length: \d*....', ''
        }

        return $ResponseContent
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function Get-OSAlias
