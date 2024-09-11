function Add-OSLogPSBulk {
    <#
    .SYNOPSIS
        Adds PowerShell log to a log_ps_* data stream using the bulk API for improved performance.

    .DESCRIPTION
        Specialized function for logging data from various PowerShell scripts. Success returns nothing.
        Uses the bulk API for improved performance. Use this over Add-OSLogPS when you are less concerned with log reliabity, and more concerned with performance (such as with extremely verbose logs).
        Use a trap{} in your script to improve reliability of Add-OSLogPSBulk 

    .PARAMETER Index
        Name of the PowerShell index to add to. Must be log_ps_misc OR follow format: log_ps_{SCRIPT NAME}_{OPTIONAL HOSTNAME}-{OPTIONAL EXTRA INFO}

    .PARAMETER Logs
        Array of hashtables containing the logs. Requires keys:
          - LogLevel
          - @timestamp (Containing the timestamp of when the log occurred)

    .PARAMETER DisableLocalLog
        Use to disable using the local LogFile option. Disabling will speed up the function.

    .PARAMETER LogFile
        Path to a local log file to save a copy of what's sent to OpenSearch. Defaults to: $PSScriptRoot/Logs/$ScriptName_OpenSearch_yyyy-MM-dd.json

    .PARAMETER OpType
        Operation to perform on the API. This will default to index, and usually that is fine. Data streams need 'create'

    .PARAMETER UploadLimit
        Break up upload to this many files per attempt. Max 4999. Break up upload to this many files per attempt. Max 4999. Sometimes necessary if individual documents are large.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.

    .EXAMPLE
        # In case of terminating error, upload existing logs
        trap {
            if ($LogList.Count -gt 0){
                $Params = @{
                    'Index' = 'log_ps_example'
                    'OpType' = 'Create'
                    'Logs' = $LogList
                    'ErrorAction' = 'Continue'
                }
                Add-OSLogPSBulk @Params
            }
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Index,

        [Parameter(Mandatory)]
        [System.Collections.Generic.List[Hashtable]]$Logs,

        [switch]$DisableLocalLog,

        [string]$LogFile,

        [ValidateSet('','create','delete','index','update')]
        [string]$OpType,

        [Int64]$UploadLimit=4999,

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

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

    $FieldNames = @{}

    foreach ($LogEntry in $Logs){
        # Validate data
        if ($LogEntry.LogLevel -notin @('Trace', 'Verbose', 'Information', 'Warning', 'Error', 'Critical')){
            throw "LogLevel must be one of the following options: Trace, Verbose, Information, Warning, Error, Critical`nYour provided level: $($LogEntry.LogLevel)"
        }
        if ($null -eq $LogEntry.'@timestamp'){
            throw "Each log must have a key named '@timestamp' with the value being the timestamp"
        }

        foreach ($key in $LogEntry.Keys){
            if ($key -ne '@timestamp' -and
            $key -ne 'LogLevel'){
                $FieldNames.$key = 'value'
            }
        }

        # Add auto generated fields
        $LogEntry.'Hostname' = $env:COMPUTERNAME
        $LogEntry.'PoSH.Script' = $ScriptName
        $LogEntry.'@timestamp' = $(Get-Date)
    }

    # Validate fild naming standard
    Confirm-OSFieldNamingStandard -FieldNames $FieldNames

    $Logs = $Logs.ToArray()

    # Add log content to local log file
    if ($False -eq $DisableLocalLog){
        if (-not (Test-Path $LogFile)){
            # Redirect to $null, otherwise if there's no other return response it returns the Path object to the log
            New-Item -Path $LogFile -Force > $null
            $LogEntries = $Logs
        }
        else {
            [Array]$LogEntries = Get-Content $LogFile | ConvertFrom-Json -Depth 100
            $LogEntries += $Logs
        }

        $LogEntries | ConvertTo-Json -Depth 100 -AsArray | Out-File -FilePath $LogFile
    }

    $Response = Import-OSAllBulkDocument -Index $Index -Documents $Logs -OpType $OpType -UploadLimit $UploadLimit -Credential $Credential -Certificate $Certificate -OpenSearchURL $OpenSearchURL

    if ($Response -eq $true -or
    $null -eq $Response){
        return
    }
    else {
        throw $Response
    }

}

Export-ModuleMember -Function Add-OSLogPSBulk
