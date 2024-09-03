Function Get-DuoIntegration {
<#
.SYNOPSIS
    List all or a signle integration

.DESCRIPTION
    Return all Duo integrated application or an individual application

.PARAMETER IntegrationKey
	Duo's Integration key

.OUTPUTS
    [PSCustomObject]DuoRequest

.EXAMPLE
    Get-DuoIntegration

.EXAMPLE
    Get-DuoIntegration -IntegrationKey 153456D1DFE546

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    [CmdletBinding(DefaultParameterSetName="IKey")]
    PARAM(
        [Parameter(ParameterSetName="IKey",
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=0
            )]
        [ValidateScript({
            If(Test-DuoIntegrations -IntegrationKey $_){$true}
            Else{Throw "Token: $($_) doesn't exist in Duo"}
        })]
            [String]$IntegrationKey
    )

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/integrations"
    [Hashtable]$DuoParams = @{}

    If($IntegrationKey){
        [String]$Uri = "/admin/v1/integrations/$($IntegrationKey)"
    }

    $DuoParams.Add("limit","300")
    $DuoParams.Add("offset","0")
    
    $Offset = 0

    #Duo has a 300 object limit in their api. Loop to return all users
    Do{
        $DuoParams.Offset = $Offset
        $Request = New-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
        $Response = Invoke-RestMethod @Request
        If($Response.stat -ne 'OK'){
            Write-Warning 'DUO REST Call Failed'
            Write-Warning "Arguments:"+($DuoParams | Out-String)
            Write-Warning "Method:$Method    Path:$Uri"
        }   
        Else{
            $Output = $Response | Select-Object -ExpandProperty Response 
            $Output
            #Increment offset to return the next 300 users
            $Offset += 300
        }
    }Until($Output.Count -lt 300)
}

