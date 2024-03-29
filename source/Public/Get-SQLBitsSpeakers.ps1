function Get-SQLBitsSpeakers {
    <#
    .SYNOPSIS
    Returns the SQLBits Speakers from the Sessionize API

    .DESCRIPTION
    This function returns the SQLBits Speakers from the Sessionize API

    .PARAMETER search
    Filters the results by the search term

    .PARAMETER remote
    A switch to filter the results to only remote speakers

    .PARAMETER full
    Returns the full object as output

    .EXAMPLE
    Get-SQLBitsSpeakers

    Returns all the SQLBits Speakers from the Sessionize API

    .EXAMPLE

    Get-SQLBitsSpeakers -search 'Rob'

    Returns all the SQLBits Speakers from the Sessionize API that contain Rob in their name

    .EXAMPLE

    Get-SQLBitsSpeakers -remote

    Returns all the SQLBits Speakers from the Sessionize API that are remote

    .EXAMPLE

    Get-SQLBitsSpeakers -full

    Returns all the SQLBits Speakers from the Sessionize API as a full object

    .NOTES
    Rob Sewell - January 2023
    #>
    [CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    <#Category#>'PSUseSingularNouns',<#CheckId#>$null,
    Justification = 'because my beard is glorious'
)]
    param (
        [Parameter(Mandatory = $false)]
        [string]$search,
        [switch]$remote,
        [switch]$full
    )
    begin {
        $BaseUri = 'https://sessionize.com/api/v2/8utc2qgu/view'
        $Date = Get-Date -Format 'yyyy-MM-dd-HH-mm-ss'
        $uri = '{0}/speakers' -f $BaseUri
        $sessionuri = '{0}/sessions' -f $BaseUri
        $AllSessions = Invoke-RestMethod -Uri $sessionuri

        $Isremote = @{Name='IsRemote';Expression={($_.categories | Where-Object {$_.id -eq '44351';}).categoryItems.name}}

        $CompanyName = @{Name='CompanyName';Expression={($_.questionAnswers | Where-Object {$_.id -eq 43369}).Answer}}
        $LinkedIn = @{Name='LinkedIn';Expression={($_.links | Where-Object {$_.linktype -eq 'LinkedIn'}).url}}
        $Sessionize = @{Name='Sessionize';Expression={($_.links | Where-Object {$_.linktype -eq 'Sessionize'}).url}}
        $Blog = @{Name='Blog';Expression={($_.links | Where-Object {$_.linktype -eq 'Blog'}).url}}
        $Facebook = @{Name='Facebook';Expression={($_.links | Where-Object {$_.linktype -eq 'Facebook'}).url}}
        $Twitter = @{Name='Twitter';Expression={($_.links | Where-Object {$_.linktype -eq 'Twitter'}).url}}
        $CompanyWebsite = @{Name='Company Website';Expression={($_.links | Where-Object {$_.linktype -eq 'Company Website'}).url}}
        $Other = @{Name='Other';Expression={($_.links | Where-Object {$_.linktype -eq 'Other'}) | ForEach-Object { $_ }}}
        $SessionNames = @{
            Name='SessionDetails';Expression={$_.sessions | ForEach-Object {
                $id = $_.id
                $Session = $AllSessions.Sessions|Where-Object{$_.id -eq $id}
                [PSCustomObject]@{
                    Name = $_.name.Trim()
                    Room = $Session.Room
                    Starts = $Session.startsAt
                    Ends = $Session.endsAt
                }
            }
        }
    }
        $Data = Invoke-RestMethod -Uri $uri
        $Data = $Data|Select-Object *,$CompanyName,$Isremote,$LinkedIn,$Sessionize,$Blog,$Facebook,$Twitter,$CompanyWebsite,$Other,$sessionNames
        if (-not $Data) {
            Write-Warning 'No data returned from Sessionize API'
            return
        }

    }
    process {
        if($search) {
            $Data = $Data | Where-Object { $_.fullName -like "*$search*" }
        }
        if($remote) {
            $Data = $Data | Where-Object { $_.IsRemote -eq 'Remote' }
        }
        if($full) {
            $Data | Select-Object -ExcludeProperty id,isTopSpeaker,questionAnswers,categories,links
        }
        else {
            $Data | Select-Object fullName, companyName,tagLine, $SessionNames
        }
    }
    end {
    }
}