BeforeAll {
    $IndexName = 'Confirm-OSIndexExists-TestIndex'

    Import-Module "./src/OpenSearch.psd1" -Force

    Import-OSDocument -Index $IndexName -Document @{'MyField' = 'MyValue'}
}

Describe 'Confirm-OSIndexExists' {
    It 'Confirms index exists' {
        Confirm-OSIndexExist -Index $IndexName | Should -Be $true -Because 'Index exists'
    }

    It 'Confirms non-existant index doesnt exist' {
        Confirm-OSIndexExist -Index 'MyNonExistantIndexName' | Should -Be $false -Because 'Index doesnt exist'
    }
}

AfterAll {
    Remove-OSIndex -Index $IndexName -NoConfirm
}
