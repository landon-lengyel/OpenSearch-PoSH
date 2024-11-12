BeforeAll {
    Import-Module "./OpenSearch-PoSH/OpenSearch-PoSH.psd1" -Force
}

Describe 'Disable-OSShardAllocation' {
    It 'Disables cluster shard allocation' {
        Disable-OSShardAllocation | Should -Be $null -Because 'Success returns no value'

        $settings = Get-OSClusterSetting
        $settings.persistent.cluster.routing.allocation.enable | Should -Be 'none' -Because 'Shard allocation was successfully disabled'
    }
}

Describe 'Enable-OSShardAllocation' {
    It 'Enables cluster shard allocation for only primary indices' {
        Enable-OSShardAllocation -ShardType 'primaries' | Should -Be $null -Because 'Success returns no value'

        $settings = Get-OSClusterSetting
        $settings.persistent.cluster.routing.allocation.enable | Should -Be 'primaries' -Because 'Shard allocation was successfully enabled for primary indices only'
    }

    It 'Enables cluster shard allocation for only new primary indices' {
        Enable-OSShardAllocation -ShardType 'new_primaries' | Should -Be $null -Because 'Success returns no value'

        $settings = Get-OSClusterSetting
        $settings.persistent.cluster.routing.allocation.enable | Should -Be 'new_primaries' -Because 'Shard allocation was successfully enabled for new primary indices only'
    }

    It 'Enables cluster shard allocation' {
        Enable-OSShardAllocation | Should -Be $null -Because 'Success returns no value'

        $settings = Get-OSClusterSetting
        $settings.persistent.cluster.routing.allocation.enable | Should -Be 'all' -Because 'Shard allocation was successfully enabled'
    }
}
