BeforeAll {
    Import-Module "./src/OpenSearch.psd1" -Force

    $OriginalLocation = Get-Location
    $PfxPath = "$OriginalLocation/docker/opensearch-security/test-admin.pfx"
    $PfxThumbprint = '0ac3bc7c992b600cf982a9c5dee16516d9714af5'   # Also specified in test config below
}

Describe 'Authentication' {
    BeforeEach {
        # Pester created temp drive
        Set-Location "TestDrive:\"
    }
    
    #region BasicAuth
    It 'Can authenticate with Username/Password directly without specifying URL' {
        # Config to use NodeOptions, and Nodes
        $Config = '{
            "NodeOptions": {
                "AllowUnencryptedAuthentication": true,
                "SkipCertificateCheck": true
            },
            "Nodes": [
                "https://opensearch-test1.local:9200"
            ]
        }'
        $Config | Out-File -Path './PoSHOpenSearchConfig.json'

        $Username = 'admin'
        $Password = 'MyNotSecretAdminPass123!' | ConvertTo-SecureString -AsPlainText -Force
        $Credential = New-Object PSCredential $Username, $Password

        $Health = Get-OSClusterHealth -Credential $Credential
        
        $Health.GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject' -Because 'Script can use config file to specify node URLs and manually specify basic authentication'

        $Health.status | Should -BeIn @('green','yellow','red') -Because 'Success returns status'
    }

    It 'Can use config file to specify Username/Password and URL' {
        # Config to use Authentication, NodeOptions, and Nodes
        $Config = '{
            "NodeOptions": {
                "AllowUnencryptedAuthentication": true,
                "SkipCertificateCheck": true
            },
            "Nodes": [
                "https://opensearch-test1.local:9200"
            ],
            "Authentication": {
                "BasicAuth": {
                    "Username": "admin",
                    "Password": "MyNotSecretAdminPass123!"
                }
            }
        }'
        $Config | Out-File -Path './PoSHOpenSearchConfig.json'

        $Health = Get-OSClusterHealth
        
        $Health.GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject' -Because 'Use config file to specify nodes and username/password'

        $Health.status | Should -BeIn @('green','yellow','red') -Because 'Success returns status'
    }

    # Right now, no way around this without modifying lots of functions
    It 'Cannot authenticate with Username/Password while specifying URL (Certificate error)' {
        $URL = 'https://opensearch-test1.local:9200'

        $Username = 'admin'
        $Password = 'MyNotSecretAdminPass123!' | ConvertTo-SecureString -AsPlainText -Force
        $Credential = New-Object PSCredential $Username, $Password

        { Get-OSClusterHealth -Credential $Credential -OpenSearchURL $URL } | Should -Throw 'The SSL connection could not be established, see inner exception.' -Because 'We havent allowed SkipCertificateCheck'
    }
    It 'Empty config file should still allow manual authentication' {
        New-Item -Path './PoSHOpenSearchConfig.json'

        $URL = 'https://opensearch-test1.local:9200'

        $Username = 'admin'
        $Password = 'MyNotSecretAdminPass123!' | ConvertTo-SecureString -AsPlainText -Force
        $Credential = New-Object PSCredential $Username, $Password

        { Get-OSClusterHealth -Credential $Credential -OpenSearchURL $URL } | Should -Throw 'The SSL connection could not be established, see inner exception.' -Because 'We havent allowed SkipCertificateCheck'
    }
    #endregion
    #region PFX Certificate
    It 'Can use config file to specify PFX Certificate path' {
        # Config to use Authentication, NodeOptions, and Nodes
        $Config = '{
            "NodeOptions": {
                "AllowUnencryptedAuthentication": true,
                "SkipCertificateCheck": true
            },
            "Nodes": [
                "https://opensearch-test1.local:9200"
            ],
            "Authentication": {
                "Certificate": {
                    "CertificatePfxPath": "./test-admin.pfx"
                },
            }
        }'
        $Config | Out-File -Path './PoSHOpenSearchConfig.json'

        # Copy the PFX File
        Copy-Item -Path $PfxPath -Destination "." | Should -BeNullOrEmpty -Because 'Certificate path should be correct'

        $Health = Get-OSClusterHealth
        
        $Health.GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject' -Because 'Used the PFX file to authenticate specified in config'

        $Health.status | Should -BeIn @('green','yellow','red') -Because 'Success returns status'
    }
    #endregion
    #region Windows Certificate Store
    It 'Can use certificate from Windows Certificate store, finding by Thumbprint' {
        # Config to use Authentication, NodeOptions, and Nodes
        $Config = '{
            "NodeOptions": {
                "AllowUnencryptedAuthentication": true,
                "SkipCertificateCheck": true
            },
            "Nodes": [
                "https://opensearch-test1.local:9200"
            ],
            "Authentication": {
                "WindowsUserCertificate": {
                    "Thumbprint": "0ac3bc7c992b600cf982a9c5dee16516d9714af5"
                }
            }
        }'
        $Config | Out-File -Path './PoSHOpenSearchConfig.json'

        # Copy the PFX File and import it
        Copy-Item -Path $PfxPath -Destination "." | Should -BeNullOrEmpty -Because 'Certificate path should be correct'
        Import-PfxCertificate -FilePath './test-admin.pfx' -CertStoreLocation 'Cert:\CurrentUser\My\' | Should -ExpectedType 'System.Security.Cryptography.X509Certificates.X509Certificate2' -Because 'Pfx name should be correct and importable'

        $Health = Get-OSClusterHealth
        
        $Health.GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject' -Because 'Found certificate in Windows cert store using the thumbprint'

        $Health.status | Should -BeIn @('green','yellow','red') -Because 'Success returns status'
    }

    # TODO: Add a test to find cert with TemplateName
    # I think this will require adding the test template name to OID '1.3.6.1.4.1.311.21.7' - Should be possible with OpenSSL

    #endregion
    #region Windows Certificate Request

    # TODO: Add tests for requesting certificates from Windows CA
    # Getting test environment to work here will be very difficult.
    # Will need a test Windows domain, CA, and this computer to be joined to the domain.

    #endregion
    
    AfterEach {
        Remove-Item 'TestDrive:\PoSHOpenSearchConfig.json' -ErrorAction SilentlyContinue
        Set-Location $OriginalLocation
    }
}

AfterAll {
    Get-ChildItem -Path "Cert:\CurrentUser\My\$PfxThumbprint" -ErrorAction SilentlyContinue | Remove-Item
}
