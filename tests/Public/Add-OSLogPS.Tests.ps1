BeforeAll {
    Import-Module "./src/OpenSearch.psd1" -Force

    $OriginalLocation = Get-Location
}

Describe 'Add-OSLogPS' {
    BeforeEach {
        # Pester created temp drive
        Set-Location "TestDrive:\"

        $DefaultLogFilePath = "$global:PSScriptRoot\Logs\Pester_OpenSearch_$(Get-Date -Format yyyy-MM-dd).json"
    }

    AfterEach {
        Set-Location $OriginalLocation
    }

    It 'Can add basic logs with LogLevels' -ForEach @(
        @{'Index' = 'log_ps_test'; 'LogLevel' = 'Trace'; 'Message' = 'This is a test entry'}
        @{'Index' = 'log_ps_test'; 'LogLevel' = 'Verbose'; 'Message' = 'This is a test entry'}
        @{'Index' = 'log_ps_test'; 'LogLevel' = 'Information'; 'Message' = 'This is a test entry'}
        @{'Index' = 'log_ps_test'; 'LogLevel' = 'Warning'; 'Message' = 'This is a test entry'}
        @{'Index' = 'log_ps_test'; 'LogLevel' = 'Error'; 'Message' = 'This is a test entry'}
        @{'Index' = 'log_ps_test'; 'LogLevel' = 'Critical'; 'Message' = 'This is a test entry'}
    ) {
        $Response = Add-OSLogPS -Index $Index -DisableLocalLog -LogLevel $LogLevel -Message $Message

        $Response | Should -BeNullOrEmpty -Because 'Success returns $null'
    }

    It 'Fails when using invalid index name' {
        $Params = @{
            'Index' = 'NotAPSIndex'
            'DisableLocalLog' = $true
            'LogLevel' = 'Information'
            'Message' = 'This is a test entry'
        }
        { Add-OSLogPS @Params } | Should -Throw 'IndexName must be: log_ps_misc OR match the format: log_ps_{SCRIPT NAME}_{OPTIONAL HOSTNAME}-{OPTIONAL EXTRA INFO}'
    }

    It 'Fails when not specifying LogLevel' {
        $Params = @{
            'Index' = 'log_ps_test'
            'DisableLocalLog' = $true
            'LogLevel' = $null
            'Message' = 'This is a test entry'
        }
        {Add-OSLogPS @Params } | Should -Throw "Cannot validate argument on parameter 'LogLevel'. The argument `"`" does not belong to the set*" -Because 'LogLevel must be an allowed option'
    }

    #region Valid Fields
    It 'Can add valid options from OpenSearch-PoSHNamingStandard.json' {
        $Params = @{
            'Index' = 'log_ps_test'
            'DisableLocalLog' = $true
            'LogLevel' = 'Information'
            'Message' = 'This is a test entry'
            'AD.SamAccountName' = 'MyCoolAccount'
            'PoSH.Error' = 'Woops, my script threw an error!'
        }
        Add-OSLogPS @Params | Should -BeNullOrEmpty -Because 'Success returns $null'
    }

    It 'Fails with invalid options from OpenSearch-PoSHNamingStandard.json' {
        $Params = @{
            'Index' = 'log_ps_test'
            'DisableLocalLog' = $true
            'LogLevel' = 'Information'
            'Message' = 'This is a test entry'
            'ImNotApproved.Bad' = 'IWillFail'
        }
        { Add-OSLogPS @Params } | Should -Throw 'Unapproved field names found: ImNotApproved.Bad'
    }
    #endregion

    #region Log Files
    It 'Adds content to local log file' {
        $Params = @{
            'Index' = 'log_ps_test'
            'LogLevel' = 'Information'
            'Message' = 'This is a test entry'
        }
        Add-OSLogPS @Params | Should -BeNullOrEmpty -Because 'Success returns $null'

        Test-Path -Path $DefaultLogFilePath | Should -BeTrue -Because 'Default log file should be created'
    }

    It 'Adds content to specified log file' {
        $SpecificLogFilePath = "./SpecificLogFile.json"

        $Params = @{
            'Index' = 'log_ps_test'
            'LogLevel' = 'Information'
            'Message' = 'This is a test entry'
            'LogFile' = $SpecificLogFilePath
        }
        # Add twice so ConvertFrom-Json should return an array
        Add-OSLogPS @Params | Should -BeNullOrEmpty -Because 'Success returns $null'
        Add-OSLogPS @Params | Should -BeNullOrEmpty -Because 'Success returns $null'

        Test-Path -Path $SpecificLogFilePath | Should -BeTrue -Because 'Log file should be created'
        $LogContent = Get-Content -Path $SpecificLogFilePath | ConvertFrom-Json -Depth 100

        $LogContent.GetType().BaseType.FullName | Should -Be 'System.Array' -Because 'Log content as stored as a JSON array'
        $LogContent.Count | Should -Be 2 -Because 'Two log entries were added'
    }
    #endregion
}

AfterAll {
    Remove-OSIndex -Index 'log_ps_test' -NoConfirm

    Remove-Item -Path "$global:PSScriptRoot\Logs\" -Recurse
}
