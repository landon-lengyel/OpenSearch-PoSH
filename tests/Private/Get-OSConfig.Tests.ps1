BeforeAll {
    Import-Module "./src/OpenSearch.psd1" -Force
    . "./src/Private/Get-OSConfig.ps1"
}

Describe 'Get-OSConfig' {
    It 'Given no parameters, it returns all values' {
        # Just the validated output (PSCustomObject) with ConvertTo-Json
        $ExpectedResult = '{"PowerShellLogging":{"AllowedAttributesPath":"./OpenSearch-PoSHNamingStandard.json"},"NodeOptions":{"AllowUnencryptedAuthentication":true,"SkipCertificateCheck":true},"Nodes":["https://opensearch-test1.local:9200"],"Authentication":{"BasicAuth":{"Username":"admin","Password":"MyNotSecretAdminPass123!"}}}'

        # ConvertTo-Json is easiest way to compare these objects
        $Config = Get-OSConfig
        $Config | ConvertTo-Json -Depth 100 -Compress | Should -Be $ExpectedResult -Because 'This is the validated config output.'
    }

    It 'Specifying Nodes should limit output' {
        $ExpectedResult = '{"Nodes":["https://opensearch-test1.local:9200"]}'

        $Config = Get-OSConfig -ReturnOptions @('Nodes')
        $Config | ConvertTo-Json -Depth 100 -Compress | Should -Be $ExpectedResult -Because 'You should be able to limit output to nodes, and this is the validated node list.'
    }

    It 'Specifying Authentication and PowershellLogging should limit output' {
        $ExpectedResult = '{"Authentication":{"BasicAuth":{"Username":"admin","Password":"MyNotSecretAdminPass123!"}},"PowerShellLogging":{"AllowedAttributesPath":"./OpenSearch-PoSHNamingStandard.json"}}'

        
        $Config = Get-OSConfig -ReturnOptions @('Authentication','PowerShellLogging')
        $Config | ConvertTo-Json -Depth 100 -Compress | Should -Be $ExpectedResult -Because 'You should be able to limit output to Authentication and PowershellLogging, and this is the validated config output.'
    }
}
