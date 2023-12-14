
function Get-SqlBitsServiceSession {
    <#
    .SYNOPSIS
        Gets the Service sessions from the Sessionize API.

    .DESCRIPTION
        Gets all the Service sessions from the Sessionize API and outputs to json, excel,   psobject, html or csv

    .PARAMETER type
        The type parameter accepts a string that specifies the type of the session. Valid options   are 'Break', 'Sponsor50', 'Sponsor20', 'Microsoft', 'Lunch', 'Other', 'All'. The default  value is 'All'.

    .PARAMETER show
        The show parameter accepts a string that specifies the level of detail of the session   information. Valid options are 'Brief', 'Detailed', 'All'. The default value is 'Detailed'.

    .PARAMETER day
        The day parameter accepts a string that specifies the day of the session. Valid options     are 'Wed', 'Thurs', 'Fri', 'Sat', 'All'. The default value is 'All'.

    .EXAMPLE
        Get-SqlBitsServiceSession -type 'Sponsor50' -show 'Detailed'

        This example retrieves all 'Sponsor50' type sessions with 'Detailed' information for all days.

    .EXAMPLE
        Get-SqlBitsServiceSession -type 'Break' -show 'Detailed' -day 'Wed'

        This example retrieves all Breaks with 'Detailed' information for 'Wednesday'.

    .EXAMPLE
        Get-SqlBitsServiceSession -type 'Microsoft' -show 'Brief' -day 'All'

        This example retrieves all 'Microsoft' sessions with 'Brief' information for all days.

    .NOTES
        Rob Sewell
#>
    [CmdletBinding()]
    param (
        [string]
        [ValidateSet('Break', 'Sponsor50', 'Sponsor20', 'Microsoft', 'Lunch', 'Other', 'All')]
        $type = 'All',
        [string]
        [ValidateSet('Brief', 'Detailed', 'All')]
        $show = 'Detailed',
        [string]
        [ValidateSet('Wed', 'Thurs', 'Fri', 'Sat', 'All')]
        $day = 'All'

    )

    $BaseUri = 'https://sessionize.com/api/v2/8utc2qgu/view/GridSmart'

    $Data = Invoke-RestMethod -Uri $BaseUri

    if (-not $Data) {
        Write-Warning 'No data returned from Sessionize API'
        return
    }

    $filteredSessions = $data | ForEach-Object {
        $_.rooms | ForEach-Object {
            $_.sessions | ForEach-Object {
                if ($_.IsServiceSession) {
                    [PSCustomObject]@{
                        id               = $_.id
                        title            = $_.title
                        description      = $_.description
                        Day              = $_.startsAt.DayOfWeek
                        startsAt         = $_.startsAt
                        endsAt           = $_.endsAt
                        isServiceSession = $_.isServiceSession
                        isPlenumSession  = $_.isPlenumSession
                        speakers         = $_.speakers
                        categories       = $_.categories
                        roomId           = $_.roomId
                        room             = $_.room
                        liveUrl          = $_.liveUrl
                        recordingUrl     = $_.recordingUrl
                        status           = $_.status
                        isInformed       = $_.isInformed
                        isConfirmed      = $_.isConfirmed
                    }
                }
            }
        }
    }
    switch ($day) {
        'Wed' { $filteredSessions = $filteredSessions | Where-Object { $_.Day -eq 'Wednesday' } }
        'Thurs' { $filteredSessions = $filteredSessions | Where-Object { $_.Day -eq 'Thursday' } }
        'Fri' { $filteredSessions = $filteredSessions | Where-Object { $_.Day -eq 'Friday' } }
        'Sat' { $filteredSessions = $filteredSessions | Where-Object { $_.Day -eq 'Saturday' } }
        'All' { }
    }

    switch ($type) {
        'Break' {
            $output = $filteredSessions | Where-Object { $_.title -like '*break*' }
        }
        'Sponsor50' {
            $output = $filteredSessions | Where-Object { $_.title -like '*Sponsor*Session*50*' }
        }
        'Sponsor20' {
            $output = $filteredSessions | Where-Object { $_.title -like '*Sponsor*Session*20*' }
        }
        'Microsoft' {
            $output = $filteredSessions | Where-Object { $_.title -like '*Microsoft*' }
        }
        'Lunch' {
            $output = $filteredSessions | Where-Object { $_.title -like '*lunch*' }
        }
        'Other' {
            $output = $filteredSessions | Where-Object { $_.title -notlike '*lunch*' } | Where-Object { $_.title -notlike '*Microsoft*' } | Where-Object { $_.title -notlike '*Sponsor*' }
        }
        'All' {
            $output = $filteredSessions
        }
        Default {
            $output = $filteredSessions
        }
    }

    switch ($show) {
        'Brief' { $Output | Select-Object Day, title, startsAt }
        'Detailed' { $output | Select-Object  Day, title, description, startsAt, endsAt }
        'All' { $output }
    }
}

