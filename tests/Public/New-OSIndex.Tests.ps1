BeforeAll {
    Import-Module "./OpenSearch-PoSH/OpenSearch-PoSH.psd1" -Force

    $global:Index1 = 'New-OSIndex-Test1'
}

Describe 'New-OSIndex' {
    It 'Creates empty index' {
        New-OSIndex -Index $global:Index1 | Should -BeNullOrEmpty -Because 'No response means success'
    }

    # ConfigHash tests
    It 'Creates an index with valid ConfigHash' {
        $Config = @{
            'settings' = @{
                'index' = @{
                    'number_of_replicas' = 0
                }
            }
            'mappings' = @{
                'properties' = @{
                    'field1' = @{
                        'type' = 'text'
                    }
                    'field2' = @{
                        'type' = 'integer'
                    }
                }
            }
        }

        New-OSIndex -Index $global:Index1 -ConfigHash $Config | Should -BeNullOrEmpty -Because 'No response means success'
    }

    It 'Throws error with invalid ConfigHash' {
        $Config = @{
            'MispelledSettings' = @{
                'index' = @{
                    'number_of_replicas' = 0
                }
            }
            'mappings'          = @{
                'properties' = @{
                    'field1' = @{
                        'type' = 'text'
                    }
                    'field2' = @{
                        'type' = 'integer'
                    }
                }
            }
        }

        { New-OSIndex -Index $global:Index1 -ConfigHash $Config } | Should -Throw -Because 'Invalid ConfigHash errors'
    }

    # ConfigJson tests
    It 'Creates an index with valid ConfigJson' {
        $Config = @'
{
    "settings": {
        "index": {
            "number_of_replicas": 0
        }
    },
    "mappings": {
        "properties": {
            "Field2": {
                "type": "integer"
            }
        }
    }
}
'@

        New-OSIndex -Index $global:Index1 -ConfigJson $Config | Should -BeNullOrEmpty -Because 'No response means success'
    }

    It 'Throws error with malformed ConfigJson' {
        $Config = @'
{
    "settings": {
        "index": {
            "number_of_replicas": 0
        
    }
    "mappings": {
        "properties": {
            "Field2": {
                "type": "integer"
            }
        }
    }
}
'@

        { New-OSIndex -Index $global:Index1 -ConfigJson $Config } | Should -Throw "ConfigJson variable must contain valid JSON (Parameter 'ConfigJson')" -Because 'Malformed JSON throws error'
    }

    # ParameterSets tests
    It 'Creates empty index - Can manually specify credentials' {
        $Username = 'admin'
        $Password = 'MyNotSecretAdminPass123!' | ConvertTo-SecureString -AsPlainText -Force
        $Credential = New-Object PSCredential $Username, $Password

        New-OSIndex -Index $global:Index1 -Credential $Credential
    }

    AfterEach {
        Remove-OSIndex -Index $global:Index1 -NoConfirm
    }
}
