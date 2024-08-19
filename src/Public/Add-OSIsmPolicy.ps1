function Add-OSIsmPolicy {
    <#
    .SYNOPSIS
        Add an Index State Management (ISM) policy to an index that does not currently have one.

    .DESCRIPTION
        Add an Index State Management (ISM) policy to an index that does not currently have one. This does not work if the index already has a policy, to change policies or update to the newest version, use Update-OSIsmPolicy

    .PARAMETER Index
        Name of an index or data stream. Data streams will apply the policy to the current write index.

    .PARAMETER PolicyName
        Name of a policy to change the index to.

    .PARAMETER Format
        Return results in specified format.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.
    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String]$Index,

        [Parameter(Mandatory)]
        [String]$PolicyName,

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

    # Build the body
    $Body = @{
        'policy_id' = $PolicyName
    } | ConvertTo-Json -Depth 100

    $Request = '_plugins/_ism/add/' + $Index + $UrlParameterString

    $Params = @{
        'Request' = $Request
        'Method' = 'POST'
        'Body' = $Body
        'Credential' = $Credential
        'Certificate' = $Certificate
        'OpenSearchUrls' = $OpenSearchURL
    }

    $Response = Invoke-OSCustomWebRequest @Params

    # Handle response
    if ($Response.StatusCode -eq 200){
        $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100

        # Errors can occur and still return status code 200 with this endpoint
        if ($ResponseContent.failures -eq $True){
            throw $ResponseContent
        }

        if ('PSObject' -eq $Format){
            # Already using $ResponseContent
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

Export-ModuleMember -Function Add-OSIsmPolicy

