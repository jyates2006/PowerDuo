# PowerDuo

**PowerDuo** is a PowerShell module designed to **manage Duo Security via its API** [1, 2]. It functions as a **Duo Admin Module utilizing the Duo API** [2].

## About the Project Name

This project was originally named `PSDuo` [1]. However, the name was changed to `PowerDuo` just two days before its planned release on PSGallery, as another project had already used the `PSDuo` name [1]. You might still find some older names or help links that need updating within the module [1].

## Features

The PowerDuo module allows you to interact with the Duo Security Admin API, providing a wide range of functions to manage various Duo objects. All functions within the module **follow the standard PowerShell format of Verb-Noun** (e.g., `Get-DuoUser`, `New-DuoUser`) [3].

Some key capabilities include:

*   **Configuration Management**: Create, save, and load API configurations [4, 5].
*   **User Management**: Get, add, set, and remove Duo users [3, 6].
*   **Group Management**: Manage Duo groups and their members [6].
*   **Device Management**: Interact with phones, tokens, WebAuthN credentials, and registered devices [6].
*   **Administrator Management**: Manage Duo administrators, including setting, removing, and sending activation links [3, 6].
*   **Logging and Reporting**: Retrieve Duo logs and reports [6].
*   **Settings and Branding**: Get and set Duo settings, logos, and custom messaging [6].

**Note**: Duo assigns an ID for each object [3]. Some functions, such as `Set-DuoAdmin`, require this ID [3]. You can typically retrieve the ID using a `Get-Duo` function (e.g., `Get-DuoAdmin`) and then pipe or select the ID for use with `Set-DuoAdmin` [3].

## Installation

The PowerDuo module is available on the PowerShell Gallery [2]. It requires a **minimum PowerShell version of 4.0** [2].

You can install it using one of the following methods:

### Install Module (PowerShellGet)

```powershell
Install-Module -Name PowerDuo
Install PSResource (Microsoft.PowerShell.PSResourceGet)
Install-PSResource -Name PowerDuo
Azure Automation
You can deploy this package directly to Azure Automation. Note that if the package has dependencies, all dependencies will also be deployed to Azure Automation.
Manual Download
You can manually download the .nupkg file to your system's default download location from the PowerShell Gallery. Please note that manually downloaded files are not unpacked and do not include dependencies.
Getting Started & Configuration
To use PowerDuo, you first need to protect an Admin API within Duo. You will require the Integration Key, Secret Key, and API hostname from your Duo admin panel. When protecting the Admin API, you might want to limit permissions and/or API network access depending on your purpose.
Create a Configuration
Begin by creating a configuration for your Duo API connection:
New-DUOConfig -IntergrationKey SDFJASKLDFJASLKDJ -SecretKey ASDKLFJSMNVCIWJRFKSDMSMVNFNSKLF -apiHost api-###XXX###.duosecurity.com
Save and Load Configuration (Optional)
You can optionally save your configuration for easier use in later sessions or automation scripts:
New-DUOConfig -IntergrationKey SDFJASKLDFJASLKDJ -SecretKey ASDKLFJSMNVCIWJRFKSDMSMVNFNSKLF -apiHost api-###XXX###.duosecurity.com -SaveConfig -Path C:\Duo\DuoConfig.clixml
To load a saved configuration, which is particularly useful for automation scripting:
Import-DuoConfig -Path C:\Duo\DuoConfig.clixml
Add Duo Directory Keys
The Duo API does not support pulling directories and their names directly. However, the PowerDuo module provides an option to add directory keys to your configuration for later use.
You can find the Directory Keys by navigating to your Duo admin panel and viewing your directories. Once inside a directory, the key will be visible in the URL (e.g., https://admin-ac#$#$.duosecurity.com/users/directorysync/ADFD56456456DFDS, where 'ADFD56456456DFDS' is the directory key). The name value you assign (-KeyName) is for your reference only and is irrelevant to the operation.
Add-DuoDirectoryKeys -KeyName DuoDirectory -KeyValue 7908DDFD890
Dependencies
This module has no dependencies.
License
This project is licensed under the GPL-3.0 license.
Author and Copyright
• Author: Jared Yates (jayates2006 on PowerShell Gallery)
• Copyright: (c) 2022-2024 Jared Yates. All rights reserved.
Tags
The module is tagged with:
• Duo
• DuoSecurity
• Powershell
• RestAPI
