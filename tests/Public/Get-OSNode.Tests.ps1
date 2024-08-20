BeforeAll {
    Import-Module "./OpenSearch-PoSH/OpenSearch-PoSH.psd1" -Force
}

Describe 'Get-OSNode' {
    It 'Returns all nodes' {
        $Nodes = Get-OSNode

        $Nodes[0].name | Should -Not -BeNullOrEmpty -Because 'Returns node name'
        $Nodes[0].id | Should -Match '\w{4,8}' -Because 'Node ID is truncated'
    }

    It 'Returns full ID' {
        $Nodes = Get-OSNode -FullId

        $Nodes[0].id | Should -Match '\w{14,}' -Because 'Full node ID is returned'
    }

    It 'Limits headers returned' {
        $Nodes = Get-OSNode -Headers @('name','ip')

        $Nodes[0].name | Should -Not -BeNullOrEmpty -Because 'Returns node name'
        $Nodes[0].ip | Should -Not -BeNullOrEmpty -Because 'Returns node IP'
        $Nodes[0].id | Should -BeNullOrEmpty -Because 'Only returns whats specified in headers'
    }

    #region Format
    It 'Can format as JSON' {
        $Nodes = Get-OSNode -Format 'JSON'

        $Nodes.GetType().FullName | Should -Be 'System.String' -Because 'JSON format appears as strings'
        $Nodes | ConvertFrom-Json | Should -ExpectedType 'System.Management.Automation.PSCustomObject' -Because 'JSON should be valid'
    }

    It 'Can format as YAML' {
        $Nodes = Get-OSNode -Format 'YAML'

        $Nodes.GetType().FullName | Should -Be 'System.String' -Because 'YAML format appears as strings'

        $Nodes | Should -BeLike '---*' -Because 'First YAML line is three dashes'
        $Nodes | Should -BeLike "*- name:*" -Because 'YAML returns node names'
    }

    It 'Can format as CBOR' {
        $Nodes = Get-OSNode -Format 'CBOR'

        $Nodes.GetType().FullName | Should -Be 'System.String' -Because 'CBOR format appears as strings'
        $Nodes | Should -BeLike '??dnamep*' -Because 'CBOR starts with ?? then adds content'
    }

    It 'Can format as Smile' {
        $Nodes = Get-OSNode -Format 'Smile'

        $Nodes.GetType().FullName | Should -Be 'System.String' -Because 'Smile format appears as strings'
        $Nodes | Should -BeLike ":)`n.???name*" -Because 'Smile starts with :) on one line then content on next line'
    }

    It 'Can format as PlainText' {
        $Nodes = Get-OSNode -Format 'PlainText' -VerboseResponse

        $Nodes.GetType().FullName | Should -Be 'System.String' -Because 'PlainText format appears as strings'
        $Nodes | Should -Match "name\s+id\s+ip" -Because 'PlainText starts with headers'
    }
    #endregion
}
