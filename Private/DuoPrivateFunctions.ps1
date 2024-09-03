Function New-DuoRequest{
<#
.SYNOPSIS
    Formats hashtables to payloads for Duo web requst

.DESCRIPTION
    Creates request to send to Duo to preform requested function

.PARAMETER Uri
    The child path to the api that follows the Duo API host name

.PARAMETER Methods
    The method type of the request [GET], [POST], [DELETE]

.PARAMETER Arguments
    The parameters that will be sent within the Duo request

.OUTPUTS
    [PSCustomObject]DuoRequest

.EXAMPLE
    New-DuoRequest -UriPath "/admin/v1/users" -Method Post -Arguments @{username,"username"}

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Version:        1.0
    Author:         Jared Yates
    Creation Date:  10/5/2022
    Purpose/Change: Initial script development
#>
    PARAM(
        [Parameter(Mandatory = $true)]$UriPath,
        [Parameter(Mandatory = $true)] $Method,
        [Parameter(Mandatory = $true)] $Arguments
    )
    
    #Decrypt our keys from our config
    $skey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Script:DuoConfig.SecretKey))
    $iKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Script:DuoConfig.IntergrationKey))
    $apiHost = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Script:DuoConfig.apiHost))
    $Date = (Get-Date).ToUniversalTime().ToString("ddd, dd MMM yyyy HH:mm:ss -0000")
    
    $DuoParamsParamsString = ($Arguments.Keys | Sort-Object | ForEach-Object {
        $_ + "=" + [uri]::EscapeDataString($Arguments.$_)
    }) -join "&"

    $DuoParams = (@(
        $Date.Trim(),
        $method.ToUpper().Trim(),
        $apiHost.ToLower().Trim(),
        $Uri.Trim(),
        $DuoParamsParamsString.trim()
    ).trim() -join "`n").ToCharArray().ToByte([System.IFormatProvider]$UTF8)

    $Secret = [System.Security.Cryptography.HMACSHA1]::new($skey.ToCharArray().ToByte([System.IFormatProvider]$UTF8))
    $Secret.ComputeHash($DuoParams) | Out-Null
    $Secret = [System.BitConverter]::ToString($Secret.Hash).Replace("-", "").ToLower()
    $AuthHeader = $ikey + ":" + $Secret
    [byte[]]$AuthHeader = [System.Text.Encoding]::ASCII.GetBytes($AuthHeader)

    $WebReqest = @{
        URI         = ('Https://{0}{1}' -f $apiHost, $UriPath)
        Headers     = @{
            "X-Duo-Date"    = $Date
            "Authorization" = ('Basic: {0}' -f [System.Convert]::ToBase64String($AuthHeader))
        }
        Body        = $Arguments
        Method      = $method
        ContentType = 'application/x-www-form-urlencoded'
    }
    $WebReqest
}

Function ConvertTo-UnixTime($Time){
<#
.Synopsis
    Converts time to epox time format
.DESCRIPTION
    Converts time to epox time format copatibale for unix systems
.EXAMPLE
    ConvertTo-UnixTime
.INPUTS

.OUTPUTS
    [int]$Timespan
.NOTES

.COMPONENT

.FUNCTIONALITY
    Time conversion
#>
    $Epox = Get-Date -Date '01/01/1970'
    $Timespan = New-Timespan -Start $Epox -End $Time | Select-Object -ExpandProperty TotalSeconds
    Write-Output $Timespan
}

Function Get-DuoDirectoryKey{

    Param(
        [Parameter(Mandatory=$false,
            ValueFromPipeLine=$true
        )]
            [String]$DirectoryName
    )

    If($DirectoryName){
        $Directories = $DirectoryName
    }
    Else{
        $Directories = Get-DuoDirectoryNames
    }

    $DuoConfig = Get-DuoConfig
    ForEach($Directory in $Directories){
        $Output = $DuoConfig.GetEnumerator() | Where-Object Name -EQ $DirectoryName
        $Output.Value
    }
}

Function Get-AllDuoGroups{
    
    #Base Claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/groups"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("limit","100")
    $DuoParams.Add("offset","0")

    #Duo has a 100 group limit in their api. Loop to return all groups
    $Offset=0
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
            #Increment offset to return the next 100 groups
            $Offset += 100
        }
    }Until($Output.Count -lt 100)
}

Function ConvertTo-EpochTimeStamp {
    PARAM(
        [datetime]$DateTime
    )
    $EpochTimestamp = [Int][Double]::Parse((Get-Date -Date $DateTime -UFormat %s))
    
    Return $EpochTimestamp
}

