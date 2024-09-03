Function Get-DuoToken {
<#
.SYNOPSIS
    Retrieves Duo token information.

.DESCRIPTION
    This function retrieves information about Duo tokens based on the provided parameters. It can fetch tokens by TokenID or by Serial and Type.

.PARAMETER TokenID
    The ID of the token to retrieve. This parameter is optional and can be piped.

.PARAMETER Serial
    The serial number of the token. This parameter is optional.

.PARAMETER Type
    The type of the token. Valid values are "HOTP-6", "HOTP-8", "YubiKey", and "Duo-D100". This parameter is mandatory when Serial is specified.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    [CmdletBinding(DefaultParameterSetName="TID")]
    PARAM(
        [Parameter(ParameterSetName="TID",
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoTokens -TokenID $_){$true}
            Else{Throw "Token: $($_) doesn't exist in Duo"}
        })]
        [String]$TokenID,

        [Parameter(ParameterSetName="Tserial",
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=0
        )]
        [String]$Serial,

        [Parameter(ParameterSetName="Tserial",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=1
        )]
        [ValidateSet("HOTP-6","HOTP-8","YubiKey","Duo-D100")]
        [String]$Type
    )

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/tokens"
    [Hashtable]$DuoParams = @{}

    If($Serial){
        $DuoParams.Add("serial",$serial.ToLower())
        Switch($Type){
            "HOTP-6" {$DuoParams.Add("type","h6")}
            "HOTP-8" {$DuoParams.Add("type","h8")}
            "YubiKey" {$DuoParams.Add("type","yk")}
            "Duo-D100" {$DuoParams.Add("type","d1")}
        }
    }
    ElseIf($TokenID){    
        $Uri = "/admin/v1/tokens/$($TokenID)"
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

Function New-DuoToken {
<#
.SYNOPSIS
    Creates a new Duo token.

.DESCRIPTION
    This function creates a new Duo token using the specified parameters.

.PARAMETER Serial
    The serial number of the token.

.PARAMETER HOTP6
    Specifies that the token type is HOTP-6.

.PARAMETER HOTP8
    Specifies that the token type is HOTP-8.

.PARAMETER Secret
    The secret key for HOTP tokens.

.PARAMETER PrivateID
    The private ID for YubiKey tokens.

.PARAMETER AESkey
    The AES key for YubiKey tokens.

.PARAMETER Counter
    The counter value for HOTP tokens.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    PARAM(
    [Parameter(
        Mandatory = $true,
        ValueFromPipeLine = $false,
        Position = 0
    )]
    [String]$Serial,

    [Parameter(ParameterSetName = "HOTP-6",
        Mandatory = $true,
        ValueFromPipeLine = $false,
        Position = 1
    )]
    [Switch]$HOTP6,

    [Parameter(ParameterSetName = "HOTP8",
        Mandatory = $true,
        ValueFromPipeLine = $false,
        Position = 1
    )]
    [Switch]$HOTP8,

    [Parameter(ParameterSetName = "HOTP6",
        Mandatory = $true,
        ValueFromPipeLine = $false,
        Position = 2
    )]
    [Switch]$SecretHOTP6,

    [Parameter(ParameterSetName = "HOTP8",
        Mandatory = $true,
        ValueFromPipeLine = $false,
        Position = 2
    )]
    [Switch]$SecretHOTP8,

    [Parameter(ParameterSetName = "YubiKey",
        Mandatory = $true,
        ValueFromPipeLine = $false,
        Position = 1
    )]
    [Switch]$PrivateID,

    [Parameter(ParameterSetName = "HOTP6",
        Mandatory = $false,
        ValueFromPipeLine = $false,
        Position = 3
    )]
    [Switch]$CounterHOTP6,

    [Parameter(ParameterSetName = "HOTP8",
        Mandatory = $false,
        ValueFromPipeLine = $false,
        Position = 3
    )]
    [Switch]$CounterHOTP8,

    [Parameter(ParameterSetName = "YubiKey",
        Mandatory = $true,
        ValueFromPipeLine = $false,
        Position = 2
    )]
    [Switch]$AESkey
)


    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/tokens"
    [Hashtable]$DuoParams = @{}

    If($HOTP6){
        $Type = "h6"
    }
    ElseIf($HOTP8){
        $Type = "h8"
    }
    ElseIf($YubiKey){
        $Type = "yk"
    }
    $DuoParams.Add("type",$Type)
    $DuoParams.Add("serial",$Serial)
    
    If($HOTP6 -or $HOTP8){
        $DuoParams.Add("secret",$Secret)
        If($Counter){
            $DuoParams.Add("counter",$Counter.ToString())
        }
    }
    ElseIf($YubiKey){
        $DuoParams.Add("private_id",$PrivateID)
        $DuoParams.Add("aes_key",$AESkey)
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

Function Sync-DuoToken {
<#
.SYNOPSIS
    Synchronizes a token with Duo.

.DESCRIPTION
    This function sends a POST request to the Duo Admin API to synchronize a token specified by its TokenID or Serial and Type. 
    It requires three codes generated by the token for synchronization.

.PARAMETER Serial
    The serial number of the token to be synchronized.

.PARAMETER TokenID
    The ID of the token to be synchronized.

.PARAMETER Code1
    The first code generated by the token.

.PARAMETER Code2
    The second code generated by the token.

.PARAMETER Code3
    The third code generated by the token.

.PARAMETER Type
    The type of the token to be synchronized. Valid values are "HOTP-6", "HOTP-8", and "Duo-D100".

.EXAMPLE
    PS C:\> Sync-DuoToken -TokenID "token123" -Code1 "123456" -Code2 "234567" -Code3 "345678"

.EXAMPLE
    PS C:\> Sync-DuoToken -Serial "serial123" -Type "HOTP-6" -Code1 "123456" -Code2 "234567" -Code3 "345678"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>
    [CmdletBinding(DefaultParameterSetName="TID")]
    PARAM(
        [Parameter(ParameterSetName="Serial",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
        )]
        [String]$Serial,

        [Parameter(ParameterSetName="TID",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoTokens -TokenID $_){$true}
            Else{Throw "Token: $($_) doesn't exist in Duo"}
        })]
        [String]$TokenID,
        
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=2
        )]
        [String]$Code1,
        
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=3
        )]
        [String]$Code2,
        
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=4
        )]
        [String]$Code3,
        
        [Parameter(ParameterSetName="Serial",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=1
        )]
        [ValidateSet("HOTP-6","HOTP-8","Duo-D100")]
        [String]$Type
    )

    If($Serial){
        $TokenID = (Get-DuoTokens -Serial $Serial -Type $Type).token_id
    }

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/tokens/$($TokenID)"
    [Hashtable]$DuoParams = @{}

    $DuoParams.Add("code1",$Code1)
    $DuoParams.Add("code2",$Code2)
    $DuoParams.Add("code3",$Code3)

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

