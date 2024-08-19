function Invoke-OSCustomWebRequest {
    <#
    .DESCRIPTION
        Used by other functions. Supports multiple OpenSearch servers, arbitrary additional params, basic auth, certificate auth, and Invoke-WebRequest optimization.
        Lets the calling function handle output, including errors.

    .PARAMETER OpenSearchUrls
        Array or just a string or OpenSearch server URLs. Include port number and protocol (https).

    .PARAMETER Request
        String containing the request data. Everything in the URL after the port.

    .PARAMETER Method
        String containing the method to use (POST,PUT,PATCH,GET,etc.)

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER Body
        String (JSON) of the HTTP body of the request to include.

    .PARAMETER AllowUnencryptedAuthentication
        NOT RECOMMENDED. Allows sending credentials without encryption (over http).

    .PARAMETER SkipCertificateCheck
        NOT RECOMMENDED. Skips checking the validity of the HTTPS certificate. You may as well consider this traffic unencrypted.

    .PARAMETER AdditionalParams
        All other parameters to pass to Invoke-WebRequest. Does not need to be directly called.
    #>
    [OutputType([Microsoft.PowerShell.Commands.BasicHtmlWebResponseObject])]
    [CmdletBinding()]
    param(
        $OpenSearchUrls,

        [Parameter(Mandatory=$true)]
        [string]$Request,

        [Parameter(Mandatory=$true)]
        [string]$Method,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        [string]$Body,

        [switch]$AllowUnencryptedAuthentication,

        [switch]$SkipCertificateCheck,

        [Parameter(ValueFromRemainingArguments=$true)]
        $AdditionalParams
    )

    # Attempt to get config file (may return $null if not found)
    $ConfigData = Get-OSConfig

    # If all required options are not specified by the calling function, use the config files
    if ($null -eq $OpenSearchUrls){
        if ($null -eq $ConfigData.Nodes){
            throw "You haven't specified an OpenSearch URL. That can be specified by the calling function, or as a list of Nodes in the config file. See New-OSConfigFile for more info"
        }
        else {
            $OpenSearchUrls = $ConfigData.Nodes

            # Only add insecure options specified in config file if OpenSearchUrls also come from config file.
            if ($true -eq $ConfigData.NodeOptions.AllowUnencryptedAuthentication){
                $AllowUnencryptedAuthentication = $true
            }
            if ($true -eq $ConfigData.NodeOptions.SkipCertificateCheck){
                $SkipCertificateCheck = $true
            }
        }
    }

    # Attempt to pull credential from config file if necessary
    if ($null -eq $Credential.Password -and
    $null -eq $Certificate){
        $ConfigCredential = Get-OSConfigAuthentication -ConfigData $ConfigData
        if ($ConfigCredential.GetType().FullName -eq 'System.Security.Cryptography.X509Certificates.X509Certificate2'){
            $Certificate = $ConfigCredential
        }
        elseif ($ConfigCredential.GetType().Name -eq 'PSCredential'){
            $Credential = $ConfigCredential
        }
    }

    # Data validation and conversion
    if ($OpenSearchUrls.GetType().Name -eq 'String'){
        $OpenSearchUrls = @($OpenSearchUrls)
    }
    elseif ($OpenSearchUrls.GetType().BaseType.Name -ne 'Array' -and
    $OpenSearchUrls.GetType().Name -ne 'ArrayList'){
        throw [System.Management.Automation.PSInvalidCastException] "OpenSearchUrls must be expressed as either an array of strings containing URLs, or a single string containing a URL."
    }

    # Combine $AdditionalParams with the body
    if ($null -ne $AdditionalParams){
        $AdditionalParamsHash = Convert-OSAdditionalParam $AdditionalParams
    }
    else {
        $AdditionalParamsHash = $null
    }

    # If the path begins with a slash, it will add another and not work properly.
    $Request = $Request -replace '^/',''

    # Build hashtable of parameters to splat to Invoke-WebRequest
    $WebRequestParams = @{
        'Method' = $Method
        'ContentType' = 'application/json'
        'SkipHttpErrorCheck' = $true
        'Body' = $Body
    }

    # Add authentication
    if ($null -ne $Certificate){
        $WebRequestParams.Certificate = $Certificate
    }
    elseif ($null -ne $Credential.Password){
        $WebRequestParams.Authentication = 'basic'
        $WebRequestParams.Credential = $Credential
    }

    # Add insecure options
    if ($AllowUnencryptedAuthentication -eq $true){
        $WebRequestParams.AllowUnencryptedAuthentication = $true
    }
    if ($SkipCertificateCheck -eq $true){
        $WebRequestParams.SkipCertificateCheck = $true
    }

    # Add Invoke-WebRequest's additional params if needed
    if ($null -ne $AdditionalParamsHash){ $WebRequestParams += $AdditionalParamsHash }

    # Speeds up Invoke-WebRequest
    $OldProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    foreach ($OpenSearchUrl in $OpenSearchUrls){
        # Attempt each OpenSearch URL if multiple are specified, and the request fails.
        $Endpoint = $OpenSearchUrl + '/' + $Request
        $WebRequestParams.Uri = $Endpoint

        $Response = Invoke-WebRequest @WebRequestParams

        # Keep trying servers until it succeeds
        if (($Response.StatusCode -eq 200) -or ($Response.StatusCode -eq 201)){
            # Restore to previous value
            $ProgressPreference = $OldProgressPreference
            return $Response
        }
    }

    # Restore to previous value
    $ProgressPreference = $OldProgressPreference

    # Failures may be due to factors unrelated to it being clustered, so you want the results returned regardless and let the calling function handle the response.
    return $Response
}

