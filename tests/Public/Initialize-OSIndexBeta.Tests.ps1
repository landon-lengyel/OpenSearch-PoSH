BeforeAll {
    Import-Module "./OpenSearch-PoSH/OpenSearch-PoSH.psd1" -Force
}

Describe 'Initialize-OSIndexBeta' {
    It 'Creates an empty index' {
        $hashtable = @{
            #Alias              = 'alias'    #The [path] property must be specified for field [Alias].
            Binary             = 'binary'
            Byte               = 'byte'
            Double             = 'double'
            Float              = 'float'
            HalfFloat          = 'half_float'
            Integer            = 'integer'
            Long               = 'long'
            UnsignedLong       = 'unsigned_long'
            #ScaledFloat        = 'scaled_float'    # Failed to parse mapping [_doc]: Field [scaling_factor] is required
            Short              = 'short'
            Boolean            = 'boolean'
            Date               = 'date'
            DateNanos          = 'date_nanos'
            Ip                 = 'ip'
            IntegerRange       = 'integer_range'
            LongRange          = 'long_range'
            DoubleRange        = 'double_range'
            FloatRange         = 'float_range'
            DateRange          = 'date_range'
            IpRange            = 'ip_range'
            Object             = 'object'
            Nested             = 'nested'
            FlatObject         = 'flat_object'
            Join               = 'join'
            Keyword            = 'keyword'
            Text               = 'text'
            #TokenCount         = 'token_count'      # Analyzer must be set for field [TokenCount] but wasn't.
            Completion         = 'completion'
            SearchAsYouType    = 'search_as_you_type'
            GeoPoint           = 'geo_point'
            GeoShape           = 'geo_shape'
            RankFeature        = 'rank_feature'
            RankFeatures       = 'rank_features'
            #KnnVector          = 'knn_vector'    # Dimension value missing for vector
            Percolator         = 'percolator'
        }
        Initialize-OSIndexBeta -Index 'Initialize-OSIndex_TestIndex' -DataTypes $hashtable | Should -BeNullOrEmpty -Because 'Successful creation outputs $null'
    }
}

AfterAll {
    Remove-OSIndex 'Initialize-OSIndex_TestIndex' -NoConfirm
}
