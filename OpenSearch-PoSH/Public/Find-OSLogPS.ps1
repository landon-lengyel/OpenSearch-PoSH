function Find-OSLogPS {
    <#
    .SYNOPSIS
        Searches PowerShell logs for values.

    .DESCRIPTION
        Specialized function for searching log data from PowerShell scripts. Defaults to max 5 returned results.
        Any non-reserved paramters passed to the function will turn into field/values to search OpenSearch.

    .PARAMETER Index
        Name of the PowerShell index to search.

    .PARAMETER LogLevel
        Search by the severity of the log. Can be one of the following: Information, Warning, Error, Fatal Error

    .PARAMETER ExecutionScript
        Search by name of the executing script. Example: MyScript.ps1

    .PARAMETER ExecutionHostname
        Search by name of the computers hostname that executed the script. Example: MyDesktop

    .PARAMETER Size
        Max number of results to return.

    .PARAMETER Explain
        Return details about how OpenSearch computed the documents score.

    .PARAMETER Preference
        Prefer a shard or node on which to perform the search. Must be specified in a specific way, see: https://opensearch.org/docs/latest/api-reference/search/#the-preference-query-parameter

    .PARAMETER Message
        Searches for contents in a log message.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.

    .EXAMPLE
        $Request = @{
            'IndexName'         = 'log_ps_test'
            'LogLevel'          = 'Information'
            'Message'           = "This is my log"
            'ExecutionScript'   = 'Test.ps1'
            'ExecutionHostname' = 'MyComputer'
            'Size'              = 20
            'Explain'           = $True
        }

        $Response = Find-OSLogPS @Request

        Write-Host $Response.hits.hits
        Write-Host 'Returned hits: ' $Response.hits.hits.Count
        Write-Host 'Total hits: ' $Response.hits.total.value

    .EXAMPLE
        Find-OSLogPS -LogLevel 'Error'
    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    param(
        [string]$Index='log_ps',

        [ValidateSet('Information', 'Warning', 'Error', 'Fatal Error')]
        [string]$LogLevel,

        [string]$Message,

        [string]$ExecutionScript,

        [string]$ExecutionHostname,

        [Int64]$Size=5,

        [switch]$Explain,

        [string]$Preference,

        [Parameter(ValueFromRemainingArguments=$true)]
        $AdditionalParams,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    # Handle the arbitrary params
    if ($null -ne $AdditionalParams){
        # If it's already a hashtable, don't do additional processing
        if ($AdditionalParams.GetType().Name -eq 'HashTable'){
            $AdditionalParamsHash = $AdditionalParams
        }
        else {
            $AdditionalParamsHash = Convert-OSAdditionalParam -AdditionalParams $AdditionalParams
        }

        # Verify field names
        Confirm-OSFieldNamingStandard -FieldNames $AdditionalParamsHash
    }

    # Only lowercase index names are allowed
    $Index = $Index.ToLower()

    # Build URL parameters
    $UrlParameter = [System.Text.StringBuilder]::new()
    [Void]$UrlParameter.Append("&size=$Size")
    if ($Explain -eq $True){
        [Void]$UrlParameter.Append('&explain=true')
    }
    if ($Preference -ne ''){
        [Void]$UrlParameter.Append("&preference=$Preference")
    }
    $UrlParameterString = $UrlParameter.ToString()

    # First URL parameter should be '?' not '&'
    if ($UrlParameterString -ne ''){
        $UrlParameterString = $UrlParameterString.Substring(1)
        $UrlParameterString = '?' + $UrlParameterString
    }

    # Build query parameters
    $Query = @{
        'query' = @{
            'bool' = @{
                'must' = @(
                )
            }
        }
    }

    $QueryMust = [System.Collections.Generic.List[Hashtable]]::new()
    if ($LogLevel -ne ''){
        $QueryMust.Add(@{
            'match' = @{
                'LogLevel' = $LogLevel
            }
        })
    }
    if ($Message -ne ''){
        $QueryMust.Add(@{
            'match' = @{
                'Message' = $Message
            }
        })
    }
    if ($ExecutionScript -ne ''){
        $QueryMust.Add(@{
            'match' = @{
                'Execution Script' = $ExecutionScript
            }
        })
    }
    if ($ExecutionHostname -ne ''){
        $QueryMust.Add(@{
            'match' = @{
                'Execution Hostname' = $ExecutionHostname
            }
        })
    }
    if ($null -ne $AdditionalParamsHash){
        foreach ($Key in $AdditionalParamsHash.Keys){
            $QueryMust.Add(@{
                'match' = @{
                    $Key = $AdditionalParamsHash.$Key
                }
            })
        }
    }
    $Query.query.bool.must = $QueryMust.ToArray()

    # Build request
    $Request = $Index + '/_search' + $UrlParameterString

    $Body = $Query | ConvertTo-Json -Depth 100
    $Params = @{
        'Request' = $Request
        'Method' = 'GET'
	    'Credential' = $Credential
        'Certificate' = $Certificate
        'OpenSearchUrls' = $OpenSearchURL
        'Body' = $Body
    }

    $Response = Invoke-OSCustomWebRequest @Params

    # Handle response
    if ($Response.StatusCode -eq 200){
        $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100

        return $ResponseContent
    }
    else {
        throw $Response
    }
}

Export-ModuleMember -Function Find-OSLogPS

