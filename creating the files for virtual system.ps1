# We need to have a Session and speakers advanced from Sessionize save as exportfromsessionize.xlsx in the /virtualplatform directory - This is in the gitignore so wont be uploaded to github
$FromSessionize = Import-Excel virtualplatform\exportfromsessionize.xlsx -WorksheetName 'Accepted Speakers'

$schedule = Get-SQLBitsSession
$SpeakersFromWeb = Get-SQLBitsSpeakers -full

# get the feedbacklinks from the database

$tenantId = '0e55cb3a-ac13-4147-b5b3-95d3992c19c8'
$subscriptionId = 'bc4bcbea-bf2e-413f-a348-f200705de7f0'
$context = Get-AzContext
if ($context.Tenant.Id -ne $tenantId) {
    Connect-AzAccount
}
if ( (Get-AzSubscription -WarningAction SilentlyContinue).SubscriptionId -ne $subscriptionId) {
    Write-Host "Switching to SQLBits Subscription"
    Select-AzSubscription -SubscriptionId $subscriptionId
}
$sqlInstance = 'sqlbitsweb.database.windows.net'
$azureToken = Get-AzAccessToken -ResourceUrl https://database.windows.net
$sqlbits = Connect-DbaInstance -SqlInstance $sqlInstance -Database SqlBits -AccessToken $azureToken
$query = "SELECT
F.[ConferenceAgendaId]
,F.[SessionId]
,F.[SessionTypeName]
,F.[Speaker]
,F.[Day]
,F.[Time]
,F.[Room]
,F.[Session]
,F.[FeedbackURL]
,F.[FeedbackURLShort]
,F.[QRCode]
,F.[QRCodeShort]
,tbl_s.ExternalId FROM [SpeakerFeedback].[FeedbackLink] F
  JOIN [dbo].[Session] tbl_s
  ON F.SessionID = tbl_s.Sessionid"
$feedbackLinks = Invoke-DbaQuery -SqlInstance $sqlbits -Query $query -As PSObject



$Sessions = foreach ($session in $schedule) {
   $FeedbackLink = 'Feedback Link :- {0}' -f ( ($feedbackLinks | Where-Object {$_.ExternalId -eq $session.id}).FeedbackURLShort)
     $Description = '{0} {1}' -f (-join $Session.description[0..4950]), $FeedbackLink
   #  $Description = '{0} {1}' -f $Session.description, $FeedbackLink
     $Speakers = $session.Speakers -split ', ' | ForEach-Object { $_.Trim() }
     $SpeakersInfo = ($Speakers | ForEach-Object {
        $Details = $SpeakersFromWeb | Where fullName -eq $_
        $SpeakersFromWeb | Where fullName -eq $_
        "{0},{1},{2}`n"  -f $Details.fullName, $Details.tagLine, $Details.CompanyName
     }) -join ''
    [pscustomobject]@{
        Session_name                 = $Session.title
        Session_start_date_time      = $session.startsat.ToString('yyyy-MM-dd HH:mm:00')
        Session_end_date_time        = $session.endsat.ToString('yyyy-MM-dd HH:mm:00')
Session_description          =   $Description
Session_status               = 'visible'
Session_speakers             =  $SpeakersInfo #String (Name, Job title, Company. Separated by new line)
Session_notes                = ''
Session_type                 = 'in-person'
Session_content_type         = ''
Session_booking              = $true
Session_show_time_and_date   = $true
Session_show_add_to_calendar = 'show'
Session_privacy              = 'public'
Session_show_rating_feedback = 'show'
Session_published            = $true
Session_session_rating       = 'Pop-up'
location = $session.room
    }
}

$Sessions |Export-csv -Path virtualplatform\sessions.csv

$Name = @{Name = 'Name'; Expression =  {'{0} {1}' -f $_.firstName,$_.lastName}}
$Email = @{Name = 'Email'; Expression =  {$_.email}}
$Title = @{Name = 'Title'; Expression =  {$_.tagLine}}
$Bio = @{Name = 'Bio'; Expression =  {$_.Bio}}
$Company = @{Name = 'Company'; Expression =  {$_.'Company Name'}}
$CompanyURL = @{Name = 'CompanyURL'; Expression =  {$_.'Company Website'}}
$Type = @{Name = 'Type'; Expression =  {''}}
$Status = @{Name = 'Status'; Expression =  {'Active'}}
$Twitter = @{Name = 'Twitter'; Expression =  {$_.Twitter}}
$Linkedin = @{Name = 'Linkedin'; Expression =  {$_.Linkedin}}
$Sessionss = @{Name = 'Sessions'; Expression =  {$fullname = '{0} {1}' -f $_.firstName,$_.lastName;
($SpeakersFromWeb | Where-Object {$_.fullName -eq $fullname } ).sessions.name -join ','}}
$showsessionappearances = @{Name = 'showsessionappearances'; Expression =  {$true}}

