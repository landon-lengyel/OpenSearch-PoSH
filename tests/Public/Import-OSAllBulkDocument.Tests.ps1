BeforeAll {
    Import-Module "./OpenSearch-PoSH/OpenSearch-PoSH.psd1" -Force

    # Index to store test data in
    $global:Index = 'allbulktest'
    # Path to test documents
    $global:TestFile418 = './tests/test-data/Test-Bulk-418.csv'
    $global:TestFile100000 = './tests/test-data/Test-Bulk-100000.csv'
}

Describe Import-OSAllBulkDocument {
    It 'Can import 418 documents' {
        $Documents = Get-Content -Path $global:TestFile418 | ConvertFrom-Csv

        Import-OSAllBulkDocument -Index $global:Index -Documents $Documents | Should -BeNullOrEmpty -Because 'Success returns null'
    }

    It 'Can import 100,000 documents' {
        $Documents = Get-Content -Path $global:TestFile100000 | ConvertFrom-Csv

        Import-OSAllBulkDocument -Index $global:Index -Documents $Documents | Should -BeNullOrEmpty -Because 'Success returns null'
    }

    It 'Can import documents using value from pipeline' {
        Get-Content -Path $global:TestFile418 | ConvertFrom-Csv | Import-OSAllBulkDocument -Index $global:Index | Should -BeNullOrEmpty -Because 'Success returns null'
    }

    It 'Can import hashtables contained in a Generic List'{
        $Documents = Get-Content -Path $global:TestFile418 | ConvertFrom-Csv

        $NewDocuments = [System.Collections.Generic.List[hashtable]]::new()
        foreach ($Document in $Documents){
            $Hashtable = @{}
            foreach ($Property in $Document.PSObject.properties){
                $Hashtable.($Property.Name) = $Property.Value
            }

            $NewDocuments.Add($Hashtable)
        }

        Import-OSAllBulkDocument -Index $global:Index -Documents $NewDocuments | Should -BeNullOrEmpty -Because 'Success returns null'
    }

    #region Data Streams
    # Need function to create Data Stream templates to test this
    #endregion

    AfterEach {
        Remove-OSIndex -Index $global:Index -NoConfirm
    }
}
