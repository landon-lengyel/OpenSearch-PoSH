BeforeAll {
    $IndexName = 'log_ps_find-oslogps-testindex'

    Import-Module "./OpenSearch-PoSH/OpenSearch-PoSH.psd1" -Force

    Add-OSLogPS -Index $IndexName -DisableLocalLog -Message 'test log 1' -LogLevel 'Information'
    Add-OSLogPS -Index $IndexName -DisableLocalLog -Message 'test log 2' -LogLevel 'Information'
    Add-OSLogPS -Index $IndexName -DisableLocalLog -Message 'test error 1' -LogLevel 'Error'

    Start-Sleep -Seconds 1     # Takes a second for indexing
}

Describe 'Find-OSLogPS' {
    It 'Can find all information results' {
        $Results = Find-OSLogPS -Index $IndexName -LogLevel 'Information'

        $Results.hits.total.value | Should -Be 2 -Because 'Should return two hits'
    }

    It 'Can find a specific message' {
        $Results = Find-OSLogPS -Index $IndexName -Message 'test log 1'

        ($Results.hits.hits | Where-Object {$_._score -ge 1}).Count | Should -Be 1 -Because 'Should return only one hit with a higher score than 1'
        ($Results.hits.hits | Where-Object {$_._score -ge 1})._source.Message | Should -Be 'test log 1' -Because 'Matching document is correct'
    }

    It 'Can provide ranking explanation' {
        $Results = Find-OSLogPS -Index $IndexName -Message 'test log 1' -Explain

        $Results.hits.hits[0]._explanation.details | Should -Not -BeNullOrEmpty -Because 'Provided explanation'
    }

    It 'Can limit return size' {
        $Results = Find-OSLogPS -Index $IndexName -Message 'test log 1' -Size 1

        $Results.hits.total.value | Should -BeGreaterThan 1 -Because 'Notes that there are more non-returned results'
        ($Results.hits.hits).count | Should -Be 1 -Because 'Returns only closest match'
        ($Results.hits.hits)[0]._source.Message | Should -Be 'test log 1' -Because 'Matching document is closest match'
    }
}

AfterAll {
    Remove-OSIndex -Index $IndexName -NoConfirm
}