BeforeAll {
    Import-Module "./OpenSearch-PoSH/OpenSearch-PoSH.psd1" -Force
}

Describe 'Get-OSClusterSetting' {
    It 'Gets all cluster settings - including defaults' {
        $settings = Get-OSClusterSetting -IncludeDefaults

        $settings.defaults | Should -Not -BeNullOrEmpty -Because 'Default settings are returned'
    }
}