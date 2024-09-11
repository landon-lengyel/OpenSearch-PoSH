BeforeAll {
    Import-Module "./OpenSearch-PoSH/OpenSearch-PoSH.psd1" -Force

    $global:OriginalLocation = Get-Location
}

Describe Add-OSLogPSBulk {
    BeforeEach {
        # Pester created temp drive
        Copy-Item './PoSHOpenSearchConfig.json' 'TestDrive:\PoSHOpenSearchConfig.json'
        Copy-Item './OpenSearch-PoSHNamingStandard.json' 'TestDrive:\OpenSearch-PoSHNamingStandard.json'
        Set-Location "TestDrive:\"

        $DefaultLogFilePath = "$global:PSScriptRoot\Logs\Pester_OpenSearch_$(Get-Date -Format yyyy-MM-dd).json"
    }

    AfterEach {
        Set-Location $OriginalLocation
    }

    #region Valid Fields
    It 'Can add valid options from OpenSearch-PoSHNamingStandard.json' {
        $LogTemplate = @{
            'LogLevel' = 'Information'
            '@timestamp' = $(Get-Date)
            'Message' = 'This is a test entry'
            'AD.SamAccountName' = 'MyCoolAccount'
            'PoSH.Error' = 'Woops, my script threw an error!'
        }

        $Logs = [System.Collections.Generic.List[hashtable]]::new()
        for ($i=0; $i -lt 100; $i++){
            $Logs.Add($LogTemplate)
        }
        $Logs = $Logs.ToArray()

        $Params = @{
            'Index' = 'log_ps_test'
            'Logs' = $Logs
            'DisableLocalLog' = $true
        }
        Add-OSLogPSBulk @Params | Should -BeNullOrEmpty -Because 'Success returns $null'
    }

    It 'Fails when using invalid index name' {
        $LogTemplate = @{
            'LogLevel' = 'Information'
            '@timestamp' = $(Get-Date)
            'Message' = 'This is a test entry'
        }

        $Logs = [System.Collections.Generic.List[hashtable]]::new()
        for ($i=0; $i -lt 100; $i++){
            $Logs.Add($LogTemplate)
        }
        $Logs = $Logs.ToArray()

        $Params = @{
            'Logs' = $Logs
            'Index' = 'NotAPSIndex'
            'DisableLocalLog' = $true
        }

        { $Response = Add-OSLogPSBulk @Params } | Should -Throw 'IndexName must be: log_ps_misc OR match the format: log_ps_{SCRIPT NAME}_{OPTIONAL HOSTNAME}-{OPTIONAL EXTRA INFO}'
    }

    It 'Fails when LogLevel is not included' {
        $LogTemplate = @{
            '@timestamp' = $(Get-Date)
            'Message' = 'This is a test entry'
        }

        $Logs = [System.Collections.Generic.List[hashtable]]::new()
        for ($i=0; $i -lt 100; $i++){
            $Logs.Add($LogTemplate)
        }
        $Logs = $Logs.ToArray()

        $Params = @{
            'Logs' = $Logs
            'Index' = 'log_ps_test'
            'DisableLocalLog' = $true
        }

        { $Response = Add-OSLogPSBulk @Params } | Should -Throw "LogLevel must be one of the following options: Trace, Verbose, Information, Warning, Error, Critical`nYour provided level: "
    }

    It 'Fails with invalid options from OpenSearch-PoSHNamingStandard.json' {
        $LogTemplate = @{
            'LogLevel' = 'Information'
            '@timestamp' = $(Get-Date)
            'Message' = 'This is a test entry'
            'ImNotApproved.Bad' = 'IWillFail'
        }

        $Logs = [System.Collections.Generic.List[hashtable]]::new()
        for ($i=0; $i -lt 100; $i++){
            $Logs.Add($LogTemplate)
        }
        $Logs = $Logs.ToArray()

        $Params = @{
            'Index' = 'log_ps_test'
            'Logs' = $Logs
            'DisableLocalLog' = $true
        }
        { Add-OSLogPSBulk @Params } | Should -Throw 'Unapproved field names found: ImNotApproved.Bad'
    }
    #endregion

    #region Log Files
    It 'Adds content to local log file' {
        $LogTemplate = @{
            'LogLevel' = 'Information'
            '@timestamp' = $(Get-Date)
            'Message' = 'This is a test entry'
            'AD.SamAccountName' = 'MyCoolAccount'
            'PoSH.Error' = 'Woops, my script threw an error!'
        }

        $Logs = [System.Collections.Generic.List[hashtable]]::new()
        for ($i=0; $i -lt 100; $i++){
            $Logs.Add($LogTemplate)
        }
        $Logs = $Logs.ToArray()

        $Params = @{
            'Index' = 'log_ps_test'
            'Logs' = $Logs
        }
        Add-OSLogPSBulk @Params | Should -BeNullOrEmpty -Because 'Success returns $null'

        Test-Path -Path $DefaultLogFilePath | Should -BeTrue -Because 'Default log file should be created'
    }

    It 'Adds content to specified log file' {
        $SpecificLogFilePath = "./SpecificLogFile.json"

        $LogTemplate = @{
            'LogLevel' = 'Information'
            '@timestamp' = $(Get-Date)
            'Message' = 'This is a test entry'
            'AD.SamAccountName' = 'MyCoolAccount'
            'PoSH.Error' = 'Woops, my script threw an error!'
        }

        $Logs = [System.Collections.Generic.List[hashtable]]::new()
        for ($i=0; $i -lt 100; $i++){
            $Logs.Add($LogTemplate)
        }
        $Logs = $Logs.ToArray()

        $Params = @{
            'Index' = 'log_ps_test'
            'Logs' = $Logs
            'LogFile' = $SpecificLogFilePath
        }
        Add-OSLogPSBulk @Params | Should -BeNullOrEmpty -Because 'Success returns $null'

        Test-Path -Path $SpecificLogFilePath | Should -BeTrue -Because 'Log file should be created'
        $LogContent = Get-Content -Path $SpecificLogFilePath | ConvertFrom-Json -Depth 100

        $LogContent.GetType().BaseType.FullName | Should -Be 'System.Array' -Because 'Log content as stored as a JSON array'
        $LogContent.Count | Should -Be 100 -Because '100 log entries were added'
    }
    #endregion
}

AfterAll {
    Remove-OSIndex -Index 'log_ps_test' -NoConfirm

    Remove-Item -Path "$global:PSScriptRoot\Logs\" -Recurse -ErrorAction SilentlyContinue
}
