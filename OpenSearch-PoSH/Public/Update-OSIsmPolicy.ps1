function Update-OSIsmPolicy {
    <#
    .SYNOPSIS
        Update an Index State Management Policy to a new policy, or just update to the latest version of the current managed policy by omitting PolicyName.

    .DESCRIPTION
        Update an Index State Management Policy to a new policy, or just update to the latest version of the current managed policy by omitting PolicyName. You need to do this after update the policy if you want the changes to apply to the index.
        Changes DO NOT always occur immediately. If the change is small, it will occur immediately. If it is a large change such as modifying the state, actions, or the order of actions of the current state the index is in, then it will happen at the end of it's current state.
        You must use Add-OSIsmPolicy to add policies to unmanaged indices.

    .PARAMETER Index
        Name of an index or data stream. Data streams will apply the policy to the current write index.

    .PARAMETER PolicyName
        Name of a policy to change the index to.

    .PARAMETER IfState
        Only apply the update if the index is currently in this ISM state.

    .PARAMETER NewState
        After the change, transition to this ISM state.

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

        [String]$PolicyName,

        [String]$IfState,

        [String]$NewState,

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

    # Process data stream
    $DataStream = Get-OSDataStream -DataStream $Index -ErrorAction SilentlyContinue
    if ($null -ne $DataStream){
        # Get backing index name that matches the 'generation' number
        $Generation = $DataStream.generation.ToString()
        $PaddedGeneration = $Generation.PadLeft(6,'0')

        # Regex: Match .ds- then any characters until it reaches 6 consecutive digits, then insert the $PaddedGeneration
        $Index = $DataStream.indices.'index_name' | Where-Object {$_ -match "^\.ds-.+?(?=\d{6})$PaddedGeneration$"}
    }

    # Build the body
    $Body = @{}

    if ($PolicyName -ne ''){
        # Apply the specified policy
        $Body += @{'policy_id' = $PolicyName}
    }
    else {
        # Re-apply the existing policy
        $CurrentPolicy = Get-OSIsm -Index $Index -ShowPolicy
        $PolicyName = $CurrentPolicy.$Index.'index.plugins.index_state_management.policy_id'

        $Body += @{'policy_id' = $PolicyName}
    }
    if ($IfState -ne ''){
        $Body.Add(@{
            'include' = @(
                @{
                    'state' = $IfState
                }
            )
        })
    }
    if ($NewState -ne ''){
        $Body += @{'state' = $NewState}
    }
    $Body = $Body | ConvertTo-Json -Depth 100

    # Build the request
    $Request = '_plugins/_ism/change_policy/' + $Index + $UrlParameterString

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

        $ResponseContent = $Response.Content | ConvertFrom-JSon -Depth 100
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

Export-ModuleMember -Function Update-OSIsmPolicy

