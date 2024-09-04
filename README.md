# PowerDuo
Manager Duo with PowerShell via the API.
This project was initially named PSDuo, but 2 days before I went live with it on PSGallery, someone else did with that name. Some names and help links may still need updated.

# Getting Started

## Install
Install-Module -Name PowerDuo

## Setup
Import-Module -Name PowerDuo

New-DuoConfig -ApiHostname "duoapi123.duosecurity.com" -IntegrationKey "JDJIDRB56377JDJ" -SecretKey - "JEJDH56388JEHHD"

Now you will be able to use the rest of the functions in your current session. You can also save the Config and Import it later for easy of use.

All functions follow the standart Powershell format of Verb-Noun
Get-DuoUser
New-DuoUser

### Duo Information
Duo assigns and ID for each object. A few functions require this ID. Such as Set-DuoAdmin. So you will need to use Get-DuoAdmin then filter or select the ID you want to use with Set-DuoAdmin. I usually have this ID to be accepted on pipeline for easy of use. 
