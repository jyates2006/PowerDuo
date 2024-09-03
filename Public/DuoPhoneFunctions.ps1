Function Get-DuoPhone{
<#
.SYNOPSIS
    Retrieves phone details from Duo.

.DESCRIPTION
    This function retrieves phone details from Duo based on the provided parameters. It can fetch phones by Name, PhoneID, Number, or Extension.

.PARAMETER Name
    The name of the Duo phone. This parameter is optional.

.PARAMETER PhoneID
    The ID of the Duo phone. This parameter is optional.

.PARAMETER Number
    The phone number of the Duo phone. This parameter is optional.

.PARAMETER Extension
    The extension number of the Duo phone. This parameter is optional.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    [CmdletBinding(DefaultParameterSetName="Name")]
    Param(
        [Parameter(ParameterSetName="Name",
            Mandatory=$false,
            Position=0
        )]
        [String]$Name,

        [Parameter(ParameterSetName="ID",
            Mandatory=$false,
            Position=0
        )]
        [String]$PhoneID,
        
        [Parameter(ParameterSetName="Number",
            Mandatory=$false,
            Position=0
        )]
        [String]$Number,
        
        [Parameter(ParameterSetName="Number",
            Mandatory=$false,
            Position=1
        )]
        [String]$Extension
    )
    
    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/phones"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("limit","500")
    $DuoParams.Add("offset","0")
    $Offset = 0

    #Duo has a 500 phone limit in their api. Loop to return all phones
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
            #Increment offset to return the next 500 phones
            $Offset += 500
        }
    }Until($Output.Count -lt 500)

    If($Name){
        $AllPhones | Where-Object Name -EQ $Name
    }
    ElseIf($PhoneID){
        $AllPhones | Where-Object Phone_ID -EQ $PhoneID
    }
    ElseIF($Number -and $Extension){
        $AllPhones | Where-Object ($_.Number -eq $Number -and $_.Extension -eq $Extension)
    }
    ElseIf($Number){
        $AllPhones | Where-Object Number -EQ $Number
    }
    ElseIf($Extension){
        $AllPhones | Where-Object Extension -EQ $Extension
    }
    Else{
        $AllPhones
    }
}

Function New-DuoPhone{
<#
.SYNOPSIS
    Creates a new phone entry in Duo.

.DESCRIPTION
    This function creates a new phone entry in Duo with the specified details. It allows setting the phone's name, number, extension, type, platform, and delay settings.

.PARAMETER Name
    The name of the Duo phone. This parameter is optional.

.PARAMETER Number
    The phone number for the Duo phone. This parameter is optional. The number must be unique.

.PARAMETER Extension
    The extension number for the Duo phone. This parameter is optional and part of the Ext parameter set.

.PARAMETER Type
    The type of the Duo phone. Valid values are "Mobile", "Landline", and "Unknown". This parameter is optional.

.PARAMETER Platform
    The platform of the Duo phone. Valid values are "Google Android", "Apple ios", "Windows Mobile", "Palm WebOS", "Java j2me", "Generic SmartPhone", "Rim Blackberry", and "Symbian OS". This parameter is optional.

.PARAMETER Predelay
    The pre-delay time for the Duo phone. This parameter is optional and part of the Ext parameter set.

.PARAMETER PostDelay
    The post-delay time for the Duo phone. This parameter is optional and part of the Ext parameter set.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>

    Param(
        [Parameter(Mandatory=$false)]
            [String]$Name,
        [Parameter(Mandatory=$false)]
        [ValidateScript({
            If(Test-DuoPhone -Number $_){Throw "Number is already in use"}
            Else{$true}
        })]
        [String]$Number,

        [Parameter(ParameterSetName="Ext",
            Mandatory=$false)]
        [String]$Extension,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Mobile","Landline","Unknown")]
        [String]$Type,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Google Android","Apple ios","Windows Mobile","Palm WebOS","Java j2me","Generic SmartPhone","Rim Blackberry","Symbian OS")]
        [String]$Platform,
        
        [Parameter(ParameterSetName="Ext",
            Mandatory=$false
        )]
        [Int]$Predelay,
        
        [Parameter(ParameterSetName="Ext",
            Mandatory=$false
        )]
        [Int]$PostDelay
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/phones"
    [Hashtable]$DuoParams = @{}

    If($Name){
        $DuoParams.Add("name",$Name)
    }
    If($Number){
        $DuoParams.Add("number",$Number)
    }
    If($Extension){
        $DuoParams.Add("extension",$Extension)
    }
    If($Type){
        $DuoParams.Add("type",$type.ToLower())
    }
    If($Platform){
        $DuoParams.Add("Platform",$Platform.ToLower())
    }
    If($Predelay){
        $DuoParams.Add("predelay",$Predelay)
    }
    If($PostDelay){
        $DuoParams.Add("postdelay",$PostDelay)
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

Function Set-DuoPhone{
<#
.SYNOPSIS
    Updates the details of a Duo phone.

.DESCRIPTION
    This function updates the details of a specified Duo phone. It allows modifying the phone's name, number, extension, type, platform, and delay settings.

.PARAMETER PhoneID
    The ID of the Duo phone to be updated. This parameter is mandatory.

.PARAMETER Name
    The new name for the Duo phone. This parameter is optional.

.PARAMETER Number
    The new phone number for the Duo phone. This parameter is optional.

.PARAMETER Extension
    The extension number for the Duo phone. This parameter is optional and part of the Ext parameter set.

.PARAMETER Type
    The type of the Duo phone. Valid values are "Mobile", "Landline", and "Unknown". This parameter is optional.

.PARAMETER Platform
    The platform of the Duo phone. Valid values are "Google Android", "Apple ios", "Windows Mobile", "Palm WebOS", "Java j2me", "Generic SmartPhone", "Rim Blackberry", and "Symbian OS". This parameter is optional.

.PARAMETER Predelay
    The pre-delay time for the Duo phone. This parameter is optional and part of the Ext parameter set.

.PARAMETER PostDelay
    The post-delay time for the Duo phone. This parameter is optional and part of the Ext parameter set.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>

    [CmdletBinding(DefaultParameterSetName="None")]
    Param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoPhone -PhoneID $_){$true}
            Else{Throw "Invalid ID"}
        })]
            [String]$PhoneID,
        [Parameter(Mandatory=$false)]
            [String]$Name,
        [Parameter(Mandatory=$false)]
            [String]$Number,
        [Parameter(ParameterSetName="Ext",
            Mandatory=$false)]
            [String]$Extension,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Mobile","Landline","Unknown")]
            [String]$Type,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Google Android","Apple ios","Windows Mobile","Palm WebOS","Java j2me","Generic SmartPhone","Rim Blackberry","Symbian OS")]
            [String]$Platform,
        [Parameter(ParameterSetName="Ext",
            Mandatory=$false)]
            [Int]$Predelay,
        [Parameter(ParameterSetName="Ext",
            Mandatory=$false)]
            [Int]$PostDelay
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/phones/$($PhoneID)"
    [Hashtable]$DuoParams = @{}
    
    If($Name){
        $DuoParams.Add("name",$Name)
    }
    If($Number){
        $DuoParams.Add("number",$Number)
    }
    If($Extension){
        $DuoParams.Add("extension",$Extension)
    }
    If($Type){
        $DuoParams.Add("type",$type.ToLower())
    }
    If($Platform){
        $DuoParams.Add("Platform",$Platform.ToLower())
    }
    If($Predelay){
        $DuoParams.Add("predelay",$Predelay)
    }
    If($PostDelay){
        $DuoParams.Add("postdelay",$PostDelay)
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

Function Remove-DuoPhone{
<#
.SYNOPSIS
    Removes a phone from Duo.

.DESCRIPTION
    This function removes a specified phone from Duo by PhoneID.

.PARAMETER PhoneID
    The ID of the Duo phone to be removed. This parameter is mandatory.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>

    Param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoPhone -PhoneID $_){$true}
            Else{Throw "Invalid ID"}
        })]
            [String]$PhoneID
    )

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/phones/$($PhoneID)"
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

