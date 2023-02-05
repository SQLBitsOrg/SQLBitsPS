function Get-SQLBitsEmptySession {
    <#
    .SYNOPSIS
    A helper function to get the number of empty sessions at SQLBits
    
    .DESCRIPTION
    Just a helper function to get the number of empty sessions at SQLBits
    
    .PARAMETER output
    The type of output required. Valid values are Raw(default), Grouped or Total
    
    .EXAMPLE
    Get-SQLBitsEmptySessionCount 

         Day StartTime EndTime EmptySessions
         --- --------- ------- -------------
        Thursday 10:10     11:00               1
        Thursday 11:30     11:50               3
        Thursday 12:00     12:50               1
        Thursday 13:40     14:00               0
        Thursday 14:10     15:00               0

    Returns the number of empty sessions at SQLBits per time slot as a psobject

    .EXAMPLE

    Get-SQLBitsEmptySessionCount -output Grouped

    Name Count

    Thursday 4
    Friday 3
    Saturday 3

    Returns the number of empty sessions at SQLBits per day

    .EXAMPLE

    Get-SQLBitsEmptySessionCount -output Total

    10

    Returns the total number of empty sessions at SQLBits
    
    .NOTES
    Rob Sewell 2023
    #>
    [cmdletbinding()]
    Param(
        [Parameter()]
        [ValidateSet('Raw', 'Grouped', 'Total')]
        [string]
        $output = 'Raw'
    )
    $Schedule = Get-SQLBitsSchedule -output object
    $plenarysessions = 'Registration', 'Quick Break', 'Closing Keynote and Prize Giving', 'End - TearDown', 'Coffee Break', 'Lunch', 'Free Time', 'Prize Giving', 'Party', 'Pub Quiz', 'Keynote by The Community', 'End - TearDown'
    $KeyNotes = 'Keynote by The Community', 'Opening Keynote'

    $rawOutput = foreach ($time in $Schedule | Where-Object { $_.'All Rooms'.Trim() -notin $plenarysessions -and $_.Auditorium.Trim() -notin $KeyNotes }) {
        $SessionCount = ($time.psobject.Properties.Where{ $_.Name -ne 'All Rooms' }.Value -eq '
' ).Count
        $Message = "{0} {1} has {2} empty sessions" -f $time.Day, $time.StartTime, $SessionCount
        Write-PSFMessage $message -Level Verbose
        
        [pscustomobject]@{
            Day           = $time.Day
            StartTime     = $time.StartTime
            EndTime       = $time.EndTime
            EmptySessions = $SessionCount
        }
    }

    switch ($output) {
        'Raw' {
            $rawOutput
        }
        'Grouped' {
            $Summary = @{Name='EmptySessions';Expression={($_.Group | Measure-Object -Property EmptySessions -Sum).Sum}}
            $rawOutput | Group-Object Day | Select-Object Name, $Summary
        }
        'Total' {
            ($rawOutput | Measure-Object -Property EmptySessions -Sum).Sum
        }
        Default {
            $RawOutput
        }
    }
}