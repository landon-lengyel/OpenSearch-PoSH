# Import Module
try {
    Import-Module './OpenSearch.psd1' -Force
}
catch [System.Management.Automation.ScriptRequiresException] {
    Add-Content -Path "ERROR IMPORTING OPENSEARCH MODULE.txt" -Value "Script *must* be run with PowerShell 7 (pwsh.exe)"
    throw $_
}

## Setup other test
function Add-TestData {
    $Index = 'test-index'
    $RecordCount = 50000

    $Documents = [System.Collections.Generic.List[hashtable]]::new()
    for ($Record = 1; $Record -le $RecordCount; $Record++) {
        $Document = @{
            'Record Counter' = $Record
            'Property 1'     = 'Value1'
            'Object 1'       = @{
                'Property 2'   = 'Value 2'
                'The Number 3' = 3
            }
        }
        $Documents.Add($Document)
    }

    $Documents = $Documents.ToArray()

    $Request = @{
        'Index' = $Index
        'Documents' = $Documents
        'OpType'    = 'create'     # Necessary for data streams
    }
    $Response = Import-OSAllBulkDocument @Request

    Write-Output $Response
}

## Single function tests
function Test-Add-OSLogPS {
    #Measure-Command {
    Write-Output "Testing with valid field names..."
    for ($i = 0; $i -lt 100; $i++) {
        Write-Output "Iteration: #$i"
        # Test even values without additional attributes
        if (0 -eq $i % 2) {
            $Request = @{
                'Index' = 'log_ps_test_xx55000109EDDO004'
                'LogLevel'  = 'Information'
                'Message'   = "This is my log. Iteration $i"
                #'ErrorAction' = 'break'
                #'LogFile' = './MyPath/ThisIsALog.json'
                #'DocumentID' = $i
            }
            Add-OSLogPS @Request
        }
        # Test odd values with additional attributes
        else {
            $Request = @{
                'Index'              = 'log_ps_test_xx55000109EDDO004'
                'LogLevel'               = 'Information'
                'Message'                = "This is my log. Iteration $i"
                'AD.SamAccountName'      = 'MyNewAccountName'
                'AD.SamAccountName-From' = 'MyOldAccountName'
                'Api.Method'             = 'GET'
                #'ErrorAction' = 'break'
                #'LogFile' = './MyPath/ThisIsALog.json'
                #'ImNotAnAcceptedName' = 'Value' # Should throw terminating with this and IgnoreError = $False
                #'DocumentID' = $i
            }
            Add-OSLogPS @Request
        }
    }

    Write-Output "Testing with invalid field name..."
    # Should throw terminating with this and IgnoreError = $False
    $Request = @{
        'Index'              = 'log_ps_test_xx55000109EDDO004'
        'LogLevel'               = 'Information'
        'Message'                = "This is my log. Iteration $i"
        'AD.SamAccountName'      = 'MyNewAccountName'
        'AD.SamAccountName-From' = 'MyOldAccountName'
        'Api.Method'             = 'GET'
        #'ErrorAction' = 'break'
        #'LogFile' = './MyPath/ThisIsALog.json'
        'ImNotAnAcceptedName'    = 'Value' 
        #'DocumentID' = $i
    }
    Add-OSLogPS @Request
    #}
}
function Test-Find-OSLogPS {
    $Request = @{
        'Index'         = 'log_ps_test_xx55000109EDDO004'
        'LogLevel'          = 'Information'
        'Message'           = "This is my log"
        'ExecutionScript'   = 'Test.ps1'
        'ExecutionHostname' = '55000109EDDO004'
        'Size'              = 20
        'Explain'           = $True
        'Preference'        = '_replica'
        'Api.Method'        = 'GET'
    }

    $Response = Find-OSLogPS @Request

    Write-Output $Response.hits.hits
    Write-Output 'Returned hits: ' $Response.hits.hits.Count
    Write-Output 'Total hits: ' $Response.hits.total.value

}
function Test-Get-OSNode {
    $Request = @{
        'FullId'  = $True
        #'VerboseResponse' = $False
        'Headers' = @('name', 'load_1m', 'load_5m', 'load_15m')
        'Format'  = 'PlainText'
    }

    $Response = Get-OSNode @Request

    Write-Output $Response
}
function Test-Find-OSIndexPatternID {
    $Request = @{
        'IndexPatternName' = 'log_ps_*'
        #'DashboardsIndexName' = '.opensearchdashboards'
    }

    $Response = Find-OSIndexPatternId @Request
    Write-Output $Response
}
function Test-Find-OSVisualizationsById {
    $Request = @{
        'IndexPatternName' = 'log_win_microsoft-windows-security-auditing'
        #'DashboardsIndexName' = '.opensearchdashboards'
    }

    $Id = Find-OSIndexPatternId @Request
    Write-Output $Id

    $Request = @{
        'DashboardsIndexId' = $Id
        #'DashboardsIndexName' = '.opensearchdashboards'
    }

    $Response = Find-OSVisualizationsById @Request
    Write-Output $Response.hits.hits
}
function Test-Confirm-OSIndexExist {
    $Request = @{
        'Index'       = 'log_*'
        #'Index' = 'lsjfosifeosei8387h98q3h'
        'ExpandWildcards' = 'none'
    }
    $Response = Confirm-OSIndexExist @Request
    Write-Host $Response
}
function Test-Get-OSIndex {
    $Request = @{
        #'Index' = @('test-index','log_win_*')
        'Index' = 'log_ps_*'
        'PrimaryOnly'       = $True
        'ExpandWildcards'   = 'all'
        #'VerboseResponse' = $False
        'Headers'           = @('index', 'store.size')
        'Format'            = 'Plaintext'
    }
    $Response = Get-OSIndex @Request
    #$Response | Out-File test-output.txt
    Write-Output $Response
}
function Test-Get-OSIngestPipeline {
    $Response = Get-OSIngestPipeline
    Write-Output $Response
}
function Test-New-OSIngestPipeline {
    $IngestProcessors = @{
        'rename' = @{
            'field'        = 'mytestfield'
            'target_field' = 'myrenamedtestfield'
        }
    }
    $Request = @{
        'PipelineName'        = 'test-pipeline'
        'PipelineDescription' = 'Testing the OpenSearch PowerShell module'
        'PipelineProcessors'  = $IngestProcessors
    }
    $Response = New-OSIngestPipeline @Request
    Write-Host $Response.StatusCode
}
function Test-Remove-OSIngestPipeline {
    $Request = @{
        'PipelineName' = 'test-pipeline'
    }
    $Response = Remove-OSIngestPipeline @Request
    Write-Output $Response
}
function Test-Invoke-OSReIndex {
    Add-TestData

    Write-Output 'Beginning re-index operation, this may take some time...'

    $SourceQuery = @{
        'query' = @{
            'match' = @{
                'First Name' = 'Daisy'
            }
        }
    }

    $Request = @{
        'SourceIndex'       = 'test-index'
        'DestinationIndex'  = 'test-index2'
        'WaitForCompletion' = $True
        #'SourceQuery' = $SourceQuery
        'MaxDocs'           = 400000
        'Slices'            = 'auto'
        #'RequestsPerSecond' = 20    # 20 is extremely limiting
        #'OpType' = 'index'
        #'IngestPipeline' = 'temprenamefields-test-index'
    }
    $Response = Invoke-OSReIndex @Request
    
    # Returns Task Id if WaitForCompletion is $false
    Write-Output "Re-indexed $($Response.total) total documents"

    Write-Output "Removing index: $($Request.DestinationIndex)"
    Remove-OSIndex -Index $Request.DestinationIndex 
}
function Test-Get-OSTask {
    $Request = @{
        #'TaskId' = 'K6NsRdEvTO-e7oDmBgAUgA:8034191'
        #'Nodes' = ''
        #'Actions' = ''
        'Detailed' = $True
        #'ParentTaskId' = ''
        #'WaitForCompletion' = $True
    }

    $Response = Get-OSTask @Request

    Write-Output $Response.task
}
function Test-Get-OSAlias {
    $Request = @{
        'AliasNames' = @('log_*')
        'ExpandWildcards'   = 'all'
        #'VerboseResponse' = $False
        #'Headers'           = @('index', 'store.size')
        #'Format'            = 'Plaintext'
    }
    $Response = Get-OSAlias @Request

    Write-Output $Response
}
<#
function Test-OSIndexIsmPolicy {
    Add-TestData

    Write-Output 'Testing adding a policy...'
    $Request = @{
        'Index' = 'test-index'
        'PolicyName' = 'test-ism-policy'
    }

    $Response = Add-OSIndexIsmPolicy @Request
    Write-Output $Response

    Write-Output 'Testing updating an an index poilcy...'
    $Request = @{
        'Index' = 'test-index'
        'PolicyName' = 'test-ism-policy'
        #'IfState' = ''
        #'NewState' = ''
    }

    $Response = Update-OSIndexIsmPolicy @Request
    Write-Output $Response

    Write-Output 'Testing removing policy from index...'
    $Request = @{
        'Index' = 'test-index'
    }

    $Response = Remove-OSIndexIsmPolicy @Request
    Write-Output $Response

    Remove-OSIndex -Index 'test-index' -NoConfirm
}
#>
function Test-Initialize-OSIndex {
    $Fields = @{
        "MyField" = "text"
        "MyField2" = "integer"
    }

    $Request = @{
        'Index' = 'test-index-initialize'
        'DataTypes' = $Fields
    }

    $Response = Initialize-OSIndex @Request

    if ($Response -eq $True){
        Write-Output "Index initialized successfully"
        Write-Output "Removing test index: $($Request.Index)"

        Remove-OSIndex -Index $Request.Index
    }
}
function Test-Remove-OSIndex {
    $Request = @{
        'Index' = 'test-index'
        #'NoConfirm' = $True
    }

    $Response = Remove-OSIndex @Request

    Write-Output $Response
}
function Test-Import-OSDocument {
    $Document = @{
        '@timestamp'        = Get-Date
        'Property1'         = 'This is my cool document! Wow!'
        'Property2'         = 'I do not like Property2 as much'
        'Integer'           = 1234
        'IPAddress'         = '192.168.1.1'
        'BadPropertyName'   = 'data'
        'Obj1.SubProperty1' = 'hello'
        'Obj1.SubProperty2' = 'hello2'
    }

    $Request = @{
        'Index' = 'test-index'
        'Document'  = $Document
    }

    $Response = Import-OSDocument @Request

    Write-Host $Response
}
function Test-Initialize-OSDataStream {
    $Request = @{
        'DataStreamName' = 'test-index'
    }

    $Response = Initialize-OSDataStream @Request

    Write-Output $Response
}
function Test-Get-OSDataStream {
    $Request = @{
        'DataStreamName' = 'log_ps_*'
        #'Format' = 'YAML'
    }
    $Response = Get-OSDataStream @Request

    Write-Host $Response
}
function Test-Remove-OSDataStream {
    $Request = @{
        'DataStreamName' = 'test-index'
    }

    $Response = Remove-OSDataStream @Request

    Write-Output $Response
}
function Test-Get-OSIndexSetting {
    $Request = @{
        'Index' = 'test-index'
    }

    $Response = Get-OSIndexSetting @Request

    Write-Output $Response | ConvertTo-Json -Depth 100
}
function Test-Get-OSIndexCount {
    
    $Query = @{
        'exists' = @{
            'field' = 'Record Counter'
        }
    } | ConvertTo-Json -Depth 100

    $Request = @{
        'Index'      = 'test-index'
        #'Query' = $Query
        #'Analyzer' = ''
        #'AnalyzeWildcards' = $True
        #'DefaultOperator' = 'AND'
        #'DefaultField' = ''
        'IgnoreUnavailable' = $True
        #'Lenient' = $True
        #'MinScore' = 50
        #'Routing' = ''
        #'Preference' = ''
        'TerminateAfter' = '1000000'
    }

    $Response = Get-OSIndexCount @Request

    Write-Output $Response
}
function Test-Import-OSUniqueBulkDocument {
    $InitialSize = Get-OSIndexCount -Index 'test-index' -ErrorAction SilentlyContinue
    
    $TestData = Import-Csv -Path './Testing/Test-Bulk-100000.csv'

    Write-Output 'Testing 100,000 documents...'
    Measure-Command {
        $Request = @{
            'Index' = 'test-index'
            'Documents' = $TestData
            #'UploadLimit' = 3000
            #'OpType' = 'create'
        }
        $Response = Import-OSUniqueBulkDocument @Request
    }
    Write-Output 'Complete'

    $TestData = Import-Csv -Path './Testing/Test-Bulk-418.csv'
    Write-Output 'Testing 418 documents...'
    Measure-Command {
        $Request = @{
            'Index' = 'test-index'
            'Documents' = $TestData
            #'UploadLimit' = 3000
            #'OpType' = 'create'
        }
        $Response = Import-OSUniqueBulkDocument @Request
    }

    Start-Sleep -Seconds 3     # Wait a few seconds for it to appear with correct document count in OpenSearch
    $Request = @{
        'Index' = 'test-index'
    }
    $DocumentCount = Get-OSIndexCount @Request

    if ($DocumentCount.count -eq (100418 + $InitialSize.count)) {
        Write-Output 'Expected 100418 documents, got 100418 documents. Removing: test-index'

        # Delete the test index
        $Request = @{
            'Index' = 'test-index'
        }
        $Result = Remove-OSIndex @Request
    }
    else {
        throw "Bulk upload test failed. See: test-index"
    }

    Write-Output "Testing duplicate documents handling..."
    # Run it through twice, same data, just re-organized. It should not add the duplicate document.
    $TestData = @{
        'AAAA' = 'MyVal'
        'BBBB' = 'MyVal2'
        'CCCC' = 'MyVal3'
    }
    $Request = @{
        'Index' = 'test-index-duplicate'
        'Documents' = $TestData
        #'UploadLimit' = 3000
        #'OpType' = 'create'
    }
    $Response = Import-OSUniqueBulkDocument @Request

    $TestData = @{
        'BBBB' = 'MyVal2'
        'CCCC' = 'MyVal3'
        'AAAA' = 'MyVal'
    }
    $Request = @{
        'Index' = 'test-index-duplicate'
        'Documents' = $TestData
        #'UploadLimit' = 3000
        #'OpType' = 'create'
    }
    $Response = Import-OSUniqueBulkDocument @Request

    Start-Sleep -Seconds 3     # Wait a few seconds for it to appear in OpenSearch
    $Request = @{
        'Index' = 'test-index-duplicate'
    }
    $DocumentCount = Get-OSIndexCount @Request

    if ($DocumentCount.count -eq 1) {
        Write-Output 'Expected 1 document, got 1 document. Removing: test-index-duplicate'

        # Delete the test index
        $Request = @{
            'Index' = 'test-index-duplicate'
        }
        $Result = Remove-OSIndex @Request
    }
    else {
        throw "Duplicate document upload test failed. See: test-index-duplicate"
    }

    Write-Output 'Complete'
}
function Test-Import-OSAllBulkDocument {
    $InitialSize = Get-OSIndexCount -Index 'test-index' -ErrorAction SilentlyContinue
    $TestData = Import-Csv -Path './Testing/Test-Bulk-100000.csv'

    Write-Output 'Testing 100,000 documents...'
    Measure-Command {
        $Request = @{
            'Index' = 'test-index'
            'Documents' = $TestData
            #'UploadLimit' = 3000
            #'OpType' = 'create'
        }
        $Response = Import-OSAllBulkDocument @Request
    }
    Write-Output 'Complete'

    $TestData = Import-Csv -Path './Testing/Test-Bulk-418.csv'
    Write-Output 'Testing 418 documents...'
    Measure-Command {
        $Request = @{
            'Index' = 'test-index'
            'Documents' = $TestData
            #'UploadLimit' = 3000
            #'OpType' = 'create'
        }
        $Response = Import-OSAllBulkDocument @Request
    }

    Start-Sleep -Seconds 3     # Wait a few seconds for it to appear with correct document count in OpenSearch
    $Request = @{
        'Index' = 'test-index'
    }
    $DocumentCount = Get-OSIndexCount @Request

    if ($DocumentCount.count -eq (100418 + $InitialSize.count)) {
        Write-Output 'Expected 100418 documents, got 100418 documents. Removing: test-index'

        # Delete the test index
        $Request = @{
            'Index' = 'test-index'
        }
        $Result = Remove-OSIndex @Request
    }
    else {
        throw "Bulk upload test failed. See: test-index"
    }
}
function Test-Get-OSShardRecovery {
    $Indices = @('log_win_microsoft-windows-security-auditing', 'log_ps_misc')

    $Request = @{
        'Index' = $Indices
        'VerboseResponse'   = $False
        'ActiveOnly'        = $False
        #'Format' = 'PlainText'
    }

    $Response = Get-OSShardRecovery @Request

    Write-Output $Response
}
function Test-Get-OSShard {
    $Request = @{
        'Index' = @('log_win_microsoft-windows-security-auditing', 'log_ps_misc')
        #'VerboseResponse' = $False
        'Headers'           = @('index', 'node', 'shard', 'prirep', 'state')
        #'UnassignedHeaders' = $True
        'Format'            = 'PlainText'
    }

    $Response = Get-OSShard @Request

    Write-Output $Response
}
function Test-Get-OSStorageAllocation {
    $Request = @{
        'NodeName' = 'osc01n01'
        #'VerboseResponse' = $False
        'Headers'  = @('disk.used', 'disk.avail', 'host')
        'Format'   = 'PlainText'
    }

    $Response = Get-OSStorageAllocation @Request

    Write-Output $Response
}
function Test-Get-OSClusterHealth {
    $Request = @{
        #'Index' = '.ds-log_ps_misc*'
        #'ExpandWildcards' = 'all'
        #'Level' = 'indices'
        #'AwarenessAttribute' = ''
        #'LocalNodeOnly' = $True
        #'ClusterManagerTimeout' = 60
        #'Timeout' = 60
        #'WaitForActiveShards' = 1
        #'WaitForAllActiveShards' = $True
        #'WaitForNodes' = '>3'
        #'WaitForEvents' = 'high'
        #'WaitForNoRelocatingShards' = $True
        #'WaitForNoInitializingShards' = $True
        #'WaitForStatus = 'green'
        #'Weights' = ''
    }

    $Response = Get-OSClusterHealth @Request

    Write-Output $Response
}
function Test-Start-OpenSearchClusterShardReroute {
    $Request = @{
        'Explain'     = $False
        'RetryFailed' = $False
    }

    $Response = Start-OSClusterShardReroute

    Write-Output $Response
}
function Test-Find-OS {
    $MyQuery = @{
        "match" = @{
            "LogLevel" = "Error"
        }
    }

    $MyJsonQuery = '{
        "match": {
            "LogLevel": "Information"
        }
      }'

    $Request = @{
        # --- URL Parameters ---
        'Index'                 = 'log_ps_test_xx55000109eddo004'
        'AllowNoIndices'            = $False
        'AllowPartialSearchResults' = $True
        #'Analyzer' = ''
        #'AnalyzeWildcards' = $True    # No longer supported?
        'BatchedReduceSize'         = 100
        'CancelAfterSeconds'        = 60
        'CcsMinimizeRoundtrips'     = $False
        #'DefaultOperator' = 'AND'     # No longer supported?
        #'DefaultField' = ''
        'ExpandWildcards'           = 'all'
        'IgnoreThrottled'           = $False
        'IgnoreUnavailable'         = $True
        #'Lenient' = $True     # No longer supported?
        'MaxConcurrentShardRequest' = 1
        'PhaseTook'                 = $True
        'PreFilterShardSize'        = 100
        #'Preference' = ''
        #'LuceneQuery' = ''
        'RequestCache'              = $True
        'RestTotalHitsAsInteger'    = $True
        #'ScrollSeconds' = 60
        'SearchType'                = 'dfs_query_then_fetch'
        'NoSource'                  = $True
        #'SourceExcludes' = @('')
        #'SourceIncludes' = @('')
        'StoredFields'              = $True
        #'SuggestFields' = @('')
        #'SuggestMode' = 'popular'    # No longer supported?
        #'SuggestCount' = 5      # No longer supported?
        #'SuggestText' = ''
        'TrackScores'               = $True
        'TrackTotalHits'            = $True    # Boolean or integer
        'TypedKeys'                 = $False
        'IncludeNamedQueriesScore'  = $True
        # --- Body Parameters ---
        #'Aggregations' = ''
        #'DocValueFields' = ''
        #'Fields' = ''
        'Explain'                   = $True
        'FromIndex'                 = 1
        #'BoostIndices' = @('')
        #'MinScore' = 0
        'DslQuery'                  = $MyQuery
        #'DslQueryJson' = $MyJsonQuery
        'SeqNoPrimaryTerm'          = $True
        'Size'                      = 20
        #'Stats' = 'MySearch'
        'TerminateAfter'            = 10
        #'Timeout' = ''
        'Version'                   = $True
    }

    $Response = Find-OS @Request

    Write-Output $Response
}
function Test-Update-OSIsmPolicy {
    $Request = @{
        'Index' = 'test-ism-policy'
        #'PolicyName' = ''
        #'IfState' = ''
        #'NewState' = ''
    }

    $Response = Update-OSIsmPolicy @Request

    Write-Output $Response
}
function Test-Get-OSIsmPolicyContent {
    $Request = @{
        'PolicyName' = 'test-ism-policy'
        #'FullResponse' = $True
    }

    $Response = Get-OSIsmPolicyContent @Request

    Write-Output $Response
}
function Test-Copy-OSIsmPolicy {
    # (optionally) Test the AdvancedIndexPatterns Option
    $AdvancedIndexPatterns = [System.Collections.Generic.List[Pscustomobject]]::new()

    $IndividualIndexPatterns = New-Object -TypeName pscustomobject
    $IndividualIndexPatterns | Add-Member -Name 'index_patterns' -Type NoteProperty -Value @('test-index')
    $IndividualIndexPatterns | Add-Member -Name 'priority' -Type NoteProperty -Value 1
    $AdvancedIndexPatterns.Add($IndividualIndexPatterns)

    $IndividualIndexPatterns = New-Object -TypeName pscustomobject
    $IndividualIndexPatterns | Add-Member -Name 'index_patterns' -Type NoteProperty -Value @('test-index-2')
    $IndividualIndexPatterns | Add-Member -Name 'priority' -Type NoteProperty -Value 2
    $AdvancedIndexPatterns.Add($IndividualIndexPatterns)
    
    $AdvancedIndexPatterns = $AdvancedIndexPatterns.ToArray()

    $Request = @{
        'PolicyName' = 'test-ism-policy'
        'NewPolicyName' = 'test-ism-policy-COPY'
        'NewIndexPatterns' = @('test-index', 'test-index-2')
        #'NewAdvancedIndexPatterns' = $AdvancedIndexPatterns
    }

    $Response = Copy-OSIsmPolicy @Request

    Write-Output $Response
}
function Test-Get-OSPerformanceAnalyzerStatus {
    $Request = @{
        #'OpenSearchURL' = 'https://osc01n03.slcsd.net:9200'    # Response can be inconsistent depending on nodes settings.
        #'VerboseResponse' = $false
    }

    $Response = Get-OSPerformanceAnalyzerStatus @Request

    Write-Output $Response
}
function Test-Enable-OSPerformanceAnalyzer {
    $Request = @{
        'RcaFramework' = $True
        #'VerboseResponse' = $false
    }

    $Response = Enable-OSPerformanceAnalyzer @Request

    Write-Output $Response
}
function Test-Disable-OSPerformanceAnalyzer {
    $Request = @{
        'VerboseResponse' = $false
    }

    $Response = Disable-OSPerformanceAnalyzer @Request

    Write-Output $Response
}
function Test-Get-OSNodeProperties {
    $Attributes = @{
        'temp' = 'warm'
        'type' = 'physical'
    }

    $Request = @{
        #'LocalNodeOnly' = $true
        #'ClusterManagerNodeOnly' = $true
        #'AllNode' = $true
        #'NodeName' = 'osc01n01'
        #'NodeIp' = '205.127.*'
        #'NodeId' = '7SUVkFVyTpCXLmpO_-QQpw'
        'NodeAttribute' = $Attributes
        #'CustomNodeFilter' = 'ingest:true'
    }

    $Response = Get-OSNodeProperties @Request

    Write-Output $Response
}

