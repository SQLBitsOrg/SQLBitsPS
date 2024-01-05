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
        [ValidateSet('Raw','Grouped', 'Total')]
        [string]
        $output = 'Raw',
        [Parameter()]

        [switch]$excludeZeros
    )
    $Schedule = Get-SQLBitsSchedule -output object

    $KeyNotes = 'Keynote by The Community', 'Opening Keynote'
    $plenarysessions = 'Registration', 'Quick Break', 'Closing Keynote and Prize Giving', 'End - TearDown', 'Coffee Break', 'Lunch', 'Free Time', 'Prize Giving', 'Party', 'Pub Quiz', 'Keynote by the community', 'End - TearDown'

    $sessionss = $Schedule | Where-Object {($_.'Room 1'.Trim() -notin $plenarysessions ) -and  ($_.'Room 1'.Trim() -notlike 'KeyNote by the community*') }| Select-Object * -ExcludeProperty 'All Rooms'



    $rawOutput = foreach ($time in $sessionss) {
        $SessionCount = ($time.psobject.Properties.Where{$_.Value -eq '
' }).Count
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
            if($excludeZeros){
                $rawOutput | Where-Object { $_.EmptySessions -gt 0 }
            } else {
                $rawOutput
            }
        }
        'Grouped' {
            if($excludeZeros){
                Write-Output "Can't exclude zeros when grouping"
            }
            $Summary = @{Name='EmptySessions';Expression={($_.Group | Measure-Object -Property EmptySessions -Sum).Sum}}
            $rawOutput | Group-Object Day | Select-Object Name, $Summary
        }
        'Total' {
            if($excludeZeros){
                Write-Output "Can't exclude zeros when summing"
            }
            ($rawOutput | Measure-Object -Property EmptySessions -Sum).Sum
        }
        Default {
            $RawOutput
        }
    }
}