function Initialize-OSIndexBeta {
    <#
    .SYNOPSIS
        (BETA) Attempts to create index with data types

    .DESCRIPTION
        (BETA) This function is in beta and is subject to change.
        Currently ScaledFloat, Alias, TokenCount, and KnnVector are not working with this function. Those require more options which will require reworking this function.

        Getting index metadata requires additional permissions. To avoid that, it simply attempts to create index with the specified data types.
        Failure to create it due to it already existing is considered success.
        Data types should be a hashtable with the key being the name of the field, and the value being the data type.
        If you want OpenSearch to interpret the types, there's no need to use this function. Just write data to the index name you want.
        OpenSearch data types can be found here: https://opensearch.org/docs/latest/field-types/supported-field-types/index/


    .PARAMETER Index
        Index you would like the data to be added to.

    .PARAMETER DataTypes
        Hashtable with the key being the name of the field, and the value being the data type.

    .PARAMETER Force
        Skips the module's data type verification and attempts to run it with arbitrary values.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Index,

        [Parameter(Mandatory=$true)]
        [Hashtable]$DataTypes,

        [Boolean]$Force,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    # Verify that the data type is valid for OpenSearch.
    # Set $Force to $True to skip this verification
    if ($Force -ne $true){
        Confirm-OSDataType -DataTypes $DataTypes | Out-Null
    }

    #Only lowercase index names are allowed
    $Index = $Index.ToLower()

    # Build body from DataTypes dynamically. It's hashtables all the way down!
    # Example of what that ultimately looks like:
    # $Body = @{
    #    "mappings" = @{
    #       "properties" = @{
    #          "Timestamp" = @{ "type" = "date" }
    #          "Location" = @{ "type" = "float" }
    #          "ID" = @{ "type" = "float" }
    #          "Description" = @{ "type" = "text" }
    #          "IP Address" = @{ "type" = "ip" }
    # }
    $Body = @{
        "mappings" = @{
            "properties" = @{}
        }
    }
    foreach ($Field in $DataTypes.keys) {
        # Create hashtables to go into properties
        # New-Variable -Name $Field -Value @{
        #     "type" = $DataTypes[$Field]
        # }

        $NewTable = @{
            "type" = $DataTypes[$Field]
        }
        $Body.mappings.properties.Add($Field, $NewTable)
    }
    $Body = $Body | ConvertTo-Json -Depth 100

    $Request = $Index
    $Response = Invoke-OSCustomWebRequest -OpenSearchUrls $OpenSearchURL -Request $Request -Method "PUT" -Credential $Credential -Certificate $Certificate -Body $Body

    # Return $true if successfully created or already exists
    if ($Response.StatusCode -eq 200){
        # index created successfully
        return
    }
    elseif ($Response.StatusCode -eq 400){
        $Response = $Response | ConvertFrom-Json -Depth 100
        if ($Response.error.type -eq 'resource_already_exists_exception'){
            # index already exists
            return
        }
        else {
            throw $Response
        }
    }
    else{
        throw $Response
    }
}

Export-ModuleMember -Function Initialize-OSIndexBeta

