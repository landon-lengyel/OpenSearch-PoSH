BeforeAll {
    $IndexName = 'OSIngestPipeline-TestIndex'

    Import-Module "./src/OpenSearch.psd1" -Force
}

Describe 'OSIngestPipeline related functions' {
    It 'Creates ingest pipelines' {
        $IngestProcessors = @{
            'rename' = @{
                'field'        = 'mytestfield'
                'target_field' = 'myrenamedtestfield'
            }
        }

        New-OSIngestPipeline -PipelineName 'test-pipeline' -PipelineDescription 'Testing the PowerShell module' -PipelineProcessors $IngestProcessors | Should -BeNullOrEmpty -Because 'No response means success'

        Start-Sleep -Seconds 1     # Give time for pipeline to create before moving on
    }

    It 'Verifies index pipeline exists' {
        $Pipelines = Get-OSIngestPipeline

        $Pipelines.'test-pipeline'.description | Should -Be 'Testing the PowerShell module' -Because 'Description is set'
        $Pipelines.'test-pipeline'.processors[0].rename.field | Should -Be 'mytestfield' -Because 'Field is set'
        $Pipelines.'test-pipeline'.processors[0].rename.target_field | Should -Be 'myrenamedtestfield' -Because 'Target field is set'
    }

    #It 'Pipeline is functional' {
    #    $Document = @{
    #        'mytestfield' = 'MyValue'
    #        'myotherfield' = 'MyOtherValue'
    #    }
    #    Import-OSDocument -Index $IndexName -Document $Document

    #    # TODO: Need to update this function to use it here
    #    Initialize-OSIndexBeta -Index "$IndexName-2"

    #    Start-Sleep -Seconds 1    # Wait for indexing to complete

    #    Invoke-OSReIndex -SourceIndex $IndexName -DestinationIndex "$IndexName-2" -IngestPipeline 'test-pipeline'

    #    $Documents = Find-OS -Index "$IndexName-2"
    #    # TODO: Add verification on next line
    #    $Documents.hits.hits._source
    #}

    It 'Removese index pipeline' {
        Remove-OSIngestPipeline -PipelineName 'test-pipeline' | Should -BeNullOrEmpty -Because 'No response means success'
    }
}

AfterAll {
    Remove-OSIndex -Index $IndexName -NoConfirm
}
