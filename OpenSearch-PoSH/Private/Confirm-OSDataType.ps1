function Confirm-OSDataType {
    <#
    .SYNOPSIS
        Used by other functions. Verifies data type is valid in OpenSearch. Returns $true if valid.

    .PARAMETER DataTypes
        Hashtable of name/datatype pairs to verify.
    #>
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$DataTypes
    )

    # Based on: https://opensearch.org/docs/latest/field-types/supported-field-types/index/
    $AcceptedTypes = [System.Collections.Generic.HashSet[string]]@('alias','binary','byte','double','float',
        'half_float','integer','long','unsigned_long',
        'scaled_float','short','boolean','date',
        'date_nanos','ip','integer_range','long_range',
        'double_range','float_range','date_range','ip_range',
        'object','nested','flat_object','join',
        'keyword','text','token_count','completion',
        'search_as_you_type','geo_point','geo_shape','rank_feature',
        'rank_features','knn_vector','percolator')
    foreach ($Field in $DataTypes.keys){
        if (-not $AcceptedTypes.Contains($DataTypes.$Field)){
            throw [System.Management.Automation.PSInvalidCastException] "DataTypeMismatch: $DataTypes[$Field]"
            return $False
        }
    }

    return $True

}

