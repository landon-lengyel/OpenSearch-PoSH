function Import-OSUniqueBulkDocument {
    <#
    .SYNOPSIS
        Takes an array of hashtables or PSCustomObjects, and bulk imports to an OpenSearch instance. _id will be a sha1 hash of document.

    .DESCRIPTION
        Takes an array of hashtables or PSCustomObjects. _id will be generated by module as a sha1 hash to avoid duplicate entries in OpenSearch. As such, documents imported without this specific function would be re-imported as duplicates.
        Uses the bulk import API to improve import speed of large quantetites of data.

    .PARAMETER Index
        Index you would like the data to be added to.

    .PARAMETER Documents
        Array of Hashtables or PSCustomObjects which will be indexed into OpenSearch.

    .PARAMETER UploadLimit
        Break up upload to this many files per attempt. Max 4999. Sometimes necessary if individual documents are large.

    .PARAMETER OpType
        Operation to perform on the API. This will default to index, and usually that is fine. Data streams need 'create'

    .PARAMETER Credential
        PSCredential for basic authentication to OpenSearch.

    .PARAMETER Certificate
        User certificate for certificate authentication to OpenSearch.

    .PARAMETER OpenSearchURL
        URL(s) to OpenSearch instance. Do not include any path or api endpoint.
    #>
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Index,

        [Parameter(Mandatory=$true, ValueFromPipeline)]
        [Array]$Documents,

        [Int64]$UploadLimit=4999,

        [ValidateSet('create','delete','index','update')]
        [string]$OpType='index',

        [System.Management.Automation.Credential()]
        [PSCredential]$Credential=[PSCredential]::Empty,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        $OpenSearchURL
    )

    # Index names must be lowercase
    $Index = $Index.ToLower()

    # OpType must be lowercase
    $OpType = $OpType.ToLower()

    # OpenSearch defined limit for uploads is 4999, but there are entries for the action so x2
    if ($UploadLimit -gt 4999){
        $UploadLimit = 4999
    }
    $UploadLimit = $UploadLimit * 2

    # Prepare for generating sha256 hashes of documents later
    $sha256 = New-Object -TypeName System.Security.Cryptography.SHA256CryptoServiceProvider
    $utf8 = New-Object -TypeName System.Text.UTF8Encoding

    $DocumentList = [System.Collections.Generic.List[PSObject]]::new()

    # The _bulk api uses a really nasty JSON-esque format for it's data that's difficult to work with.
    # It requires every other line be an action, and the document itself to perform the action on.
    # See examples: https://opensearch.org/docs/latest/api-reference/document-apis/bulk/
    # Generate sha256 checksum's for each document, and use those as the _id to prevent duplicate documents.
    foreach ($Document in $Documents){
        # Using $sha256 and $utf8 generated outside of foreach loop
        # StringBuilder is like ArrayLists/Generic Lists for Strings
        $ObjectString = [System.Text.StringBuilder]::new()

        if ('PSCustomObject' -eq $Document.GetType().Name){
            foreach ($Property in ($Document.PSOBject.Properties | Sort-Object)){
                [Void]$ObjectString.Append($Property.Value)
            }
        }
        elseif ('Hashtable' -eq $Document.GetType().Name){
            foreach ($Key in ($Document.Keys | Sort-Object)){
                [Void]$ObjectString.Append($Document.$Key)
            }
        }
        else {
            throw [System.Management.Automation.ParameterBindingException] "Documents should be an array of hashtables preferably. PSCustomObjects are also allowed."
        }
        $ObjectString = $ObjectString.ToString()
        $DocumentId = [System.BitConverter]::ToString($sha256.ComputeHash($utf8.GetBytes($ObjectString)))

        # Generate action line
        $DocumentList.Add("{ `"$OpType`": { `"_index`": `"$Index`", `"_id`": `"$DocumentId`" } }")

        # Add nextline
        $DocumentList.Add($($Document | ConvertTo-Json -Depth 100 -Compress))
    }
    $DocumentList = $DocumentList.ToArray()

    # OpenSearch has a limit on how many records _bulk can handle at a time.
    # Split apart bulk requests to smaller chunks.
    if ($DocumentList.Count -gt $UploadLimit){
        # Keep track of bulk errors, throw if any are found, but complete the actions for the rest
        $BulkErrors = [System.Collections.Generic.List[PSObject]]::new()

        # Loop through $UploadLimit line increments
        for ($LineCounter = 0; $LineCounter -le $DocumentList.Count; $LineCounter += $UploadLimit){
            # Grab the next $UploadLimit lines (or less)
            $RequestBody = $DocumentList[$LineCounter..$($LineCounter+($UploadLimit - 1))]

            # Set the Output Field Seperator to a newline, then set it back. If you don't set it back, it will mess up errors in Invoke-OSCustomWebRequest (https://devblogs.microsoft.com/powershell/psmdtagfaq-what-is-ofs/)
            $OldOfs = $ofs
            $ofs = "`n"
            # Convert back to string
            $RequestBody = [String]$RequestBody
            $ofs = $OldOfs

            # Add a newline at the end
            $RequestBody += "`n"

            # Perform bulk request

            $Request = '/_bulk'
            $Response = Invoke-OSCustomWebRequest -OpenSearchUrls $OpenSearchURL -Request $Request -Method "POST" -Credential $Credential -Certificate $Certificatel -Body $RequestBody

            # Pass to bulk error handling function
            $TempErrors = Find-OSBulkError $Response
            if ($null -ne $TempErrors){
                $BulkErrors.Add($TempErrors)
            }
        }

        $Errors = $BulkErrors.ToArray()
    }
    # Current request body is sufficiently sized
    else {
        # Set the Output Field Seperator to a newline, then set it back. If you don't set it back, it will mess up errors in Invoke-OSCustomWebRequest (https://devblogs.microsoft.com/powershell/psmdtagfaq-what-is-ofs/)
        $OldOfs = $ofs
        $ofs = "`n"

        $RequestBody = [String]$DocumentList
        $ofs = $OldOfs

        # Add a newline at the end
        $RequestBody += "`n"

        # Perform bulk request
        $Request = '/_bulk'
        $Response = Invoke-OSCustomWebRequest -OpenSearchUrls $OpenSearchURL -Request $Request -Method "POST" -Credential $Credential -Certificate $Certificate -Body $RequestBody

        # Pass to bulk error handling function
        $Errors = Find-OSBulkError $Response
    }

    if ($Errors.Count -eq 0){
        return
    }
    else {
        throw $Errors
    }
}

Export-ModuleMember -Function Import-OSUniqueBulkDocument