## Multi function tests
function Test-TaskStartStop {
    $SourceIndex = 'log_win_microsoft-windows-security-auditing'
    $DestinationIndex = 'test-index_test-taskstartstop'

    Write-Output 'Beginning re-index operation, this may take some time...'
    $Request = @{
        'SourceIndex'      = $SourceIndex
        'DestinationIndex' = $DestinationIndex
        #'WaitForCompletion' = $True
        #'SourceQuery' = $SourceQuery
        'MaxDocs'          = 4000000
        'Slices'           = 'auto'
        #'RequestsPerSecond' = 20    # 20 is extremely limiting
        #'OpType' = 'index'
    }
    $ReIndex = Invoke-OSReIndex @Request
    Write-Output "Task ID: $($ReIndex.Task)"
    
    Start-Sleep -Seconds 3

    Write-Output 'Getting task information...'
    $Request = @{
        'TaskId' = $ReIndex.task
        #'Nodes' = ''
        #'Actions' = ''
        #'Detailed' = $True
        #'ParentTaskId' = ''
        #'WaitForCompletion' = $True
    }
    $Task = Get-OSTask @Request
    Write-Output "Task description: $($Task.task.description)"

    Write-Output 'Killing re-index task...'
    $Request = @{
        'TaskId' = $Task.task.node + ':' + $Task.task.id
        #'Nodes' = ''
        #'Actions' = ''
        #'Detailed' = $True
        #'ParentTaskId' = ''
        #'WaitForCompletion' = $True
    }
    $TaskKill = Stop-OSTask @Request
    if ($TaskKill.nodes.$($Task.task.node).tasks.$($Task.task.node + ':' + $Task.task.id).cancelled -eq 'True') {
        Write-Output 'Task successfully stopped!'
    }
    else {
        Write-Output 'Task was not successfully stopped. Did it finish too fast?'
    }

    Write-Output "Removing temp index..."
    $Request = @{
        'Index' = $DestinationIndex
    }

    $Response = Remove-OSIndex @Request
}
function Test-DisableEnable-OSIndexWrite {
    $Index = 'test-index'

    $Request = @{
        'Index'   = $Index
        'AllowDelete' = $True
    }
    $DisableResponse = Disable-OSIndexWrite @Request

    if ($DisableResponse -ne $True){
        Write-Output "Error occurred disabling write actions."
        exit
    }
    
    $Settings = Get-OSIndexSetting -Index $Index
    Write-Output $Settings.$Index.settings.index.blocks | ConvertTo-Json

    $Request = @{
        'Index' = $Index
    }
    $EnableResponse = Enable-OSIndexWrite @Request
    
    if ($EnableResponse -eq $True){
        Write-Output "Index writes successfully blocked and un-blocked."
    }
}
function Test-Get-OSClusterShardAllocation {
    $Request = @{
        'Index' = @('log_ps_misc')
        #'VerboseResponse' = $False
        'Headers'           = @('index', 'node', 'shard', 'prirep', 'state', 'unassigned.reason')
        #'Format' = 'JSON'
    }

    $Shards = Get-OSShard @Request

    $Request = @{
        'Index'   = $Shards[0].index
        #'IncludeYesDecisions' = $True
        #'IncludeDiskInfo' = $True
        'CurrentNode' = $Shards[0].node
        'ShardId'     = $Shards[0].shard
    }
    if ($Shards[0].prirep -eq 'r') {
        $Request.Primary = $False
    }
    elseif ($Shards[0].prirep -eq 'p') {
        $Reequest.Primary = $True
    }

    $Response = Get-OSClusterShardAllocation @Request

    Write-Output $Response
}