Function Get-Base64Image {
    PARAM(
        [String]$ImagePath
    )
    $File = Get-Item -Path $ImagePath
    $Image = [System.Drawing.Image]::FromFile($ImagePath)
    $ImageBytes = [System.IO.File]::ReadAllBytes($ImagePath)
    $Base64String = [Convert]::ToBase64String($ImageBytes)

    $ImgObj = [PSCustomObject]@{
        Name = $File.Name
        Width = $Image.Width
        Height = $Image.Height
        Size = $File.Length
        Base64String = $Base64String
    }

    Return $ImgObj
}

Function Test-DuoConnection{
<#
.Synopsis
   Ping Duo Endpoints
.DESCRIPTION
    The /ping endpoint acts as a "liveness check" that can be called to verify that Duo is up before 
    trying to call other endpoints. Unlike the other endpoints, this one does not have to be signed 
    with the Authorization header.
.EXAMPLE
    Get-DuoUser
.EXAMPLE
    Test-DuoConnection
.INPUTS

.OUTPUTS
   [PSCustomObject]DuoRequest
.NOTES
    DUO API 
        Method GET 
        Path /auth/v2/ping
    PARAMETERS
        None
    RESPONSE CODES
        Response	Meaning
        200	        Success.
    RESPONSE FORMAT
        Key         Value
        time        Current server time. Formatted as a epoch timestamp Int.
.COMPONENT
   DUO Auth
.FUNCTIONALITY
   Sends a webrequest to DUO, verifying the service is available. 
#>
    [CmdletBinding(
    )]
    PARAM()

    [String]$method = "GET"
    [String]$path = "/auth/v2/ping"
    $apiHost = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Script:DuoConfig.apiHost))
    
    $DUORestRequest = @{
        URI         = ('Https://{0}{1}' -f $apiHost, $path)
        Method      = $method
        ContentType = 'application/x-www-form-urlencoded'
    }
    
    $Response = Invoke-RestMethod @DUORestRequest
    If($Response.stat -ne 'OK'){
        Write-Warning 'DUO REST Call Failed'
        Write-Warning "APiParams:"+($APiParams | Out-String)
        Write-Warning "Method:$method    Path:$path"
    }   
    #$Output = $Response | Select-Object -ExpandProperty Response 
    #Write-Output $Output
    Write-Output "Successfully connected"

    Try{
        $DuoUsers = Get-DuoUser
    }
    Catch{
        Write-Warning "User Check: Failed"
        Write-Warning "Cannot pull user information"
    }
    Finally{
        If($DuoUsers.Count -gt 1){
            Write-Output "User Check: Passed"
        }
    }
}

Function Test-DuoUser{
<#
.Synopsis
    Validates if a user exist in Duo
.DESCRIPTION
    Test if user exist within Duo
.EXAMPLE
    Test-DuoUser -Username TestUser
.EXAMPLE
    Test-DuoUser -UserID ABCDEF12G34567HIJKLM
.INPUTS

.OUTPUTS
    [bool]$true/$false
.NOTES

.COMPONENT

.FUNCTIONALITY
    Time conversion
#>
    [CmdletBinding(DefaultParameterSetName="Uname")]
    Param(
        [Parameter(
            ParameterSetName="Uname",
            Mandatory=$true
            )]
                $Username,
        [Parameter(
            ParameterSetName="UID",
            Mandatory=$true
            )]
                $UserID
    )
    If($Username){$UserID = (Get-DuoUser -Username $Username -ErrorAction Ignore).user_id}
    If([String]::IsNullOrEmpty($UserID)){$UserID="null"}
    Try{
        Get-DuoUser -UserID $UserID | Out-Null
        Return $true
    }
    Catch{
        Return $false
    }
}

Function Test-DuoGroup{
    [CmdletBinding(DefaultParameterSetName="Gname")]
    Param(
        [Parameter(
            ParameterSetName="Gname",
            Mandatory=$true,
            ValueFromPipelin=$true,
            Position=0
            )]
                $GroupName,
        [Parameter(
            ParameterSetName="GID",
            Mandatory=$true,
            ValueFromPipelin=$true,
            Position=0
            )]
                $GroupID
    )
    If($GroupName){
        Try{
            Get-DuoGroup -GroupName $GroupName | Out-Null
            Return $true
        }
        Catch{
            Return $false
        }
    }
    ElseIf($GroupID){
        Try{
            Get-DuoGroup -GroupID $GroupID | Out-Null
            Return $true
        }
        Catch{
            Return $false
        }
    }

}

