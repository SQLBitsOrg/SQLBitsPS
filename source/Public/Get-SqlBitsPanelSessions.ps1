function Get-SqlBitsPanelSessions {
    <#
    .SYNOPSIS
    Gets all the SQLBits sessions that have more than one speaker

    .DESCRIPTION
    Gets all the SQLBits sessions that have more than one speaker

    .PARAMETER ExcludeCommunityCorner
    Exclude the Community Corner sessions

    .EXAMPLE
    Get-SqlBitsPanelSessions

    Returns all the SQLBits sessions that have more than one speaker

    .EXAMPLE
    Get-SqlBitsPanelSessions -ExcludeCommunityCorner

    Returns all the SQLBits sessions that have more than one speaker excluding the Community Corner sessions

    .NOTES
    Rob Sewell, 2020
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $ExcludeCommunityCorner,
        [switch]
        $includeSponsorSessions
    )
    if (-not $includeSponsorSessions) {
        $excludedSessions = @(
            "Data Modernization in a Hybrid World",
            "Azure Stack HCI and Microsoft Hybrid Data Services",
            "The Microsoft Intelligent Data Platform and Dell"
        )
    } else {
        $excludedSessions = @()
    }

    $speakerCount = @{Name = 'NumberOfSpeakers'; Expression = { ($_.Speakers -split ',').Count } }

    switch ($ExcludeCommunityCorner) {
        $true {
            Get-SQLBitsSession | where room -NE 'Community Corner' | where title -NotIn $excludedSessions | select title, room, $speakerCount, startsAt, endsAt | where 'NumberOfSpeakers' -GT 2
        }
        $false {
            Get-SQLBitsSession | where title -NotIn $excludedSessions | select title, room, $speakerCount, startsAt, endsAt | where 'NumberOfSpeakers' -GT 2
        }
        Default {}
    }

}