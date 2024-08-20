function Get-OSIsmPolicyContent {
    <#
    .SYNOPSIS
        Retrieve an Index State Management Policy's contents.

    .DESCRIPTION
        Retrieve the content of an Index State Management Policy.

    .PARAMETER PolicyName
        Name of the Index State Management Policy to retrieve.

    .PARAMETER FullResponse
        Return more metadata _id, _version, _seq_no, and _primary_term
        Main content will now be under 'policy' parameter

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
        [String]$PolicyName,

        [switch]$FullResponse,

        [ValidateSet('JSON','YAML','CBOR','PSObject','Smile','PlainText')]
        [String]$Format='PSObject',

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    # Build URL parameters - [Void] is necessary to prevent StringBuilder from outputting the object.
    $UrlParameter = [System.Text.StringBuilder]::new()
    if ('PlainText' -eq $Format){
        # Do nothing
    }
    elseif ('PSObject' -eq $Format){    # PSObject is custom, processed later
        [Void]$Urlparameter.Append('&format=JSON')
    }
    else {
        [Void]$Urlparameter.Append("&format=$Format")
    }
    $UrlParameterString = $UrlParameter.ToString()

    # First URL parameter should be '?' not '&'
    if ($UrlParameterString -ne ''){
        $UrlParameterString = $UrlParameterString.Substring(1)
        $UrlParameterString = '?' + $UrlParameterString
    }

    # Build the request - $PolicyName may be ''
    $Request = '_plugins/_ism/policies/' + $PolicyName + $UrlParameterString

    $Params = @{
        'Request' = $Request
        'Method' = 'GET'
        'Credential' = $Credential
        'Certificate' = $Certificate
        'OpenSearchUrls' = $OpenSearchURL
    }

    $Response = Invoke-OSCustomWebRequest @Params

    # Handle response
    if ($Response.StatusCode -eq 200){
        if ('PSObject' -eq $Format){
            $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100

            if ($FullResponse -ne $True){
                # Strip out needless nested object
                $ResponseContent = $ResponseContent.policy
            }
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

Export-ModuleMember -Function Get-OSIsmPolicyContent

