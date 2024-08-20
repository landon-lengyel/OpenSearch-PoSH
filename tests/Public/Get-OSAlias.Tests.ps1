BeforeAll {
    Import-Module "./OpenSearch-PoSH/OpenSearch-PoSH.psd1" -Force

    # Create a few test indices
    $Index1 = 'New-OSAlias-Test1'
    $Index2 = 'New-OSAlias-Test2'
    $Document = @{ 'myfield' = 'myvalue' }

    Import-OSDocument -Index $Index1 -Document $Document
    Import-OSDocument -Index $Index2 -Document $Document

    Start-Sleep -Seconds 1    # Give time for indexing

    # Create a few aliases
    New-OSAlias -Index $Index1 -Alias 'Alias1'
    New-OSAlias -Index $Index2 -Alias 'Alias2'
}

Describe 'Get-OSAlias' {
    It 'Can get all aliases' {
        $Aliases = Get-OSAlias

        $Aliases.GetType().BaseType.FullName | Should -Be 'System.Array' -Because 'Returns array of results'
        ($Aliases | Where-Object {$_.index -eq $Index1}).alias | Should -Contain 'alias1' -Because 'Returns the correct list of aliases'
    }

    It 'Can limit results to one alias' {
        $Aliases = Get-OSAlias -Alias 'alias1'

        $Aliases | Should -ExpectedType 'System.Management.Automation.PSCustomObject' -Because 'Returns a PSCustomObject if only one result'
        $Aliases.alias | Should -Be 'alias1' -Because 'Correct result is returned'
    }

    It 'Can limit results to multiple aliases' {
        $Aliases = Get-OSAlias -Alias @('Alias1','Alias2')

        $Aliases.GetType().BaseType.FullName | Should -Be 'System.Array' -Because 'Returns array of results'
        ($Aliases | Where-Object {$_.index -eq $Index1}).alias | Should -Contain 'alias1' -Because 'Returns the correct list of aliases'
    }

    It 'Can limit return headers' {
        $Aliases = Get-OSAlias -Headers @('alias','filter')

        $Aliases.GetType().BaseType.FullName | Should -Be 'System.Array' -Because 'Returns array of results'
        $Aliases[0].index | Should -BeNullOrEmpty -Because 'Index header was filtered out'
    }

    #region Format
    It 'Can format as JSON' {
        $Aliases = Get-OSAlias -Format 'JSON'

        $Aliases.GetType().FullName | Should -Be 'System.String' -Because 'JSON format appears as strings'
        $Aliases | ConvertFrom-Json | Should -ExpectedType 'System.Management.Automation.PSCustomObject' -Because 'JSON should be valid'
    }

    It 'Can format as YAML' {
        $Aliases = Get-OSAlias -Format 'YAML'

        $Aliases.GetType().FullName | Should -Be 'System.String' -Because 'YAML format appears as strings'

        $Aliases | Should -BeLike '---*' -Because 'First YAML line is three dashes'
        $Aliases | Should -BeLike "*- alias:*" -Because 'YAML returns node names'
    }

    It 'Can format as CBOR' {
        $Aliases = Get-OSAlias -Format 'CBOR'

        $Aliases.GetType().FullName | Should -Be 'System.String' -Because 'CBOR format appears as strings'
        $Aliases | Should -BeLike '??ealiasf*' -Because 'CBOR starts with ?? then adds content'
    }

    It 'Can format as Smile' {
        $Aliases = Get-OSAlias -Format 'Smile'

        $Aliases.GetType().FullName | Should -Be 'System.String' -Because 'Smile format appears as strings'
        $Aliases | Should -BeLike ":)`n.???alias*" -Because 'Smile starts with :) on one line then content on next line'
    }

    It 'Can format as PlainText' {
        $Aliases = Get-OSAlias -Format 'PlainText'

        $Aliases.GetType().FullName | Should -Be 'System.String' -Because 'PlainText format appears as strings'
        $Aliases | Should -Match "alias\s+index\s+filter" -Because 'PlainText starts with headers'
    }
    #endregion
}

AfterAll {
    Remove-OSIndex -Index $Index1 -NoConfirm
    Remove-OSIndex -Index $Index2 -NoConfirm
}
