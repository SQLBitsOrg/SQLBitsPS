
function Get-SQLBitsSchedule {
    <#
    .SYNOPSIS
        Gets the SQLBits Schedule from the Sessionize API

    .DESCRIPTION
        Gets the SQLBits Schedule from the Sessionize API and outputs to json, excel, psobject, html or csv

    .PARAMETER output
        The type of output required. Valid values are json, excel, psobject, html or csv

    .PARAMETER search
        A wild card search beat used to find a speaker

    .PARAMETER fileDirectory
        The directory to save the output file to - defaults to Env:Temp

    .PARAMETER Show
        Whether to open the output file after it has been created

    .EXAMPLE
        Get-SQLBitsSchedule  -output Excel -Show

        Gets the SQLBits Schedule from the Sessionize API and outputs to excel, opens the file and saves it to the default temp directory

    .EXAMPLE
        Get-SQLBitsSchedule  -output Raw

        Gets the SQLBits Schedule from the Sessionize API and outputs as json on the screen

    .EXAMPLE
        Get-SQLBitsSchedule  -output csv -Show

        Gets the SQLBits Schedule from the Sessionize API and outputs to csv, opens the file and saves it to the default temp directory

    .EXAMPLE
        Get-SQLBitsSchedule  -output object

        Gets the SQLBits Schedule from the Sessionize API and outputs as a psobject on the screen

    .EXAMPLE
        Get-SQLBitsSchedule  -output html -Show

        Gets the SQLBits Schedule from the Sessionize API and outputs to html, opens the file and saves it to the default temp directory

    .EXAMPLE
        Get-SQLBitsSchedule -search Buck -output object | ft

            Day StartTime EndTime Room        speakers   Session
            --- --------- ------- ----        --------   -------
        Thursday 14:10     15:00   MR 1B       Buck Woody Arc, Arc and Arc: De-mystifying Azure Arc for Data…
        Friday 12:00     12:50   Expo Room 2 Buck Woody The Microsoft Intelligent Data Platform…

        Gets the SQLBits Schedule from the Sessionize API searches fro Buck and outputs an object

    .NOTES
        Author: Rob Sewell
        December 2022
#>
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet('raw', 'excel', 'object', 'csv', 'html')]
        $output = 'excel',
        [string]
        $search,
        [string]
        $fileDirectory = $env:TEMP,
        [switch]
        $show
    )

    $BaseUri = 'https://sessionize.com/api/v2/u1qovn3p/view'
    $Date = Get-Date -Format 'yyyy-MM-dd-HH-mm-ss'

    #TODO Add other options
    $filter = 'Schedule'
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
    $rooms = ($data.rooms | Sort-Object name)
    if (-not $rooms) {
        Write-Warning 'No rooms returned from Sessionize API'
        return
    }
    $speakers = $data.speakers
    if (-not $speakers) {
        Write-Warning 'No speakers returned from Sessionize API'
        return
    }
    # Thank you Shane - https://nocolumnname.blog/2020/10/29/pivot-in-powershell/
    $props = @(
        @{ Name = 'Day' ; Expression = { $Psitem.Group[0].startsAt.DayOfWeek } }
        @{ Name = 'Date' ; Expression = { $Psitem.Group[0].startsAt.tolongdatestring() } }
        @{ Name = 'StartTime' ; Expression = { $Psitem.Group[0].startsAt.ToShortTimeString() } }
        @{ Name = 'EndTime' ; Expression = { $Psitem.Group[0].EndsAt.ToShortTimeString() } }
        foreach ($room in $rooms) {
            $rn = $room.Name
            @{
                Name       = $rn
                Expression = {
                    '{0}
{1}'  -f @(
                        ($Psitem.Group | Where-Object { $PSItem.roomID -eq $room.id }).title,
                        (($Psitem.Group | Where-Object { $PSItem.roomID -eq $room.id }).speakers.ForEach{ $speakers | Where-Object id -EQ $_ }.FullName -join ' ')
                    )

                }.GetNewClosure()
            }
        }
    )
    if ($IsCoreCLR) {
        $rawsessions = $Data.sessions 
    } else {
        $rawsessions = $Data.sessions | select -Property id, title, @{Name = 'startsAt'; expression = { [datetime]$_.startsAt } } , @{Name = 'endsAt'; expression = { [datetime]$_.endsAt } }, roomID, speakers

    }
    $sessions = $rawsessions | Group-Object -Property StartsAt | Select-Object $props

    # if we have a search filter, filter the sessions
    if ($search) {
        $Results = @{Name = 'Results'; Expression = {
                $_.psobject.properties.Value -like "*$search*" 
            }
        }
        $RoomSearch = @{Name = 'Room'; Expression = {
            ($_.psobject.properties | Where-Object { $_.Value -like "*$search*" } ).Name
            }
        }
        $speakerSearch = @{Name = 'speakers'; Expression = { ($_.Results -Split "`n")[1] } }
        $Session = @{Name = 'Session'; Expression = { ($_.Results -Split "`n")[0] } }
        $sessions = $sessions | Select-Object -Property *, $RoomSearch, $Results | Where-Object { $null -ne $_.Results } | Select-Object -Property Day, StartTime, EndTime, Room, $speakerSearch, $Session
    }
    

    switch ($output) {
        'Raw' {
            $Data
        }
        'object' {
            $sessions
        }
        'Excel' {
            if (Get-Module -Name ImportExcel -ErrorAction SilentlyContinue -ListAvailable) {
                if ($filter -eq 'Schedule') {

                    $FilePath = '{0}\SQLBitsSchedule{1}_{2}.xlsx' -f $fileDirectory, $filter, $Date

                    $sessions | Group-Object Day | ForEach-Object {

                        $worksheetName = $_.Name
                        $excel = $_.Group | Export-Excel -Path $FilePath -WorksheetName $worksheetName -AutoSize  -FreezePane 2, 5 -PassThru
                        1..15 | ForEach-Object {
                            Set-ExcelRow -ExcelPackage $excel -WorksheetName $worksheetName -Row $_ -Height 30 -WrapText
                        }

                        $rulesparam = @{
                            Address   = $excel.Workbook.Worksheets[$WorkSheetName].Dimension.Address
                            WorkSheet = $excel.Workbook.Worksheets[$WorkSheetName]
                        }

                        Add-ConditionalFormatting @rulesparam -RuleType 'Expression'  -ConditionValue 'NOT(ISERROR(FIND("Coffee Break",$E1)))' -BackgroundColor GoldenRod -ForegroundColor White -StopIfTrue
                        Add-ConditionalFormatting @rulesparam -RuleType 'Expression'  -ConditionValue 'NOT(ISERROR(FIND("Quick Break",$E1)))' -BackgroundColor GoldenRod -ForegroundColor White -StopIfTrue
                        Add-ConditionalFormatting @rulesparam -RuleType 'Expression'  -ConditionValue 'NOT(ISERROR(FIND("Keynote",$E1)))' -BackgroundColor BlueViolet -ForegroundColor White -StopIfTrue
                        Add-ConditionalFormatting @rulesparam -RuleType 'Expression'  -ConditionValue 'NOT(ISERROR(FIND("Lunch",$E1)))' -BackgroundColor Chocolate  -ForegroundColor White -StopIfTrue
                        Add-ConditionalFormatting @rulesparam -RuleType 'Expression'  -ConditionValue 'NOT(ISERROR(FIND("Prize",$E1)))' -BackgroundColor PowderBlue  -ForegroundColor White -StopIfTrue
                        Add-ConditionalFormatting @rulesparam -RuleType 'Expression'  -ConditionValue 'NOT(ISERROR(FIND("Free Time",$E1)))' -BackgroundColor GoldenRod  -ForegroundColor White -StopIfTrue
                        Add-ConditionalFormatting @rulesparam -RuleType 'Expression'  -ConditionValue 'NOT(ISERROR(FIND("Registration",$E1)))' -BackgroundColor DarkOrange  -ForegroundColor White -StopIfTrue
                        Close-ExcelPackage $excel
                    }
                    if ($Show) {
                        Invoke-Item $filepath
                    } else {
                        Write-output "Excel file saved to $FilePath"
                    }
                }
            } else {
                Write-Warning 'You need to install ImportExcel to use this option but here is a CSV instead'
                $FilePath = '{0}\SQLBits_{1}_{2}.csv' -f $fileDirectory, $filter, $Date
                $sessions | Sort-Object Day, StartsAt | Export-Csv -Path $FilePath -NoTypeInformation
                if ($Show) {
                    Invoke-Item $filepath
                } else {
                    Write-output "Csv file saved to $FilePath"
                }
            }

        }
        'CSv' {
            $FilePath = '{0}\SQLBits_{1}_{2}.csv' -f $fileDirectory, $filter, $Date
            $sessions | Sort-Object Day, StartsAt | Export-Csv -Path $FilePath -NoTypeInformation
            if ($Show) {
                Invoke-Item $filepath
            } else {
                Write-output "Csv file saved to $FilePath"
            }
        }
        'html' {
            $FilePath = '{0}\SQLBits_{1}_{2}.html' -f $fileDirectory, $filter, $Date
            $sessions | ConvertTo-Html | Out-File $FilePath
            if ($Show) {
                Invoke-Item $filepath
            } else {
                Write-output "Html file saved to $FilePath"
            }
        }
        Default {

        }
    }
}