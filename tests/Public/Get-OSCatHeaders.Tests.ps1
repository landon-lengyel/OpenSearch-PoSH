BeforeAll {
    Import-Module "./src/OpenSearch.psd1" -Force
}

Describe 'Get-OSCatHeaders' {
    It 'Can describe headers for _cat/indices' {
        $Cat = Get-OSCatHeaders -CatApi 'indices'

        $Cat.GetType().BaseType.FullName | Should -Be 'System.Array' -Because 'returns an array'
        $Cat[0].GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject' -Because 'each array element is a PSCustomObject'
        $Cat.Header | Should -Contain 'health' -Because 'health is one of the headers'
    }

    It 'Can output only headers' {
        $Cat = Get-OSCatHeaders -CatApi 'indices' -OutputFormat HeadersOnly

        $Cat.GetType().BaseType.FullName | Should -Be 'System.Array' -Because 'returns an array'
        $Cat[0].GetType().FullName | Should -Be 'System.String' -Because 'each array element is a string'
        $Cat | Should -Contain 'health' -Because 'health is one of the headers'
    }

    It 'Can output Headers as CSV' {
        $Cat = Get-OSCatHeaders -CatApi 'indices' -OutputFormat HeadersCsv

        $Cat.GetType().FullName | Should -Be 'System.String' -Because 'returns a string of comma seperated values'
        $Cat | Should -BeLike 'health,status,*' -Because 'first two elements of the return result'
    }
}
