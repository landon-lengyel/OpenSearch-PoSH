BeforeAll {
    $IndexName = 'Get-OSIndex-TestIndex'

    Import-Module "./OpenSearch-PoSH/OpenSearch-PoSH.psd1" -Force

    Import-OSDocument -Index $IndexName -Document @{'MyField' = 'MyValue'}
}

Describe 'Get-OSIndex' {
    It 'Lists all indices' {
        $Indices = Get-OSIndex

        $Indices.GetType().BaseType.FullName | Should -Be 'System.Array' -Because 'Indices are returned as array'
        $Indices[0].health | Should -BeIn @('green','yellow','red') -Because 'Health information is returned'
    }

    It 'Limits output to a specific index' {
        $Index = Get-OSIndex -Index $IndexName

        $Index | Should -ExpectedType 'System.Management.Automation.PSCustomObject' -Because 'One index is returned'
        $Index.health | Should -BeIn @('green','yellow','red') -Because 'Health information is returned'
    }

    It 'Limits output to specific header' {
        $Index = Get-OSIndex -Index $IndexName -Headers @('health')

        $Index | Should -ExpectedType 'System.Management.Automation.PSCustomObject' -Because 'One index is returned'
        $Index.health | Should -BeIn @('green','yellow','red') -Because 'Health information is returned'
        $Index.status | Should -BeNullOrEmpty -Because 'Return is limited'
    }

    #region Format
    It 'Can format as JSON' {
        $Indices = Get-OSIndex -Format 'JSON'

        $Indices.GetType().FullName | Should -Be 'System.String' -Because 'JSON format appears as strings'
        $Indices | ConvertFrom-Json | Should -ExpectedType 'System.Management.Automation.PSCustomObject' -Because 'JSON should be valid'
    }

    It 'Can format as YAML' {
        $Indices = Get-OSIndex -Format 'YAML'

        $Indices.GetType().FullName | Should -Be 'System.String' -Because 'YAML format appears as strings'

        $Indices | Should -BeLike '---*' -Because 'First YAML line is three dashes'
        $Indices | Should -BeLike "*- health:*"
    }

    It 'Can format as CBOR' {
        $Indices = Get-OSIndex -Format 'CBOR'

        $Indices.GetType().FullName | Should -Be 'System.String' -Because 'CBOR format appears as strings'
        $Indices | Should -BeLike '??fhealthf*' -Because 'CBOR starts with ?? then adds content'
    }

    It 'Can format as Smile' {
        $Indices = Get-OSIndex -Format 'Smile'

        $Indices.GetType().FullName | Should -Be 'System.String' -Because 'Smile format appears as strings'
        $Indices | Should -BeLike ":)`n.???health*" -Because 'Smile starts with :) on one line then content on next line'
    }

    It 'Can format as PlainText' {
        $Indices = Get-OSIndex -Format 'PlainText'

        $Indices.GetType().FullName | Should -Be 'System.String' -Because 'PlainText format appears as strings'
        $Indices | Should -Match "health\s+status\s+index" -Because 'PlainText starts with headers'
    }
    #endregion
}

AfterAll {
    Remove-OSIndex -Index $IndexName -NoConfirm
}
