function Convert-OSAdditionalParam {
    <#
    .SYNOPSIS
        Used by other functions to support arbitrary list of additional parameters. Returns arbitrary parameters as hashtable.

    .DESCRIPTION
        Allows other functions to support users inputting arbitrary additional parameters, beyond what was specified for the function.
        This is very useful for indices that may have additional fields the function doesn't know about, among other uses.
        AdditionalParams should be allowed in the function by adding: [Parameter(ValueFromRemainingArguments=$true)]

    .PARAMETER AdditionalParams
        Uses .NET class of List`1 but it is what additional parameters come through as.
    #>
    [OutputType([Hashtable])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $AdditionalParams
    )

    $AdditionalParamsHash = @{}
    # Convert string[] to hashtable. Alternating lines of key/value
    for ($StringCount=0; $StringCount -lt $AdditionalParams.Count; $StringCount++){
        if ($AdditionalParams[$StringCount] -match '^-'){
            # Remove the hyphen before the parameter name, and the colon after if applicable. Those are not needed with splatting.
            $Key = $AdditionalParams[$StringCount]
            $Key = $Key -replace '^-',''
            $Key = $Key -replace ':$',''
            # Only add the value if it's not a parameter (some parameters don't have a value)
            if ($AdditionalParams[$StringCount + 1] -match '^-'){
                $Value = $null
            }
            else {
                $Value = $AdditionalParams[$StringCount + 1]
            }

            $AdditionalParamsHash.Add($Key, $Value)
        }
    }

    return $AdditionalParamsHash
}

