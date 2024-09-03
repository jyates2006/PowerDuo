# PowerDuo
Manager Duo with PowerShell via the API.
This project was initially named PSDuo, but 2 days before I went live with it on PSGallery, someone else did with that name. Some names and help links may still need updated.

#Getting Started

##Install
Install-Module -Name PowerDuo

##Setup
Import-Module -Name PowerDuo

New-DuoConfig -ApiHostname "duoapi123.duosecurity.com" -IntegrationKey "JDJIDRB56377JDJ" -SecretKey - "JEJDH56388JEHHD"
