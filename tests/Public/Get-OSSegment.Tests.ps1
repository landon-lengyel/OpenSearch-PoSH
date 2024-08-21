BeforeAll {
    $IndexName = 'Get-OSSegment-TestIndex'

    Import-Module "./OpenSearch-PoSH/OpenSearch-PoSH.psd1" -Force

    Import-OSDocument -Index $IndexName -Document @{'MyField' = 'MyValue'}
    Start-Sleep -Seconds 1    # Creation can be a little slower than is needed
}

Describe 'Get-OSSegment' {
    It 'Can list default segments' {
        $Shards = Get-OSSegment

        $Shards.GetType().BaseType.FullName | Should -Be 'System.Array' -Because 'Returns array of shards'
        $Shards.index | Should -Contain '.plugins-ml-config' -Because 'Built in index is returned'
    }

    It 'Can list added segments' {
        $Shards = Get-OSSegment

        $Shards.GetType().BaseType.FullName | Should -Be 'System.Array' -Because 'Returns array of shards'
        $Shards.index | Should -Contain $IndexName -Because 'Test index is returned - and lowercased'
        ($Shards | Where-Object { $_.index -eq $IndexName }).'docs.count' | Should -BeGreaterThan 0 -Because 'Documents were added'
    }

    It 'Can filter to specific index' {
        $Shards = Get-OSSegment -Index $IndexName

        $Shards | Should -ExpectedType 'System.Management.Automation.PSCustomObject'
        $Shards.'docs.count' | Should -BeGreaterThan 0 -Because 'Documents were added'
    }

    It 'Can list specific headers' {
        $Shards = Get-OSSegment -Headers @('index')

        $Shards.GetType().BaseType.FullName | Should -Be 'System.Array' -Because 'Returns array of shards'
        $Shards.index | Should -Contain $IndexName -Because 'Test index is returned - and lowercased'
        ($Shards | Where-Object { $_.index -eq $IndexName }).PSObject.Properties.Count | Should -Be 1 -Because 'Filtered headers to just one value'
    }

    #region Format
    It 'Can format as JSON' {
        $Shards = Get-OSSegment -Format 'JSON'

        $Shards.GetType().FullName | Should -Be 'System.String' -Because 'JSON format appears as strings'
        $Shards | ConvertFrom-Json | Should -ExpectedType 'System.Management.Automation.PSCustomObject' -Because 'JSON should be valid'
    }

    It 'Can format as YAML' {
        $Shards = Get-OSSegment -Format 'YAML'

        $Shards.GetType().FullName | Should -Be 'System.String' -Because 'YAML format appears as strings'

        $Shards | Should -BeLike '---*' -Because 'First YAML line is three dashes'
        $Shards | Should -BeLike "*- index: `"$IndexName`"*" -Because 'YAML returns indices'
    }

    It 'Can format as CBOR' {
        $Shards = Get-OSSegment -Format 'CBOR'

        $Shards.GetType().FullName | Should -Be 'System.String' -Because 'CBOR format appears as strings'
        $Shards | Should -BeLike '??eindex*' -Because 'CBOR starts with ?? then adds content'
    }

    It 'Can format as Smile' {
        $Shards = Get-OSSegment -Format 'Smile'

        $Shards.GetType().FullName | Should -Be 'System.String' -Because 'Smile format appears as strings'
        $Shards | Should -BeLike ":)`n.???index*" -Because 'Smile starts with :) on one line then content on next line'
    }

    It 'Can format as PlainText' {
        $Shards = Get-OSSegment -Format 'PlainText'

        $Shards.GetType().FullName | Should -Be 'System.String' -Because 'PlainText format appears as strings'
        $Shards | Should -Match "index\s+shard\s+prirep" -Because 'PlainText starts with headers'
    }
    #endregion
}

AfterAll {
    Remove-OSIndex $IndexName -NoConfirm
}
