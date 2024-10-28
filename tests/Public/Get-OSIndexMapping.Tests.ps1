BeforeAll {
    $IndexName = 'Get-OSIndexMapping-TestIndex'

    Import-Module "./OpenSearch-PoSH/OpenSearch-PoSH.psd1" -Force

    Import-OSDocument -Index $IndexName -Document @{'MyField' = 'MyValue'}
    Import-OSDocument -Index $IndexName -Document @{'MyField' = 'MyValue'; 'MyField2' = 'MyValue2'}
}

Describe 'Get-OSIndexMapping' { 
    It 'Can return mappings' {
        $Mapping = Get-OSIndexMapping -Index $IndexName

        $Mapping.$IndexName.mappings.properties | Should -Not -BeNullOrEmpty -Because 'Mappings are returned'
    }
}

AfterAll {
    Remove-OSIndex -Index $IndexName -NoConfirm
}