Function Test-DuoPhone{
    Param(
        [String]$Name,
        [String]$PhoneID,
        [String]$Number,
        [String]$Extension
    )

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/phones"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("limit","500")
    $DuoParams.Add("offset","0")
    $Offset = 0

    #Duo has a 300 user limit in their api. Loop to return all users
    $AllPhones = Do{
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
            $Offset += 500
        }
    }Until($Output.Count -lt 500)

    If($Name){
        If(($AllPhones | Where-Object Name -EQ $Name)){
            Return $true
        }
        Else{
            Return $false
        }
    }
    ElseIf($PhoneID){
        If(($AllPhones | Where-Object Phone_ID -EQ $PhoneID)){
            Return $true
        }
        Else{
            Return $false
        }
    }
    ElseIf($Number -and $Extension){
        If(($AllPhones | Where-Object ($_.Number -EQ $Number -and $_.extension -eq $Extension))){
            Return $true
        }
        Else{
            Return $false
        }
    }
    ElseIf($Number){
        If(($AllPhones | Where-Object Number -EQ $Number)){
            Return $true
        }
        Else{
            Return $false
        }
    }
}

Function Test-DuoBypassCode{
    Param(
        [String]$BypassCodeID
    )
    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/bypass_codes/$($BypassCodeID)"
    [Hashtable]$DuoParams = @{}
    Try{
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
        Return $true
    }
    Catch{
        Return $false
    }
}

Function Validate-PhoneNumber {
    Param (
        [Parameter(Mandatory=$true)]
        [String]$PhoneNumber
    )

    # Regular expression pattern for phone number in the format +18144554545
    $Pattern = '^\+\d{11}$'

    If($PhoneNumber -match $pattern) {
        Return $true
    } 
    Else {
        Return $false
    }
}

Function Test-DuoTokens{
    Param(
        [String]$TokenID
    )
    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/tokens/$($TokenID)"
    [Hashtable]$DuoParams = @{}
    Try{
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
        Return $true
    }
    Catch{
        Return $false
    }
}

Function Test-WebAuthnKey {
    PARAMS(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true,
            Position=0
            )]
        [String]$WebAuthnKey
    )
    
    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/webauthncredentials/$($WebAuthnKey)"
    [Hashtable]$DuoParams = @{}

    Try{
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
        Return $true
    }
    Catch{
        Return $false
    }
}

Function Test-DuoDesktop {
    PARAMS(
        [Parameter(
            Mandatory = $true,
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
    [String]$Uri = "/admin/v1/desktop_authenticators/$($DesktopKey.dakey)"
    [Hashtable]$DuoParams = @{}

    Try{
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
        Return $true
    }
    Catch{
        Return $false
    }
}

Function Test-DuoIntegrations {
    [CmdletBinding(DefaultParameterSetName="IKey")]
    PARAM(
        [Parameter(ParameterSetName="IKey",
            Mandatory = $true,
            ValueFromPipeLine = $true,
            Position=0
            )]
            [String]$IntegrationKey
    )

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/integrations/$($IntegrationKey)"
    [Hashtable]$DuoParams = @{}

    Try{
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
        Return $true
    }
    Catch{
        Return $false
    }
}

Function Test-EpochTimestamp {
    PARAM (
        [Parameter(Mandatory=$true)]
        [string]$Timestamp
    )

    # Check if the timestamp is a number
    If($Timestamp -match '^\d+$'){
        # Convert the timestamp to an integer
        $TimeStampInt = [Int64]$Timestamp

        # Define the range for valid epoch timestamps
        $EpochStart = [DateTime]::New(1970, 1, 1, 0, 0, 0, [DateTimeKind]::UTC)
        $EpochEnd = [DateTime]::UTCnow

        # Convert the timestamp to a DateTime object
        $TimeStampDate = $EpochStart.AddSeconds($TimeStampInt)

        # Check if the timestamp falls within the valid range
        If($TimeStampDate -ge $EpochStart -and $TimeStampDate -le $EpochEnd){
            Return $true
        }
    }

    Return $false
}

Function Test-DuoAdmin {
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true,
            Position=0
            )]
            [String]$AdminID
    )

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/admins/$($AdminID)"
    [Hashtable]$DuoParams = @{}

    Try{
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
        Return $true
    }
    Catch{
        Return $false
    }
}