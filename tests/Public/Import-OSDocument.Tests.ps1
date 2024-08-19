BeforeAll {
    Import-Module "./src/OpenSearch.psd1" -Force

    # Variables used in tests
    $Index = 'Import-OSDocument-TestIndex'
    $Document = @{
        'Record Counter' = $Record
        'Property 1'     = 'Value1'
        'Object 1'       = @{
            'Property 2'   = 'Value 2'
            'The Number 3' = 3
        }
    }
    $Username = 'admin'
    $Password = 'MyNotSecretAdminPass123!' | ConvertTo-SecureString -AsPlainText -Force
    $Credential = New-Object PSCredential $Username, $Password
}

Describe 'Import-OSDocument' {
    It 'Imports a single document to a new index' {
        $Request = @{
            'Index' = $Index
            'Document' = $Document
        }
        $Response = Import-OSDocument @Request

        $Response.GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject' -Because 'Successful document creation returns a PSCustomObject'
        $Response._index | Should -Be $Index
        $Response.result | Should -Be 'created'
    }

    #region DocumentId
    It 'Can import at a specific DocumentId' {
        $DocumentId = 'MyVerySpecificDocId'
        $Request = @{
            'Index' = $Index
            'Document' = $Document
            'DocumentId' = $DocumentId
        }

        $Response = Import-OSDocument @Request
        $Response.GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject' -Because 'Successful document creation returns a PSCustomObject'
        $Response._index | Should -Be $Index
        $Response.result | Should -Be 'created'
        $Response._id | Should -Be $DocumentId -Because 'Support creation at specific document _id'
    }

    It 'Can import at a specific DocumentId with the same document' {
        $DocumentId = 'MyVerySpecificDocId'
        $Request = @{
            'Index' = $Index
            'Document' = $Document
            'DocumentId' = $DocumentId
        }

        $Response = Import-OSDocument @Request
        $Response.GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject' -Because 'Successful document creation returns a PSCustomObject'
        $Response._index | Should -Be $Index
        $Response.result | Should -Be 'updated' -Because 'It is replacing an exiting document'
        $Response._id | Should -Be $DocumentId -Because 'Support creation at specific document _id'
    }

    It 'Can import at a specific DocumentId with a different document, replacing it' {
        $DocumentId = 'MyVerySpecificDocId'
        $Request = @{
            'Index' = $Index
            'Document' = @{'MyNewProperty' = '1234'}
            'DocumentId' = $DocumentId
        }

        $Response = Import-OSDocument @Request
        $Response.GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject' -Because 'Successful document creation returns a PSCustomObject'
        $Response._index | Should -Be $Index
        $Response.result | Should -Be 'updated' -Because 'It is replacing an exiting document'
        $Response._id | Should -Be $DocumentId -Because 'Support creation at specific document _id'
    }
    #endregion

    It 'Can specify Username/Password manually' {
        $Request = @{
            'Index' = $Index
            'Document' = $Document
            'Credential' = $Credential
        }
        $Response = Import-OSDocument @Request

        $Response.GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject' -Because 'Successful document creation returns a PSCustomObject'
        $Response._index | Should -Be $Index
        $Response.result | Should -Be 'created'
    }
}

AfterAll {
    Remove-OSIndex -Index $Index -NoConfirm
}
