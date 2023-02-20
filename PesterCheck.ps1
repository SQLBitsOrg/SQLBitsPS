# Validates the Sessionize schedule against the Speaker Requests

BeforeDiscovery {

    switch ($env:computername) {
        'BEARD-DESKTOP' {
            $file = 'G:\SQLBits Limited (O365)\SQLBits portal - Shared Documents\2023\Speakers\SpeakerRequests.xlsx'
        }
        'BEARD-SURFACELA1' {
            $file = 'C:\Users\mrrob\SQLBits Limited (O365)\SQLBits portal - 2023\Speakers\SpeakerRequests.xlsx'
        }
        default {
            $file = Read-Host -Prompt 'Please enter the full path to the SpeakerRequests.xlsx file'
        }
    }
    $SpeakerRequests = Import-Excel -Path $file -WorksheetName SpeakerRequests

    $Schedule = Get-SQLBitsSchedule -output object
    $ScheduleSearch = Get-SQLBitsSchedule -output object -search *
    $plenarysessions = 'Registration', 'Quick Break', 'Closing Keynote and Prize Giving', 'End - TearDown', 'Coffee Break', 'Lunch', 'Free Time', 'Prize Giving', 'Party', 'Pub Quiz', 'Keynote by The Community'

    $Rooms = ($Schedule[0].psobject.properties | Where-Object { $_.Name -notin 'Day', 'Date', 'StartTime', 'EndTime', 'All Rooms' }).Name
    $Checking = $Schedule | Where-Object { $PsItem.'All Rooms'.Trim() -notin $plenarysessions -and $PsItem.Auditorium.Trim() -ne 'Opening Keynote' } | ForEach-Object {
        $Speakers = @{Name = 'Speakers'; Expression = { $_.psobject.properties | Where-Object Name -In $rooms | ForEach-Object { ($_.value -Split "`n")[1] } } }
        $PsItem | select Day, StartTime, EndTime, $Speakers
    }
    $Thursday = $Checking | Where-Object Day -EQ 'Thursday'
    $Friday = $Checking | Where-Object Day -EQ 'Friday'
    $Saturday = $Checking | Where-Object Day -EQ 'Saturday'
    $SponsoredRoom1Name = 'MR 2E'
    $SponsoredRoom2Name = 'MR 3E'
    $SponsoredRoom1Sessions = @{
        Name = 'Sponsored Room Session 1'
        Room = $SponsoredRoom1Name
    }, @{
        Name = 'Sponsored Room Session 2'
        Room = $SponsoredRoom1Name
    }, @{
        Name = 'Sponsored Room Session 3'
        Room = $SponsoredRoom1Name
    }, @{
        Name = 'Sponsored Room Session 4'
        Room = $SponsoredRoom1Name
    }, @{
        Name = 'Sponsored Room Session 5'
        Room = $SponsoredRoom1Name
    }, @{
        Name = 'Sponsored Room Session 6'
        Room = $SponsoredRoom1Name
    }, @{
        Name = 'Power BI governance, disaster recovery and auditing'
        Room = $SponsoredRoom2Name
    }, @{
        Name = 'Understanding and Managing Data Lineage in Power BI'
        Room = $SponsoredRoom2Name
    }, @{
        Name = 'Power Bi Composite and Hybrid models'
        Room = $SponsoredRoom2Name
    }
    $CommunityCorner = 'Community Corner'
    $CommunityCornerTitles = 'Meet the PG: SQL Leadership', 'Meet the PG: Azure SQL Managed Instance', 'Meet the PG: SQL Server on Azure VMs', 'Meet the PG: Microsoft Purview', 'Meet the PG: Just Use Extended Events Already with Erin Stellato', 'Meet the PG: Azure Synapse Analytics', 'Meet the PG: Azure Arc enabled SQL Server / Arc SQL MI', 'Meet the PG: Azure SQL', 'Meet the PG: SQL Server', 'Meet the PG: Power BI'


    $AllSpeakers = Get-SQLBitsSpeakers -full
    $RemoteRoom = 'MR 4'
}
BeforeAll {
    $Schedule = Get-SQLBitsSchedule -output object
    $RemoteRoom = 'MR 4'
    $CommunityCorner = 'Community Corner'

}