# Setup other tests
#Add-TestData

# Single function tests
#Test-Add-OSLogPS
#Test-Find-OSLogPS
#Test-Get-OSNode
#Test-Find-OSIndexPatternID
#Test-Find-OSVisualizationsById
#Test-Confirm-OSIndexExist
#Test-Get-OSIndex
#Test-Get-OSIngestPipeline
#Test-New-OSIngestPipeline
#Test-Remove-OSIngestPipeline
#Test-Invoke-OSReIndex
#Test-Get-OSTask
#Test-Get-OSAlias
#Test-Initialize-OSIndex
#Test-Remove-OSIndex
#Test-Import-OSDocument
#Test-Initialize-OSDataStream
#Test-Get-OSDataStream
#Test-Get-OSIndexSetting
#Test-Get-OSIndexCount
#Test-Import-OSUniqueBulkDocument
#Test-Import-OSAllBulkDocument
#Test-Get-OSShardRecovery
#Test-Get-OSShard
#Test-Get-OSStorageAllocation
#Test-Get-OSClusterHealth
#Test-Start-OSClusterShardReroute
#Test-Find-OS
#Test-Update-OSIsmPolicy
#Test-Get-OSIsmPolicyContent
#Test-Copy-OSIsmPolicy
#Test-Get-OSPerformanceAnalyzerStatus
#Test-Enable-OSPerformanceAnalyzer
#Test-Disable-OSPerformanceAnalyzer
#Test-Get-OSNodeProperties

# Multi function tests
#Test-TaskStartStop
#Test-DisableEnable-OSIndexWrite
#Test-Get-ClusterShardAllocation
#Test-OSIndexIsmPolicy


# Run this to test /Private functions in the terminal. Otherwise any additional helper functions won't be loaded
$PrivateFunctions = Get-ChildItem '.\Private\'
Foreach ($PrivateFunction in $PrivateFunctions){
    . $PrivateFunction
}
