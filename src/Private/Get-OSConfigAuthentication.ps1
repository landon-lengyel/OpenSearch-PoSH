function Get-OSConfigAuthentication {
    <#
    .SYNOPSIS
        Returns PSCredential or certificate object depending on config.

    .PARAMETER ConfigData
        Data from the config file.

    .DESCRIPTION
        Using the preferred config file (passed in via ConfigData), it will return either a PSCredential object, or a certificate object depending on what's in ConfigData
        If multiple authentication options are in the ConfigData, it will throw an error.
        If no authentication options are configured, it will return $null
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $ConfigData
    )

    # Verify only one authentication method is specified
    $AuthMethodCounter = [System.Collections.Generic.List[String]]::new()
    if ($null -ne $ConfigData.Authentication.WindowsUserCertificate.Thumbprint){ [Void]$AuthMethodCounter.Add('Authentication.WindowsUserCertificate.Thumbprint') }
    if ($null -ne $ConfigData.Authentication.WindowsUserCertificate.TemplateName){ [Void]$AuthMethodCounter.Add('Authentication.WindowsUserCertificate.TemplateName') }
    if ($null -ne $ConfigData.Authentication.Certificate.CertificatePfxPath){ [Void]$AuthMethodCounter.Add('Authentication.Certificate.CertificatePfxPath') }
    if ($null -ne $ConfigData.Authentication.BasicAuth.Username -and
    $null -ne $ConfigData.Authentication.BasicAuth.Password){ [Void]$AuthMethodCounter.Add('Authentication.BasicAuth') }
    $AuthMethodCounter = $AuthMethodCounter.ToArray()

    if ($AuthMethodCounter.Count -gt 1){
        throw "The config file specifies multiple authentication methods. You must pick only one. You specified: $AuthMethodCounter"
    }

    # Specific WindowsUserCertificate
    if ($null -ne $ConfigData.Authentication.WindowsUserCertificate.Thumbprint){
        $Certificate = Get-Item -Path "Cert:\CurrentUser\My\$($ConfigData.Authentication.WindowsUserCertificate.Thumbprint)"

        if ($Certificate.HasPrivateKey -ne $True){ continue }
        if ($Certificate.NotAfter -le $(Get-Date)){ continue }
        if ($Certificate.NotBefore -ge $(Get-Date)){ continue }

        return $Certificate
    }
    # Unspecific WindowsUserCertificate - Try to request one if we know the specific template's OID
    if ($null -ne $ConfigData.Authentication.WindowsUserCertificate.TemplateName){
        $TemplateName = $ConfigData.Authentication.WindowsUserCertificate.TemplateName

        $UserCertificates = Get-ChildItem -Recurse -Path 'Cert:\CurrentUser\My\'

        foreach ($Certificate in $UserCertificates){
            # Skip if certificate is invalid
            if ($Certificate.HasPrivateKey -ne $True){ continue }
            if ($Certificate.NotAfter -le $(Get-Date)){ continue }
            if ($Certificate.NotBefore -ge $(Get-Date)){ continue }

            # This is the Oid for template names
            $Extension = $Certificate.Extensions | Where-Object {$_.Oid.Value -eq '1.3.6.1.4.1.311.21.7'}

            # Check for $null first to avoid errors when calling .Format method
            if ($null -ne $Extension){
                if ($Extension.Format(1) -match '^Template=(.+)\([0-9\.]+\)'){
                    if ($Matches[1] -eq $TemplateName){
                        return $Certificate
                    }
                }
            }
        }

        # Existing certificate not found. If there's an OID specified, request one from AD CS
        if ($null -ne $ConfigData.Authentication.WindowsUserCertificate.TemplateOid){
            $TemplateOid = $ConfigData.Authentication.WindowsUserCertificate.TemplateOid

            $Certificate = $null
            $Certificate = Get-Certificate -Template $TemplateOid -CertStoreLocation 'Cert:\CurrentUser\My' -Url ldap: -ErrorAction Continue

            if ($null -ne $Certificate){
                return $Certificate
            }
        }
    }
    # Specified PFX Certificate file
    if ($null -ne $ConfigData.Authentication.Certificate.CertificatePfxPath){
        # Build certificate object
        $Certificate = Get-PfxCertificate -FilePath $ConfigData.Authentication.Certificate.CertificatePfxPath

        return $Certificate
    }
    # BasicAuth - last option
    if ($null -ne $ConfigData.Authentication.BasicAuth.Username -and
    $null -ne $ConfigData.Authentication.BasicAuth.Password){
        # Build PSCredential object
        $OpenSearchUsername = $ConfigData.Authentication.BasicAuth.Username
        $OpenSearchPassword = ConvertTo-SecureString -AsPlainText -Force $ConfigData.Authentication.BasicAuth.Password
        $OpenSearchCredential = New-Object PSCredential $OpenSearchUsername, $OpenSearchPassword

        return $OpenSearchCredential
    }

    # OpenSearch may not have security plugin enabled, so proceed
    return $null
    #throw [System.Configuration.ConfigurationException] "Could not find a supported authentication method in the config file."
}