Describe "Ensuring <_.'Speaker Name'> available days are granted" -ForEach ($SpeakerRequests | where Available -NE 0) {
    BeforeDiscovery {
        $Available = $Psitem.Available
        $SpeakerName = $Psitem.'Speaker Name'
    }
    BeforeAll {
        $Available = $Psitem.Available
        $SpeakerName = $Psitem.'Speaker Name'
    }
    It "The Speaker $SpeakerName's session starting at <_.StartTime> on <_.Day> should be on the correct day $Available " -ForEach (($Checking | where Speakers -Like "*$SpeakerName*" )) {
        $Available.ToUpper().Replace('AM', '').Replace('PM', '').Replace(' ', '') | Should -BeLike "*$($PsItem.day.ToString().ToUpper())*"  -Because "The Speaker $SpeakerName should be on the correct day $Available "
    }
}

Describe "Ensuring <_.'Speaker Name'> available days AM and PM are granted" -ForEach ($SpeakerRequests | Where-Object { ($_.Available -like '*AM*') -or ($_.Available -like '*PM*') }) {
    BeforeDiscovery {
        $Available = $Psitem.Available
        $SpeakerName = $Psitem.'Speaker Name'.Trim()
    }
    BeforeAll {
        $Available = $Psitem.Available
        $SpeakerName = $Psitem.'Speaker Name'.Trim()
    }
    Context "Should be AM" -ForEach (@($Available) | Where-Object { $_ -like '*AM*' } ) {
        It "The Speaker $SpeakerName's session starting at <_.StartTime> on <_.Day> should be on the correct day $Available " -ForEach (($Checking | where Speakers -Like "*$SpeakerName*" )) {
            ([datetime]$Psitem.StartTime).Hour | Should -BeLessThan 13  -Because "The Speaker $SpeakerName should be in the AM"
            $Available.ToUpper().Replace('AM', '').Replace('PM', '').Replace(' ', '') | Should -BeLike "*$($PsItem.day.ToString().ToUpper())*"  -Because "The Speaker $SpeakerName should be on the correct day $Available "
        }
    }
    Context "Should be PM" -ForEach ($Available | Where-Object { $_ -like '*PM*' } ) {
        It "The Speaker $SpeakerName's session starting at <_.StartTime> on <_.Day> should be on the correct day $Available " -ForEach (($Checking | where Speakers -Like "*$SpeakerName*" )) {
            ([datetime]$Psitem.StartTime).Hour | Should -BeGreaterThan 12  -Because "The Speaker $SpeakerName should be in the PM"
            $Available.ToUpper().Replace('AM', '').Replace('PM', '').Replace(' ', '') | Should -BeLike "*$($PsItem.day.ToString().ToUpper())*"  -Because "The Speaker $SpeakerName should be on the correct day $Available "
        }
    }

}

Describe "Ensuring <_.'Speaker Name'> unavailable wishes are granted" -ForEach ($SpeakerRequests | where 'Not Available' -NE 0) {
    BeforeDiscovery {
        $NotAvailable = $Psitem.'Not Available'
        $SpeakerName = $Psitem.'Speaker Name'.Trim()
    }
    BeforeAll {
        $NotAvailable = $Psitem.'Not Available'
        $SpeakerName = $Psitem.'Speaker Name'.Trim()
    }
    It "$SpeakerName's session starting at <_.StartTime> on <_.Day> should not be scheduled on the wrong day $NotAvailable " -ForEach (($Checking | Where-Object { $_.Speakers -Like "*$SpeakerName*" -and $NotAvailable -notlike '*AM*' -and $NotAvailable -notlike '*PM*' })) {
        $NotAvailable.ToUpper().Replace('AM', '').Replace('PM', '').Replace(' ', '') | Should -Not -BeLike "*$($PsItem.day.ToString().ToUpper())*"  -Because "The Speaker $SpeakerName should not be on the wrong day $NotAvailable "
    }
}

