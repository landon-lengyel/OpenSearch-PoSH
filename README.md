# OpenSearch-PoSH
[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/OpenSearch-PoSH?label=PowerShell%20Gallery)](https://www.powershellgallery.com/packages/OpenSearch-PoSH)
[![Minimum Supported PowerShell Version](https://img.shields.io/badge/PowerShell-7.0-blue.svg)](https://github.com/landon-lengyel/OpenSearch-PoSH)

This module attempts to make OpenSearch management easier for syadmins, by exposing the API in a more PowerShell friendly way. It can be used to assist with scripting, or as a CLI for assisting with OpenSearch management tasks.

# Config File
The config file isn't required, and you can specify your nodes URL and credentials each time it runs. The config file allows you to bypass that and really helps makes the module useful as a CLI.

An empty config file can be generated with `New-OSConfigFile` and will be placed in the current directory.
You should configure the `Nodes` section with a list of your node(s), and one of the authentication methods.

The config file will be loaded from the following **paths in order**:
1. `.\PoSHOpenSearchConfig.json`
2. `$env:USERPROFILE\Documents\PoSHOpenSearchConfig.json`
3. `C:\ProgramData\PoSHOpenSearchConfig.json`

> Note: Keep in mind that due to this order, the **Start In** option in Task Scheduler becomes very important.

> Tip: The third option can be combined with the `WindowsUserCertificate` authentication and an Active Directory Certificate Services template to deploy the module to client workstations and have logs sent with the logged in users permissions.

## Authentication
Authentication can be passed each time a function is run, and handled entirely by your script or manually entered if you choose. The rest of the modules functions support both certificate objects for user certificate authentication (preferred), or PSCredential objects for basic auth.

The easier option is to utilize the modules config file.  If you configure multiple, then additional authentication options will be used in this order:

1. `WindowsUserCertificate` (Specific Thumbprint)
2. `WindowsUSerCertificate` (Any from the specified Template)
3. `Certificate` (Pfx File)
4. `BasicAuth`

### WindowsUserCertificate
**Client Configuration**:
This configuration is for certificates in your Windows user store.
If you have a specific certificate in mind, simply add the certificates `Thumbprint` to the config and it will always use that one.

If you have a template configured in Active Directory Certificate Services, you may utilize the the `TemplateName` for the module to automatically grab a valid certificate generated with that template from your user store.
If you optionally also specify a `TemplateOid`, then the module will attempt to request a new certificate from Active Directory Certificate Services using that template, in the case where it can't find a valid one that already exists in the store.

> Tip: This is a great option if you are mass deploying the module to client machines and you can't manually add certificates for each client machine.

### Certificate
This utilizes a specific `.pfx` file at a specified location. This can be useful if you're on non-Windows platforms.
Specify the `.pfx` file path with `CertificatePfxPath` option. The `pfx` file must contain a certificate, and key.

> Note: Use forward slashes for paths. Json uses backslashes as escape characters.

### Basic Authentication
This option is not preferred. It is significantly less secure overall than using certificate authentication, and of course you need to ensure access permissions on your config file are such that non-authorized users cannot access the username/password combination.

**Client Configuration**:
Specify the `Username` and `Password` under `BasicAuth` and it will utilize the rest.

# PowerShell Logs
Some functions are designed specifically for logging PowerShell script output. This is very useful when you have many scripts running automatically in your environment. You *do not* have to use these functions to utilize the rest of the module.
- `Add-OSLogPS`
- `Find-OSLogPS`

The functions expect the Indices to follow the naming standard: `log_ps_{My Custom Name}`
So you could use, for example:
- `log_ps_activedirectory`
- `log_ps_entraid`
- `log_ps_dhcp`

## Field Naming Standard
See [[OpenSearch Processes]] for more information around naming standards.

**About**:
The naming standard prevents uploading fields that aren't specified in the naming standard file from uploading with the `Add-OSLogPS` function. This is useful for keeping the logs field names consistent, and easily searchable. The field naming standard itself is configurable by you.

If you want to use the PowerShell logging functions, but not the field naming standard option then simply don't specify it in your config file.

**Configuration**:
The field naming standard's file path is configured in the config file described above. You can source a second config file containing just a Json array of the field names with the `AllowedAttributesPath` option. See the `OpenSearch-PoSHNamingStandard.json` as an example using some AD fields, and some other custom ones.

> Note: Use forward slashes for paths. Json uses backslashes as escape characters.
