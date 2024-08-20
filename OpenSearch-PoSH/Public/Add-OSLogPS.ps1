function Add-OSLogPS {
    <#
    .SYNOPSIS
        Adds PowerShell log to a log_ps_* data stream.

    .DESCRIPTION
        Specialized function for logging data from various PowerShell scripts. Success returns nothing.
        Any non-reserved paramters passed to the function will turn into fields passed to OpenSearch.

    .PARAMETER Index
        Name of the PowerShell index to add to. Must be log_ps_misc OR follow format: log_ps_{SCRIPT NAME}_{OPTIONAL HOSTNAME}-{OPTIONAL EXTRA INFO}

    .PARAMETER DisableLocalLog
        Use to disable using the local LogFile option. Disabling will speed up the function.

    .PARAMETER LogFile
        Path to a local log file to save a copy of what's sent to OpenSearch. Defaults to: $PSScriptRoot/Logs/$ScriptName_OpenSearch_yyyy-MM-dd.json

    .PARAMETER LogLevel
        The severity of the log. Must be one of the following: Information, Warning, Error, Fatal Error

    .PARAMETER Message
        Log message.

    .PARAMETER DocumentId
        Optionally include an _id to index the document at. Do not specify to have OpenSearch generate one.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.

    .EXAMPLE
        PS>$Request = @{
        PS>'Index' = 'log_ps_example'
        PS>'LogLevel'  = 'Information'
        PS>'Message'   = "Script is starting"
        PS>'AD.SamAccountName' = 'MyUser'
        PS>'LogFile' = './MyPath/ThisIsALog.json'
        PS>}
        PS>Add-OSLogPS @Request

        Use hashtable to add parameters with a period in the name.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Index,

        [switch]$DisableLocalLog,

        [string]$LogFile,

        [Parameter(Mandatory)]
        [ValidateSet('Trace', 'Verbose', 'Information', 'Warning', 'Error', 'Critical')]
        [string]$LogLevel,

        [string]$Message,

        [string]$DocumentId,

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
    # Verify format of IndexName
    if ($Index -notmatch 'log_ps_'){
        throw [System.ArgumentException] 'IndexName must be: log_ps_misc OR match the format: log_ps_{SCRIPT NAME}_{OPTIONAL HOSTNAME}-{OPTIONAL EXTRA INFO}'
    }

    # Script name is used for OpenSearch log and path to save local copy of log
    $ScriptName = $(Get-PSCallStack | Where-Object {$_.Command -match '.ps1'})[0].Command
    if ('' -eq $LogFile){
        $LogFile = "$global:PSScriptRoot\Logs\$($ScriptName.replace('.ps1',''))_OpenSearch_$(Get-Date -Format yyyy-MM-dd).json"
    }

    # Build the request
    $Body = @{
        'LogLevel' = $LogLevel
        'Message' = $Message
        'Hostname' = $env:COMPUTERNAME
        'PoSH.Script' = $ScriptName
        '@timestamp' = $(Get-Date)
    }
    if ($null -ne $AdditionalParamsHash){
        $Body += $AdditionalParamsHash
    }

    # Add log content to local log file
    if ($False -eq $DisableLocalLog){
        if (-not (Test-Path $LogFile)){
            # Redirect to $null, otherwise if there's no other return response it returns the Path object to the log
            New-Item -Path $LogFile -Force > $null
            $LogEntries = @($Body)
        }
        else {
            [Array]$LogEntries = Get-Content $LogFile | ConvertFrom-Json -Depth 100
            $LogEntries += $Body
        }

        $LogEntries | ConvertTo-Json -Depth 100 -AsArray | Out-File -FilePath $LogFile
    }

    $Body = $Body | ConvertTo-Json -Depth 100
    # PUT needed for custom _id fields. Otherwise POST
    if ($DocumentId -ne ''){
        $Request = $Index + '/_doc/' + $DocumentId
        $Response = Invoke-OSCustomWebRequest -Method 'PUT' -Request $Request -OpenSearchUrls $OpenSearchURL -Credential $Credential -Certificate $Certificate -Body $Body
    }
    else {
        $Request = $Index + '/_doc'
        $Response = Invoke-OSCustomWebRequest -Method 'POST' -Request $Request -OpenSearchUrls $OpenSearchURL -Credential $Credential -Certificate $Certificate -Body $Body
    }

    if ($Response.StatusCode -eq '201'){
        return
    }
    else {
        throw $Response
    }

}

Export-ModuleMember -Function Add-OSLogPS