Describe "Ensuring <_.'Speaker Name'> unavailable days AM and PM are granted" -ForEach ( $SpeakerRequests | Where-Object { ($_.'Not Available' -like '*AM*') -or ($_.'Not Available' -like '*PM*') }) {
    BeforeDiscovery {
        $NotAvailable = $Psitem.'Not Available'
        $SpeakerName = $Psitem.'Speaker Name'.Trim()
    }
    BeforeAll {
        $NotAvailable = $Psitem.'Not Available'
        $SpeakerName = $Psitem.'Speaker Name'.Trim()
    }
    Context "Should NOT be AM" -ForEach ($NotAvailable | Where-Object { $_ -like '*AM*' } ) {
        It "The Speaker $SpeakerName's session starting at <_.StartTime> on <_.Day> should be on the correct day $NotAvailable and time" -ForEach (($Checking | Where-Object { $_.Speakers -Like "*$SpeakerName*" -and $_.Day -eq $NotAvailable.ToUpper().Replace('AM', '').Replace('PM', '').Replace(' ', '') })) {
            ([datetime]$Psitem.StartTime).Hour | Should -BeGreaterThan 12  -Because "The Speaker $SpeakerName should not be in the AM"
        }
    }
    Context "Should NOT be PM" -ForEach ($NotAvailable | Where-Object { $_ -like '*PM*' } ) {
        It "The Speaker $SpeakerName's session starting at <_.StartTime> on <_.Day> should be on the correct day $NotAvailable and time" -ForEach (($Checking | Where-Object { $_.Speakers -Like "*$SpeakerName*" -and $_.Day -eq $NotAvailable.ToUpper().Replace('AM', '').Replace('PM', '').Replace(' ', '') } )) {
            ([datetime]$Psitem.StartTime).Hour | Should -BeLessThan 13  -Because "The Speaker $SpeakerName should not be in the PM"
        }
    }

}

Describe "Ensuring Sponsor sessions are in the correct room" {

    It "The session <_.Name> should be in the correct room <_.Room>" -ForEach $SponsoredRoom1Sessions {
        $Name = $Psitem.Name
        $Results = @{Name = 'Results'; Expression = {
                $_.psobject.properties.Value -like "*$Name*"
            }
        }
        (($Schedule | Select-Object -Property *, $Results | Where-Object { $null -ne $_.Results }).psobject.properties | Where-Object { $_.Value -like "*$Name*" } )[0].Name | Should -Be $Psitem.Room   -Because "The session $($Psitem.Name) should be in the room $($Psitem.Room)"
    }
}

Describe "Ensuring Community Corner sessions are in the correct room" {

    It "The session <_> should be in the correct room $CommunityCorner " -ForEach $CommunityCornerTitles {
        $Title = $_
        $Results = @{Name = 'Results'; Expression = {
            ($_.psobject.properties.Value -split "`n").Trim() -eq "$Title"
            }
        }
        $RommitIsIn = @{Name = 'RoomitisIn'; Expression = {
        ($_.psobject.properties | Where-Object {
         ($_.Value -split "`n").Trim() -eq "$Title" }).Name
            }
        }
        ($Schedule | Select-Object -Property *, $Results , $RommitIsIn | Where-Object { $_.Results -ne $null }).RoomItIsIn | Should -Be $CommunityCorner -Because "The session $($Psitem.Name) should be in the Community Corner "
    }
}

Describe "All the remote speakers should be in the correct room" {
    Context "<_.FullName> remote speaker" -ForEach ($AllSpeakers | Where-Object { $_.isRemote -eq 'Remote' }) {

        It "The Session <_.Name> in <_.Room> should be in the correct room $RemoteRoom " -ForEach ($Psitem.SessionNames) {
            $Psitem.Room | Should -Be $RemoteRoom   -Because "The session $($Psitem.Name) should be in the correct room $($Psitem.Room)"
        }
    }
}
