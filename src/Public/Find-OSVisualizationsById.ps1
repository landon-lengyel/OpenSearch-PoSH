function Find-OSVisualizationsById {
    <#
    .SYNOPSIS
        Finds all OpenSearch Dashboards visualizations associated with an Index Pattern ID

    .DESCRIPTION
        Takes an ID of an Index Pattern, and returns an array of objects representing visualizations. Can be useful when you need to re-create an Index Pattern and move it's visualizations.

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.

    .PARAMETER DashboardsIndexId
        Specify ID of the OpenSearch Dashboards index.

    .PARAMETER DashboardsIndexName
        Specify name of the OpenSearch Dashboards index. Defaults to .kibana
    #>
    [OutputType([array])]
    [CmdletBinding()]
    param(
        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL,

        [Parameter(Mandatory=$true)]
        [string]$DashboardsIndexId,

        [string]$DashboardsIndexName='.kibana'
    )

    # Build request body to find all Visualizations that match the $DashboardsIndexId
    $Body = @{
        'query' = @{
            'bool' = @{
                'must' = @(
                    @{
                        'match' = @{
                            'type' = 'visualization'
                        }
                    },
                    @{
                        'nested' = @{
                            'path' = 'references'
                            'query' = @{
                                'bool' = @{
                                    'must' = @(
                                        @{
                                            'term' = @{
                                                'references.id' = @{
                                                    'value' = $DashboardsIndexId
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                )
            }
        }
    } | ConvertTo-Json -Depth 100

    $Request = $DashboardsIndexName + '/_search'
    $Response = Invoke-OSCustomWebRequest -OpenSearchUrls $OpenSearchURL -Request $Request -Method "GET" -Credential $Credential -Certificate $Certificate -Body $Body

    if ($Response.StatusCode -eq 200){
        $ResponseContent = $Response.Content | ConvertFrom-Json -Depth 100
        return $ResponseContent
    }
    # Throw the full response if there was an error so it may be handled
    else {
        throw $Response
    }

}

Export-ModuleMember -Function Find-OSVisualizationsById

