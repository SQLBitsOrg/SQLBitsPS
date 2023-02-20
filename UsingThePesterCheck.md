# Using the SQLBits Schedule Pester Check

This can only be run by a SQLBits committee member as only they have access tothe correct xlsx file.

- Checks that speaker requests for Days and AM/PM are followed
- Ensures that Sponsored Room sessions are in the correct room
- Ensures that Remote Speakers are in the correct room

## Pre-Requisites

Ensure that you have installed the SQLBitsPs module

`Install-Module SQLBitsPS -AllowPreRelease`

Ensure that you have the latest version of the SQLBitsPs Repository cloned to your local machine.

`git clone https://github.com/SQLBitsOrg/SQLBitsPS`

or

cd to root of repo

`git pull`

Ensure that you have Pester v5 installed

`Install-Module Pester -Force -SkipPublisherCheck`

Ensure that you have the SpeakerRequests.xlxs file on your local machine and you know the path to it.

Make sure that all the speakers have been informed. The API is set to only show sessions that have been accepted, confirmed and informed.

## To run

Then all that you need to do is at the root of the repository run

`Invoke-Pester .\PesterCheck.ps1 -Output Detailed`

It will prompt for the full path to the SpeakerRequests.xlxs file. Provide that and

 ![image](https://user-images.githubusercontent.com/6729780/218675494-44e34379-2a43-4ba8-b1bc-8546cb1859c2.png)

