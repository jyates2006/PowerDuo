Function Get-DuoDestktop {
<#
.SYNOPSIS
    Retrieves desktop authenticators from Duo.

.DESCRIPTION
    This function sends a GET request to the Duo Admin API to retrieve details of desktop authenticators. 
    It supports retrieving a specific desktop authenticator by DesktopKey or all desktop authenticators with pagination.

.PARAMETER DesktopKey
    The key of the desktop authenticator to retrieve. If not specified, retrieves all desktop authenticators.

.EXAMPLE
    PS C:\> Get-DuoDesktop

.EXAMPLE
    PS C:\> Get-DuoDesktop -DesktopKey "desktop123"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>
    PARAMS(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=0
            )]
        [ValidateScript({
            If(Test-DuoWEbAuthnKey -TokenID $_){$true}
            Else{Throw "Token: $($_) doesn't exist in Duo"}
        })]
        [String]$DesktopKey
    )
    
    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/desktop_authenticators"
    [Hashtable]$DuoParams = @{}

    If($DesktopKey){
        $Uri = "/admin/v1/desktop_authenticators/$($DesktopKey)"
    }
    
    $Offset = 0

    #Duo has a 300 user limit in their api. Loop to return all users
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

Function Remove-DuoDestktop {
<#
.SYNOPSIS
    Removes a desktop authenticator from Duo.

.DESCRIPTION
    This function sends a DELETE request to the Duo Admin API to remove a desktop authenticator specified by its DesktopKey.

.PARAMETER DesktopKey
    The key of the desktop authenticator to be removed.

.EXAMPLE
    PS C:\> Remove-DuoDesktop -DesktopKey "desktop123"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>
    PARAMS(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true,
            Position=0
            )]
        [ValidateScript({
            If(Test-DuoDesktop -DesktopKey $_){$true}
            Else{Throw "Desktop: $($_) doesn't exist in Duo"}
        })]
        [String]$DesktopKey
    )
    
    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/desktop_authenticators/$($DesktopKey)"
    [Hashtable]$DuoParams = @{}

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

Function Get-DuoEndpoint {
<#
.SYNOPSIS
    Retrieves endpoint details from Duo.

.DESCRIPTION
    This function sends a GET request to the Duo Admin API to retrieve details of endpoints. 
    It supports retrieving a specific endpoint by EndpointKey or all endpoints with pagination.

.PARAMETER EndpointKey
    The key of the endpoint to retrieve. If not specified, retrieves all endpoints.

.EXAMPLE
    PS C:\> Get-DuoEndpoint

.EXAMPLE
    PS C:\> Get-DuoEndpoint -EndpointKey "endpoint123"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>

    [CmdletBinding(DefaultParameterSetName="EKey")]
    PARAM(
        [Parameter(ParameterSetName="EKey",
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=0
            )]
        <#[ValidateScript({
            If(Test-DuoTokens -TokenID $_){$true}
            Else{Throw "Token: $($_) doesn't exist in Duo"}
        })]#>
            [String]$EndpointKey
    )

     #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/endpoints"
    [Hashtable]$DuoParams = @{}

    If($EndpointID){    
        $Uri = "/admin/v1/endpoints/$($EndpointKey)"
    }
    Else{
        $DuoParams.Add("limit","300")
        $DuoParams.Add("offset","0")
    }
    $Offset = 0

    #Duo has a 300 user limit in their api. Loop to return all users
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

Function Get-DuoRegisteredDevices {
<#
.SYNOPSIS
    Retrieves registered devices from Duo.

.DESCRIPTION
    This function sends a GET request to the Duo Admin API to retrieve registered devices. 
    It supports retrieving a specific device by DeviceID or all devices with pagination.

.PARAMETER DeviceID
    The ID of the device to retrieve. If not specified, retrieves all registered devices.

.EXAMPLE
    PS C:\> Get-DuoRegisteredDevices

.EXAMPLE
    PS C:\> Get-DuoRegisteredDevices -DeviceID "device123"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>
    PARAM(
        [Parameter(ParameterSetName="DID",
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=0
            )]
        <#[ValidateScript({
            If(Test-DuoTokens -TokenID $_){$true}
            Else{Throw "Token: $($_) doesn't exist in Duo"}
        })]#>
            [String]$DeviceID
    )

     #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/registered_devices"
    [Hashtable]$DuoParams = @{}

    If($DeviceID){    
        $Uri = "/admin/v1/registered_devices/$($DeviceID)"
    }
    Else{
        $DuoParams.Add("limit","300")
        $DuoParams.Add("offset","0")
    }
    $Offset = 0

    #Duo has a 300 user limit in their api. Loop to return all users
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

Function Remove-DuoRegisteredDevice {
<#
.SYNOPSIS
    Removes a registered device from Duo.

.DESCRIPTION
    This function sends a DELETE request to the Duo Admin API to remove a registered device specified by its DeviceID.

.PARAMETER DeviceID
    The ID of the device to be removed.

.EXAMPLE
    PS C:\> Remove-DuoRegisteredDevice -DeviceID "device123"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>
    PARAM(
        [Parameter(ParameterSetName="DID",
            Mandatory = $true,
            ValueFromPipeLine = $true,
            Position=0
            )]
        <#[ValidateScript({
            If(Test-DuoTokens -TokenID $_){$true}
            Else{Throw "Token: $($_) doesn't exist in Duo"}
        })]#>
            [String]$DeviceID
    )

     #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/registered_devices/$($DeviceID)"
    [Hashtable]$DuoParams = @{}

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
    }
}