function Copy-OSIsmPolicy {
    <#
    .SYNOPSIS
        Duplicates an Index State Management (ISM) policy.

    .DESCRIPTION
        Duplicates an Index State Management (ISM) policy. Only changes what is necessary to allow for duplication.
        Further editing can be done in OpenSearch Dashboards.

    .OUTPUTS
        System.Management.Automation.PSCustomObject Returns an object that represents the new policy, similar if you were to run Get-OSIsmPolicyContent with FullResponse

    .PARAMETER PolicyName
        Name of the Index State Management Policy to duplicate.

    .PARAMETER NewPolicyName
        Name of the new Index State Management Policy.

    .PARAMETER NewIndexPatterns
        If the old policy has an index pattern, these are the new patterns to apply since they cannot overlap.
        If NewIndexPatterns and NewAdvancedIndexPatterns are ommited, the old index patterns will just be removed if necessary.
        Must be an array of index patterns. Priority will match the order of the array.

    .PARAMETER NewAdvancedIndexPatterns
        If the old policy has an index pattern, these are the new patterns to apply since they cannot overlap.
        If NewIndexPatterns and NewAdvancedIndexPatterns are ommited, the old index patterns will just be removed if necessary.
        This is parameter is more complicated, but more flexible. Object has a specific structure. Must be an array, with members that are PSCustomObjects. Each object must contain a property named 'index_patterns' which is itself an array of index patterns (strings). The object must also contain a property called 'priority' which is an int representing the evaluation priority.
        - [array]NewIndexPatterns
            - [PSCustomObject]
                - [array]index_patterns
                    - [string]
                    - [string]
                - [int32]priority
            - [PSCustomObject]
    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.
    #>
    [CmdletBinding(DefaultParameterSetName = 'NoIndexPatterns')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [String]$PolicyName,

        [Parameter(Mandatory)]
        [String]$NewPolicyName,

        [Parameter(ParameterSetName = 'SimpleIndexPatterns')]
        [array]$NewIndexPatterns,

        [Parameter(ParameterSetName = 'AdvancedIndexPatterns')]
        [array]$NewAdvancedIndexPatterns,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    # Verify Index Pattern parameters as best as possible, and create the necessary object if using SimpleIndexPatterns
    if ($PSCmdlet.ParameterSetName -eq 'SimpleIndexPatterns'){
        if ($NewIndexPatterns[0].GetType().FullName -ne 'System.String'){
            throw 'NewIndexPatterns can only be an array of strings. Use NewAdvancedIndexPatterns for more advanced options.'
        }

        # Create the structure that needs to be sent to the API
        $IndexPatterns = [System.Collections.Generic.List[Pscustomobject]]::new()

        for ($Count=0; $Count -lt $NewIndexPatterns.Length; $Count++){
            $IndividualIndexPatterns = New-Object -TypeName pscustomobject

            $IndividualIndexPatterns | Add-Member -Name 'index_patterns' -Type NoteProperty -Value @($NewIndexPatterns[$Count])
            $IndividualIndexPatterns | Add-Member -Name 'priority' -Type NoteProperty -Value ($Count + 1)

            $IndexPatterns.Add($IndividualIndexPatterns)
        }

        $IndexPatterns = $IndexPatterns.ToArray()
    }
    if ($PSCmdlet.ParameterSetName -eq 'AdvancedIndexPatterns'){
        if ($NewAdvancedIndexPatterns[0].GetType().Name -ne 'PSCustomObject'){
            throw 'NewAdvancedIndexPatterns must be an array of PSCustomObjects. See help for full structure. Use NewIndexPatterns for a more straightforward experience.'
        }
        if ($NewAdvancedIndexPatterns[0].index_patterns.GetType().BaseType.Name -ne 'Array'){
            throw 'NewAdvancedIndexPatterns objects must contain a property named index_patterns that is itself an array of strings. Use NewIndexPatterns for a more straightforward experience.'
        }
        if ($NewAdvancedIndexPatterns[0].index_patterns[0].GetType().FullName -ne 'System.String'){
            throw 'NewAdvancedIndexPatterns objects must contain a property named index_patterns that is itself an array of strings. Use NewIndexPatterns for a more straightforward experience.'
        }
        if ($NewAdvancedIndexPatterns[0].priority.GetType().FullName -ne 'System.Int64' -and 
        $NewAdvancedIndexPatterns[0].priority.GetType().FullName -ne 'System.Int32'){
            throw 'NewAdvancedIndexPatterns objects must contain a property named priority which is an Int. Use NewIndexPatterns for a more straightforward experience.'
        }

        $IndexPatterns = $NewAdvancedIndexPatterns
    }

    # Get the old policy content
    # Build the request
    $Request = '_plugins/_ism/policies/' + $PolicyName + '?format=JSON'

    $Params = @{
        'Request' = $Request
        'Method' = 'GET'
        'Credential' = $Credential
        'Certificate' = $Certificate
        'OpenSearchUrls' = $OpenSearchURL
    }

    $Response = Invoke-OSCustomWebRequest @Params

    if ($Response.StatusCode -ne 200){
        throw $Response
    }
    else {
        $OriginalPolicy = $Response.Content | ConvertFrom-Json -Depth 100
    }

    # Make necessary modifications to create a new policy without conflict
    $NewPolicy = New-Object -TypeName pscustomobject
    $NewPolicy | Add-Member -Name 'policy' -Type NoteProperty -value $OriginalPolicy.policy


    # OpenSearch seems to edit policy_id on it's own, but doing it manually just in case
    $NewPolicy.policy.policy_id = $NewPolicyName

    # Fix the Index Patterns aka ISM Template
    if ($IndexPatterns.count -gt 0){
        $NewPolicy.policy.ism_template = $IndexPatterns
    }
    else {
        $NewPolicy.PSObject.Properties.Remove('ism_template')
    }

    # Create new policy
    $Request = '_plugins/_ism/policies/' + $NewPolicyName
    $Body = $NewPolicy | ConvertTo-Json -Depth 100

    $Params = @{
        'Request' = $Request
        'Body' = $Body
        'Method' = 'PUT'
        'Credential' = $Credential
        'Certificate' = $Certificate
        'OpenSearchUrls' = $OpenSearchURL
    }

    $Response = Invoke-OSCustomWebRequest @Params

    # Handle response
    if ($Response.StatusCode -eq 201){
        $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100

        return $ResponseContent
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function Copy-OSIsmPolicy

