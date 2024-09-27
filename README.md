# PowerDuo
Manager Duo with PowerShell via the API.
This project was initially named PSDuo, but 2 days before I went live with it on PSGallery, someone else did with that name. Some names and help links may still need updated.

# Getting Started
You will need to protect an Admin API within Duo. You will need to the Interation Key, Secret Key, and API hostname. 
Go to your Duo admin panel. Then to Applications. Protect an Application. Admin API.
Depending on the purpose, you may want to limit the permissions and/or the API network access. 

## Install
`Install-Module -Name PowerDuo`

## Setup
Start by creating a config
`New-DUOConfig -IntergrationKey SDFJASKLDFJASLKDJ -SecretKey ASDKLFJSMNVCIWJRFKSDMSMVNFNSKLF -apiHost api-###XXX###.duosecurity.com`

Optionally save the config for use with the same user later on
`New-DUOConfig -IntergrationKey SDFJASKLDFJASLKDJ -SecretKey ASDKLFJSMNVCIWJRFKSDMSMVNFNSKLF -apiHost api-###XXX###.duosecurity.com -SaveConfig -Path C:\Duo\DuoConfig.clixml`

You can load a saved config. Useful for automation scripting.
`Import-DuoConfig -Path C:\Duo\DuoConfig.clixml`

The Duo API doesn't support pulling the Directories and their names, so I have added the option to add it to the config for later use.
`Add-DuoDirectoryKeys -KeyName DuoDirectory -KeyValue 7908DDFD890`

You can get the Directory Keys by going to your Duo admin panel and viewing your directories. Once in a directory, the key will be in the URL.
https://admin-ac#$#$.duosecurity.com/users/directorysync/ADFD56456456DFDS
'ADFD56456456DFDS' will be the directory key. The name value is irrelavant to operation. Just for your reference. 

All functions follow the standart Powershell format of Verb-Noun
`Get-DuoUser`
`New-DuoUser`

### Duo Information
Duo assigns and ID for each object. A few functions require this ID. Such as Set-DuoAdmin. So you will need to use Get-DuoAdmin then filter or select the ID you want to use with Set-DuoAdmin. I usually have this ID to be accepted on pipeline for easy of use. 
