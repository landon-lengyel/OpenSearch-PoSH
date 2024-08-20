BeforeAll {
    Import-Module "./OpenSearch-PoSH/OpenSearch-PoSH.psd1" -Force

    # Create a few test indices
    $Index1 = 'New-OSAlias-Test1'
    $Index2 = 'New-OSAlias-Test2'
    $Document = @{ 'myfield' = 'myvalue' }

    Import-OSDocument -Index $Index1 -Document $Document
    Import-OSDocument -Index $Index2 -Document $Document

    Start-Sleep -Seconds 1    # Give time for indexing
}

Describe 'New-OSAlias' {
    It 'Maps 1 alias to 1 index' {
        New-OSAlias -Index $Index1 -Alias 'Alias1' | Should -BeNullOrEmpty -Because 'No return means success'
    }

    It 'Maps 1 alias to 2 indices' {
        New-OSAlias -Index @($Index1,$Index2) -Alias 'Alias2' | Should -BeNullOrEmpty -Because 'No return means success'
    }

    It 'Maps 1 alias to 2 indices, with one a write index' {
        New-OSAlias -Index @($Index1,$Index2) -Alias 'Alias3' -WriteIndex $Index1 | Should -BeNullOrEmpty -Because 'No return means success'
    }

    It 'Maps 2 aliases to 1 index' {
        New-OSAlias -Index $Index1 -Alias @('Alias4','Alias5') | Should -BeNullOrEmpty -Because 'No return means success'
    }

    It 'Maps 2 aliases to 2 indices' {
        New-OSAlias -Index @($Index1,$Index2) -Alias @('Alias4','Alias5') | Should -BeNullOrEmpty -Because 'No return means success'
    }

    It 'Maps 2 aliases to 2 indices, with one a write index' {
        New-OSAlias -Index @($Index1,$Index2) -Alias @('Alias4','Alias5') -WriteIndex $Index2 | Should -BeNullOrEmpty -Because 'No return means success'
    }
}

AfterAll {
    Remove-OSIndex -Index $Index1 -NoConfirm
    Remove-OSIndex -Index $Index2 -NoConfirm
}