Function Remove-DuoToken {
<#
.SYNOPSIS
    Removes a token from Duo.

.DESCRIPTION
    This function sends a DELETE request to the Duo Admin API to remove a token specified by its TokenID or Serial and Type.

.PARAMETER TokenID
    The ID of the token to be removed.

.PARAMETER Serial
    The serial number of the token to be removed.

.PARAMETER Type
    The type of the token to be removed. Valid values are "HOTP-6", "HOTP-8", "YubiKey", and "Duo-D100".

.EXAMPLE
    PS C:\> Remove-DuoToken -TokenID "token123"

.EXAMPLE
    PS C:\> Remove-DuoToken -Serial "serial123" -Type "YubiKey"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>
    [CmdletBinding(DefaultParameterSetName="TID")]
    PARAM(
        [Parameter(ParameterSetName="TID",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoTokens -TokenID $_){$true}
            Else{Throw "Token: $($_) doesn't exist in Duo"}
        })]
        [String]$TokenID,
        
        [Parameter(ParameterSetName="Serial",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
        )]
        [String]$Serial,

        [Parameter(ParameterSetName="Serial",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=1
        )]
        [ValidateSet("HOTP-6","HOTP-8","YubiKey","Duo-D100")]
        [String]$Type
    )
    
    If($Serial){
        $TokenID = Get-DuoTokens -Serial $Serial -Type $Type
    }

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/tokens/$($TokenID)"
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

Function Get-DuoWebAuthnCredential {
<#
.SYNOPSIS
    Retrieves WebAuthn credentials from Duo.

.DESCRIPTION
    This function sends a GET request to the Duo Admin API to retrieve details of WebAuthn credentials. 
    It supports retrieving a specific WebAuthn credential by WebAuthnKey or all WebAuthn credentials with pagination.

.PARAMETER WebAuthnKey
    The key of the WebAuthn credential to retrieve. If not specified, retrieves all WebAuthn credentials.

.EXAMPLE
    PS C:\> Get-DuoWebAuthnCredential

.EXAMPLE
    PS C:\> Get-DuoWebAuthnCredential -WebAuthnKey "webauthn123"

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
        [String]$WebAuthnKey
    )
    
    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/webauthncredentials"
    [Hashtable]$DuoParams = @{}

    If($WebAuthnKey){
        $Uri = "/admin/v1/webauthncredentials/$($WebAuthnKey)"
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

Function Remove-DuoWebAuthnCredential {
<#
.SYNOPSIS
    Removes a WebAuthn credential from Duo.

.DESCRIPTION
    This function sends a DELETE request to the Duo Admin API to remove a WebAuthn credential specified by its WebAuthnKey.

.PARAMETER WebAuthnKey
    The key of the WebAuthn credential to be removed.

.EXAMPLE
    PS C:\> Remove-DuoWebAuthnCredential -WebAuthnKey "webauthn123"

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
        [String]$WebAuthnKey
    )

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/webauthncredentials/$($WebAuthnKey)"
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