Function Set-DuoIntegration {
<#
.SYNOPSIS
    Set and modify settings for existing Duo integrations

.DESCRIPTION
    Set settings for existing Duo integrations

.PARAMETER IntegrationKey
	Required, Duo's Integration key

.PARAMETER Name
    Set a new name

.PARAMETER APInetworks
    Comma separated list of allowed networks for API access

.Parameter APIadmins
    Comma separated list of Duo Admin IDs
	
.Parameter APIinfo 
	Additional Info

.Parameter EnableAPI_All
	Enable/Disable all acces via API

.Parameter EnableAPI_ReadLog
	Enable/Disable Read log via API 

.Parameter EnableAPI_ReadResource
	Enable/Disable Read Resource via API

.Parameter EnableAPI_ModifySettings
	Enable/Disable modification to settings via API

.Parameter EnableAPI_WriteResource
	Enable/Disable write resouce via API

.Parameter Greeting
	Set the voice greeting

.Parameter AllowedGroups
	Comma separated list of Duo Group IDs

.Parameter Notes
	Enter notes

.Parameter PolicyKey
	Apply a policy

.Parameter Enable_DuoUniversalPrompt
	Enable/Disable Universal Prompt or Traditional Prompt

.Parameter ResetSecretKey
	Resets the secret key

.Parameter Enable_SelfService
	Enable/Disable self service

.Parameter SSO
	Provie the SSO settings


.Parameter Enable_UsernameNormalization
	Enable/DuoAdminUnit Simple username normalization or UPN

.OUTPUTS
    [PSCustomObject]DuoRequest

.EXAMPLE
    Set-DuoIntegration -IntegrationKey 54DFD7849DFJK78 -Name "Protected Application" -Enable_DuoUniversalPrompt $True

.EXAMPLE
    Set-DuoIntegration -IntegrationKey 54DFD7849DFJK78 -AllowedGroups "153456132156DFEFF,5DFDF1564D2131F"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    [CmdletBinding(DefaultParameterSetName="IKey")]
    PARAM(
        [Parameter(ParameterSetName="IKey",
            Mandatory = $true,
            ValueFromPipeLine = $true,
            Position=0
            )]
        [ValidateScript({
            If(Test-DuoIntegrations -IntegrationKey $_){$true}
            Else{Throw "Token: $($_) doesn't exist in Duo"}
        })]
            [String]$IntegrationKey,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=1
            )]
            [String]$Name,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [String]$APInetworks,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$APIadmins,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$APIinfo,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$EnableAPI_All,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$EnableAPI_ReadLog,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$EnableAPI_ReadResouce,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$EnableAPI_ModifySettings,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$EnableAPI_WriteResource,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [String]$Greeting,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [String]$AllowedGroups,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [String]$Notes,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [String]$PolicyKey,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$Enable_DuoUniversalPrompt,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$ResetSecretKey,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [String]$Enable_SelfService,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [String]$SSO,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$Enable_UsernameNormalization
    )

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/integrations/$($IntegrationKey)"
    [Hashtable]$DuoParams = @{}

    If($Name){
        $DuoParams.Add("name",$Name)
    }
    If($APInetworks){
        $DuoParams.Add("networks_for_api_access",$APInetworks)
    }
    If($APIadmins){
        Switch($APIadmins){
            $true {$DuoParams.Add("adminapi_admins",1)}
            $false {$DuoParams.Add("adminapi_admins",0)}
        }
    }
    If($APIinfo){
        Switch($APIinfo){
            $true {$DuoParams.Add("adminapi_info",1)}
            $false {$DuoParams.Add("adminapi_info",0)}
        }
    }
    If($EnableAPI_All){
        Switch($EnableAPI_All){
            $true {$DuoParams.Add("adminapi_integrations",1)}
            $false {$DuoParams.Add("adminapi_integrations",0)}
        }
    }
    If($EnableAPI_ReadLog){
        Switch($EnableAPI_ReadLog){
            $true {$DuoParams.Add("adminapi_read_log",1)}
            $false {$DuoParams.Add("adminapi_read_log",0)}
        }
    }
    If($EnableAPI_ReadResouce){
        Switch($APIinfo){
            $true {$DuoParams.Add("adminapi_read_resource",1)}
            $false {$DuoParams.Add("adminapi_info",0)}
        }
    }
    If($EnableAPI_ModifySettings){
        Switch($EnableAPI_ModifySettings){
            $true {$DuoParams.Add("adminapi_settings",1)}
            $false {$DuoParams.Add("adminapi_settings",0)}
        }
    }
    If($EnableAPI_WriteResource){
        Switch($EnableAPI_WriteResource){
            $true {$DuoParams.Add("adminapi_write_resource",1)}
            $false {$DuoParams.Add("adminapi_write_resource",0)}
        }
    }
    If($Greeting){
        $DuoParams.Add("greeting",$Greeting)
    }
    If($Notes){
        $DuoParams.Add("notes",$Notes)
    }
    If($PolicyKey){
        $DuoParams.Add("policy_key",$PolicyKey)
    }
    If($Enable_DuoUniversalPrompt){
        Switch($Enable_DuoUniversalPrompt){
            $true {$DuoParams.Add("prompt_v4_enabled",1)}
            $false {$DuoParams.Add("prompt_v4_enabled",0)}
        }
    }
    If($ResetSecretKey){
        Switch($ResetSecretKey){
            $true {$DuoParams.Add("reset_secret_key",1)}
            $false {$DuoParams.Add("reset_secret_key",0)}
        }
    }
    If($Enable_SelfService){
        Switch($Enable_SelfService){
            $true {$DuoParams.Add("self_service_allowed",1)}
            $false {$DuoParams.Add("self_service_allowed",0)}
        }
    }
    If($Enable_UsernameNormalization){
        Switch($Enable_UsernameNormalization){
            $true {$DuoParams.Add("username_normalization_policy","simple")}
            $false {$DuoParams.Add("username_normalization_policy","none")}
        }
    }

    $Request = New-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
    $Response = Invoke-RestMethod @Request
    If($Response.stat -ne 'OK'){
        Write-Warning 'DUO REST Call Failed'
        Write-Warning "Arguments:"+($DuoParams | Out-String)
        Write-Warning "Method:$Method    Path:$Uri"
    }   
    Else{
        $Output = $Response | Select-Object -ExpandProperty Response 
        $Output
    }
}