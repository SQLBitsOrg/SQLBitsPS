
#copilot wrote this
Describe 'Get-SqlBitsServiceSession' {
    # Test the function with the 'All' type, 'Detailed' show, and 'All' day
    It 'returns all sessions with detailed information for all days' {
        $result = Get-SqlBitsServiceSession -type 'All' -show 'Detailed' -day 'All'
        $result | Should -Not -BeNullOrEmpty
    }

    # Test the function with the 'Break' type, 'Brief' show, and 'Wed' day
    It 'returns break sessions with brief information for Wednesday' {
        $result = Get-SqlBitsServiceSession -type 'Break' -show 'Brief' -day 'Wed'
        $result | Should -Not -BeNullOrEmpty
    }

    # Test the function with an invalid type
    It 'throws an error for an invalid type' {
        { Get-SqlBitsServiceSession -type 'Invalid' -show 'Detailed' -day 'All' } | Should -Throw
    }

    # Test the function with an invalid show
    It 'throws an error for an invalid show' {
        { Get-SqlBitsServiceSession -type 'All' -show 'Invalid' -day 'All' } | Should -Throw
    }

    # Test the function with an invalid day
    It 'throws an error for an invalid day' {
        { Get-SqlBitsServiceSession -type 'All' -show 'Detailed' -day 'Invalid' } | Should -Throw
    }
}