
function Get-SQLBitsSession {
<#
.SYNOPSIS
Gets the sessions from the Sessionize API.

.DESCRIPTION
Gets all the sessions from the Sessionize API and outputs to json, excel, psobject, html or csv

.PARAMETER search
searches all properties for the search term

.PARAMETER all
returns all the sessions

.EXAMPLE
Get-SQLBitsSession -search 'Power Bi'

Searches for the term 'Power Bi' in all the sessions

.EXAMPLE
Get-SQLBitsSession -search 'Community Corner'

Searches for all the sessions in the Community Corner

.EXAMPLE
Get-SQLBitsSession -search 'Rie Merritt'

Searches for all the sessions by Rie Merritt

.NOTES
Rob Sewell
#>
    [CmdletBinding()]
    param (
        [string]
        $search,
        [switch]
        $all
    )

    $BaseUri = 'https://sessionize.com/api/v2/u1qovn3p/view'
    $Date = Get-Date -Format 'yyyy-MM-dd-HH-mm-ss'

    #TODO Add other options
    $filter = 'Sessions'
    switch ($filter) {
        'All' {
            $uri = '{0}/All' -f $BaseUri
        }
        'Schedule' {
            $uri = '{0}/All' -f $BaseUri
        }
        'Sessions' {
            $uri = '{0}/sessions' -f $BaseUri
        }
        'speakers' {
            $uri = '{0}/speakers' -f $BaseUri
        }
        Default {
            $uri = '{0}/All' -f $BaseUri
        }
    }

    $Data = Invoke-RestMethod -Uri $uri

    if (-not $Data) {
        Write-Warning 'No data returned from Sessionize API'
        return
    }
    $sessions = ($data.sessions | Sort-Object id)


    if ($IsCoreCLR) {
        $rawsessions = $sessions
    } else {
        $rawsessions = $sessions | select -Property id, title, @{Name = 'startsAt'; expression = { [datetime]$_.startsAt } } , @{Name = 'endsAt'; expression = { [datetime]$_.endsAt } }, roomID, speakers

    }
    $Speakers = @{Name='Speakers'; Expression = {$PsItem.speakers.name -join ', '}}
    $PrimaryTheme = @{Name='PrimaryTheme'; Expression = {($PsItem.categories | Where Name -eq 'Primary Theme').categoryItems.name}}
    $SessionLength = @{Name='SessionLength'; Expression = {($PsItem.categories | Where id -eq 34075).categoryItems.name -replace ' sessoin', ''}}

    if($all){
        $rawsessions | Select title,description,startsAt,EndsAt,$Speakers,$PrimaryTheme,$SessionLength,room
    }else{
        if ($search) {

            $Results = @{Name = 'Results'; Expression = {
                    $_.psobject.properties.Value -like "*$search*"
                }
            }
        $rawsessions | Where-Object {$PSItem.isServiceSession -eq $false -and $PsItem.isPlenumSession -eq $false } | Select-Object -Property *, $Results | Where-Object { $null -ne $_.Results }  | Select title,description,startsAt,EndsAt,$Speakers,$PrimaryTheme,$SessionLength,room
        } else {
            $rawsessions | Where-Object {$PSItem.isServiceSession -eq $false -and $PsItem.isPlenumSession -eq $false } | Select title,description,startsAt,EndsAt,$Speakers,$PrimaryTheme,$SessionLength,room
        }
    }

}

