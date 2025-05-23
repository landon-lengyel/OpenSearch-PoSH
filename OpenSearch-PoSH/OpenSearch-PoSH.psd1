#
# Module manifest for module 'OpenSearch'
#
# Generated by: Landon Lengyel
#
# Generated on: 6/24/2024
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'OpenSearch-PoSH.psm1'

# Version number of this module.
ModuleVersion = '0.3.5'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'c2d5fef3-a5c6-4be8-a39d-a45ee1c127e2'

# Author of this module
Author = 'Landon Lengyel'

# Company or vendor of this module
#CompanyName = 'Unknown'

# Copyright statement for this module
#Copyright = '(c) Landon Lengyel. All rights reserved.'

# Description of the functionality provided by this module
Description = 'This modules goal is to allow administrators to monitor, manage, and add to OpenSearch in a familiar way with Powershell.'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '7.0'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
#'Confirm-OSDataType', 'Confirm-OSFieldNamingStandard', 'Convert-OSAdditionalParam'
#'Find-OSBulkError', 'Get-OSConfigAuthentication', 'Get-OSConfigNode', 'Import-OSConfigFile',
#'Invoke-OSCustomWebRequest', 'New-OSConfigFile',
    FunctionsToExport = @('Add-OSIsmPolicy', 'Add-OSLogPS', 'Add-OSLogPSBulk', 'Confirm-OSIndexExist', 'Copy-OSIsmPolicy', 'Disable-OSIndexWrite',
        'Disable-OSShardAllocation', 'Disable-OSPerformanceAnalyzer', 'Enable-OSIndexWrite', 'Enable-OSPerformanceanalyzer', 'Enable-OSShardAllocation', 'Find-OS',
        'Find-OSIndexPatternId', 'Find-OSLogPS', 'Find-OSVisualizationsById' , 'Get-OSAlias', 'Get-OSCatHeader',
        'Get-OSClusterHealth', 'Get-OSClusterSetting', 'Get-OSClusterShardAllocation', 'Get-OSDataStream' , 'Get-OSIndex',
        'Get-OSIndexCount', 'Get-OSIndexMapping', 'Get-OSIndexSetting', 'Get-OSIngestPipeline', 'Get-OSIsm',
        'Get-OSIsmPolicyContent', 'Get-OSNode', 'Get-OSNodeProperty', 'Get-OSPerformanceAnalyzerStatus', 'Get-OSSegment', 'Get-OSShard', 'Get-OSShardRecovery',
        'Get-OSStorageAllocation', 'Get-OSTask', 'Import-OSAllBulkDocument', 'Import-OSDocument',
        'Import-OSUniqueBulkDocument', 'Initialize-OSDataStream', 'Initialize-OSIndexBeta', 'Initialize-OSPSLog',
        'Invoke-OSIsmRetry', 'Invoke-OSReIndex', 'New-OSAlias', 'New-OSConfigFile', 'New-OSIndex', 'New-OSIngestPipeline', 'Remove-OSDataStream', 'Remove-OSIndex',
        'Remove-OSIngestPipeline', 'Remove-OSIsmPolicy', 'Start-OSClusterShardReroute', 'Stop-OSTask',
        'Update-OSDashboardsObject', 'Update-OSIsmPolicy'
    )

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
#CmdletsToExport = @()
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{
        Title = 'OpenSearch-PoSH'

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('Windows','Linux','macOS','OpenSearch','Logging','Monitoring')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/landon-lengyel/OpenSearch-PoSH/tree/main?tab=GPL-3.0-1-ov-file'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/landon-lengyel/OpenSearch-PoSH'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

        # Prerelease string of this module
        Prerelease = 'beta'

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}
