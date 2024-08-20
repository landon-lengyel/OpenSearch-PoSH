BeforeAll {
    Import-Module "./OpenSearch-PoSH/OpenSearch-PoSH.psd1" -Force

    # Variables
    $Index = 'Get-OSClusterHealth-TestIndex'
    $Index2 = 'Get-OSClusterHealth2-TestIndex'
    $RecordCount = 100

    # Add test data
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
        [void]$Documents.Add($Document)
    }

    $Documents = $Documents.ToArray()

    Import-OSAllBulkDocument -Index $Index -Documents $Documents -OpType 'create' > $null
    Import-OSAllBulkDocument -Index $Index2 -Documents $Documents -OpType 'create' > $null

}

Describe 'Get-OSClusterHealth' {
    It 'Returns health status as a PowerShell object' {
        $Health = Get-OSClusterHealth

        $Health.GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject'

        $Health.status | Should -BeIn @('green','yellow','red')
    }

    #region Filter to Index
    It 'Can filter to just one index' {
        $Health = Get-OSClusterHealth -Index $Index

        $Health.status | Should -BeIn @('green','yellow','red')
        $Health.active_primary_shards | Should -Be 1 -Because 'filtering to one index should have one primary shard'
    }

    It 'Can filter to a few indices' {
        $Health = Get-OSClusterHealth -Index @($Index,$Index2)

        $Health.status | Should -BeIn @('green','yellow','red')
        $Health.active_primary_shards | Should -Be 2 -Because 'filtering to two indices should have two primary shards'

    }

    It 'Can expand wildcards' {
        $Health = Get-OSClusterHealth -Index '*TestIndex' -ExpandWildcards open

        $Health.status | Should -BeIn @('green','yellow','red')
        # Allowing greater than since there may be more that match the wildcard
        $Health.active_primary_shards | Should -BeGreaterOrEqual 2 -Because 'filtering to two indices should have two primary shards'
    }

    It 'Can not expand wildcards' {
        $Health = Get-OSClusterHealth -Index '*TestIndex' -ExpandWildcards none

        $Health.status | Should -BeIn @('green','yellow','red')
        # Allowing greater than since there may be more that match the wildcard
        $Health.active_primary_shards | Should -Be 0 -Because 'wildcards are disabled and no indices are returned'
    }
    #endregion
}

AfterAll {
    Remove-OSIndex -Index $Index -NoConfirm
    Remove-OSIndex -Index $Index2 -NoConfirm
}