$FromSessionize | Select $Name,$Email,$Title,$Bio,$Company,$CompanyURL,$Type,$Status,$Twitter,$Linkedin,$Sessionss,$showsessionappearances|Export-csv -Path virtualplatform\speakers.csv

# We need to have a Session and speakers advanced from Sessionize save as trainingdays.xlsx in the /virtualplatform directory - This is in the gitignore so wont be uploaded to github - delete column L
$TDSessions = Import-Excel virtualplatform\trainingdays.xlsx -WorksheetName 'Accepted Sessions'
$TDSpeakers = Import-Excel virtualplatform\trainingdays.xlsx -WorksheetName 'Accepted Speakers'
$TDSpeakersFromWeb = Get-SQLBitsTDSpeakers -full

$TDschedule = Get-SQLBitsTDSession



$TDSessionsforcsv = foreach ($session in $TDschedule) {
   $FeedbackLink = 'Feedback Link :- {0}' -f ( ($feedbackLinks | Where-Object {$_.ExternalId -eq $session.id}).FeedbackURLShort)
   $Description = '{0} {1}' -f (-join $Session.description[0..4950]), $FeedbackLink
    $Speakers = $session.Speakers -split ', ' | ForEach-Object { $_.Trim() }
    $SpeakersInfo = ($Speakers | ForEach-Object {
       $Details = $TDSpeakersFromWeb | Where fullName -eq $_
       $TDSpeakersFromWeb | Where fullName -eq $_
       "{0},{1},{2}`n"  -f $Details.fullName, $Details.tagLine, $Details.CompanyName
    }) -join ''
   [pscustomobject]@{
       Session_name                 = $Session.title
       Session_start_date_time      = $session.startsat.ToString('yyyy-MM-dd HH:mm:00')
       Session_end_date_time        = $session.endsat.ToString('yyyy-MM-dd HH:mm:00')
Session_description          = $Description
Session_status               = 'visible'
Session_speakers             =  $SpeakersInfo #String (Name, Job title, Company. Separated by new line)
Session_notes                = ''
Session_type                 = 'in-person'
Session_content_type         = ''
Session_booking              = $true
Session_show_time_and_date   = $true
Session_show_add_to_calendar = 'show'
Session_privacy              = 'public'
Session_show_rating_feedback = 'show'
Session_published            = $true
Session_session_rating       = 'Pop-up'
location = $session.room
   }
}

$TDSessionsforcsv |Export-csv -Path virtualplatform\TDsessions.csv



$Name = @{Name = 'Name'; Expression =  {'{0} {1}' -f $_.firstName,$_.lastName}}
$Email = @{Name = 'Email'; Expression =  {$_.email}}
$Title = @{Name = 'Title'; Expression =  {$_.tagLine}}
$Bio = @{Name = 'Bio'; Expression =  {$_.Bio}}
$Company = @{Name = 'Company'; Expression =  {$_.'Company Name'}}
$CompanyURL = @{Name = 'CompanyURL'; Expression =  {$_.'Company Website'}}
$Type = @{Name = 'Type'; Expression =  {''}}
$Status = @{Name = 'Status'; Expression =  {'Active'}}
$Twitter = @{Name = 'Twitter'; Expression =  {$_.Twitter}}
$Linkedin = @{Name = 'Linkedin'; Expression =  {$_.Linkedin}}
$Sessionss = @{Name = 'Sessions'; Expression =  {$fullname = '{0} {1}' -f $_.firstName,$_.lastName;
($SpeakersFromWeb | Where-Object {$_.fullName -eq $fullname } ).sessions.name -join ','}}
$showsessionappearances = @{Name = 'showsessionappearances'; Expression =  {$true}}

$TDSpeakers | Select $Name,$Email,$Title,$Bio,$Company,$CompanyURL,$Type,$Status,$Twitter,$Linkedin,$Sessionss,$showsessionappearances|Export-csv -Path virtualplatform\TDspeakers.csv

$TDSpeakers |Select FirstName, LastName, 'Profile Picture' |Export-Excel c:\temp\speakermugshots.xlsx -WorksheetName 'Speakers' -AutoSize -FreezeTopRow -AutoFilter -BoldTopRow
$FromSessionize  |Select FirstName, LastName, 'Profile Picture' |Export-Excel c:\temp\speakermugshots.xlsx -WorksheetName 'Speakers' -AutoSize -FreezeTopRow -AutoFilter -BoldTopRow -Append