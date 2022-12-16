BeforeAll {
    Mock -ModuleName SQLBitsPS Invoke-RestMethod { return [PSCustomObject]@{
        Data = [PSCustomObject]@{
            rooms = dummyRooms
        }
    }}
}

Describe "Get-SQLBitsSchedule" {

    Context "When the function is called" {

        It "Should return a psobject" {
            $result = Get-SQLBitsSchedule -Output object
            $result | Should -BeOfType System.Management.Automation.PSObject
        }

    }
}