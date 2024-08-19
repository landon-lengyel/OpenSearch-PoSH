function New-OSConfigFile {
    <#
    .SYNOPSIS
        Create an empty config file with all possible options.

    .DESCRIPTION
        Create an empty config file with all possible options at the current directory named OpenSearchModule.json

    .PARAMETER Path
        Create the config file at this path and filename.

    .PARAMETER Force
        Overwite any existing file with the empty file.
    #>
    [CmdletBinding()]
    param(
        [string]$Path='./PoSHOpenSearchConfig.json',

        [switch]$Force
    )

    $BaseConfigContent = '{
    "Nodes": [
        "https://mynode.example.com:9200"
    ],
    "NodeOptions": {
        "AllowUnencryptedAuthentication": false,
        "SkipCertificateCheck": false
    },
    "Authentication": {
        "WindowsUserCertificate": {
            "Thumbprint": "",
            "TemplateName": "",
            "TemplateOid": ""
        },
        "Certificate": {
            "CertificatePfxPath": ""
        },
        "BasicAuth": {
            "Username": "",
            "Password": ""
        }
    },
    "PowerShellLogging": {
        "AllowedAttributes": [
            ""
        ],
        "AllowedAttributesPath": ""
    }
    }' | ConvertFrom-Json -Depth 100 | ConvertTo-Json -Depth 100    # Ensuring fomatting is pretty

    if (Test-Path $Path){
        if ($Force -ne $True){
            throw "File already exists. Not overwriting. Path: $Path"
        }
    }
    $BaseConfigContent | Out-File -FilePath $Path

    Write-Host "Config file created at: $Path"
    Write-Host "Specify your node(s) URLs with protocol and port number. Connection is attempted in the order specified."
    Write-Host "You need one authentication method (WindowsUserCertificate, Certificate, BasicAuth)"
    Write-Host "WindowsUserCertificate needs either a Thumbprint or TemplateName."

    return
}

Export-ModuleMember -Function New-OSConfigFile