Function New-DuoMobileActivationCode{
<#
.SYNOPSIS
    Generates a new mobile activation code for a Duo phone.

.DESCRIPTION
    This function generates a new mobile activation code for a specified Duo phone. It allows setting an expiration time and optionally sends the activation code via SMS.

.PARAMETER PhoneID
    The ID of the Duo phone. This parameter is mandatory.

.PARAMETER ExpirationDate
    The date and time when the activation code expires. This parameter is optional and is part of the DateTime parameter set.

.PARAMETER TimeToExpire
    The number of seconds until the activation code expires. This parameter is optional and is part of the Seconds parameter set.

.PARAMETER Install
    If specified, the activation code will include installation instructions.

.PARAMETER SendSMS
    If specified, the activation code will be sent via SMS.

.PARAMETER Activation_Message
    The message to include with the activation SMS. This parameter is mandatory when using the Send parameter set.

.PARAMETER Installation_Message
    The message to include with the installation SMS. This parameter is optional.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>

    [CmdletBinding(DefaultParameterSetName="None")]
    Param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoPhone -PhoneID $_){$true}
            Else{Throw "Invalid ID"}
        })]
            [String]$PhoneID,

        [Parameter(ParameterSetName="DateTime",
            Mandatory=$false
        )]
        [Parameter(ParameterSetName="Seconds",
            Mandatory=$false
        )]
            [DateTime]$ExpirationDate,
        [Parameter(ParameterSetName="Seconds",
            Mandatory=$false
        )]
            [Int]$TimeToExpire,

        [Parameter(Mandatory=$false)]
            [Switch]$Install,
        [Parameter(ParameterSetName="Send",
            Mandatory=$false
        )]
        [Parameter(ParameterSetName="Seconds",
            Mandatory=$false
        )]
            [Switch]$SendSMS,

        [Parameter(ParameterSetName="Send",
            Mandatory=$true
        )]
        [Parameter(ParameterSetName="Seconds",
            Mandatory=$false
        )]
            [String]$Activation_Message,
        [Parameter(ParameterSetName="Send",
            Mandatory=$false
        )]
        [Parameter(ParameterSetName="Seconds",
            Mandatory=$false
        )]
            [String]$Installation_Message
    )

    If($ExpirationDate){
        $TimeToExpire = [Math]::Round(($ExpirationDate - (Get-Date)).TotalSeconds)
    }
    ElseIf($TimeToExpire){
        $ExpireTime = $TimeToExpire
    }
    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/phones/$($PhoneID)/activation_url"
    [Hashtable]$DuoParams = @{}
    
    If($Install){
        $DuoParams.Add("install","1")
    }
    If($ExpireTime){
        $DuoParams.Add("valid_secs",$ExpireTime)
    }

    If($SendSMS){
        #Base claim
        [String]$Uri = "/admin/v1/phones/$($PhoneID)/send_sms_activation_url"
        If($Activation_Message){
            $DuoParams.Add("activation_msg",$Activation_Message)
        }
        If($Installation_Message){
            $DuoParams.Add("installation_msg",$Installation_Message)
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