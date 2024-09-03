Function Sync-DuoUser{
<#
.SYNOPSIS
    Syncs a user from Duo to from directory within Duo

.DESCRIPTION
     Syncs a user from Duo to from directory

.PARAMETER Username
    Sync user by their Duo username

.PARAMETER UserID
    Sync user by their Duo UserID

.PARAMETER Directory
    The intended directory you wish to sync from

.Parameter Email
    Switch to change username search to email if normalization is on

.OUTPUTS
    [PSCustomObject]DuoRequest

.EXAMPLE
    Sync-DuoUser -Username DuoUser1 -Directory "DuoDirectory"

.EXAMPLE
    Sync-Duouser -Username DuoUser1@Duosecurity.com -Directory "DuoDirectory"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    Param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeLine=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "User: $($_) doesn't exist in Duo"}
        })]
            [String]$Username,
        [Parameter(
            Mandatory=$true,
            Position=1)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            If($_ -In (Get-DuoDirectoryNames)){$true}
            Else{Throw "$($_) is an invalid directory"}
        })]
            [String]$Directory,
        [Parameter(
            Mandatory=$false,
            Position=2
        )]
            [Switch]$Email
    )
    
    $dKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR((Get-DuoDirectoryKey -DirectoryName $Directory)))
    
    #Base Claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/users/directorysync/$($dKey)/syncuser"
    [Hashtable]$DuoParams = @{}

    #$User = Get-DuoUser -Username $Username
    If($Email){$VerifiedUsername = (Get-Duouser -Username $Username).email}
    Else{$VerifiedUsername = $Username}
    $DuoParams.Add("username",$VerifiedUsername.ToLower())

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

Function Get-DuoUser {
<#
.Synopsis
    Utilizing Duo REST API to return user(s)
.DESCRIPTION
    Returns a list of Duo users or an individual user

.EXAMPLE
    Get-DuoUser
    Returns all users from Duo. Initiates a call for each 300

.EXAMPLE
    Get-UserUser -Username TestUser

.EXAMPLE
    Get-UserUser -UserID ABCDEF12G34567HIJKLM

.OUTPUTS
    [PSCustomObject]$DuoUsers

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    [CmdletBinding(DefaultParameterSetName="Uname")]
    PARAM(
        [Parameter(ParameterSetName="UName",
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=0
            )]
            [String]$Username,
        [Parameter(ParameterSetName="UID",
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$UserID
    )

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/users"
    [Hashtable]$DuoParams = @{}

    If($Username){
        $DuoParams.Add("username",$Username.ToLower())
    }
    ElseIf($UserID){    
        $Uri = "/admin/v1/users/$($UserID)"
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

Function New-DuoUser{
<#
.SYNOPSIS
    Creates a new user within Duo with Duo as the source

.DESCRIPTION
     Creates a new user within Duo

.PARAMETER Username
    New user's username

.PARAMETER Alias1
    First alias for the new user

.PARAMETER Alias2
    Second alias for the new user

.PARAMETER Alias3
    Third alias for the new user

.PARAMETER Alias4
    Fourth alias for the new user

.PARAMETER Realname
    The user's realname

.PARAMETER Firstname
    User's first name

.PARAMETER Lastname
    User's last name

.Parameter Email
    User's email address

.Parameter Status
    Status for the account to be created with either Active, Bypass, or Disabled

.Parameter Notes
    Any notes to be included on the Duo account

.OUTPUTS
    [PSCustomObject]DuoRequest

.EXAMPLE
    New-DuoUser -Username DuoUser1

.EXAMPLE
    New-DuoUser -Username DuoUser1 -email DuoUser1@duosecurity.com

.EXAMPLE
    New-DuoUser -UserName DuoUser1 -email DuoUser1@duosecurity.com -alias1 DuoDemo -Status Disabled -Notes "Demo purposes"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){Throw "User: $($_) already exist in Duo"}
            Else{$true}
        })]
        [String]$Username,
        
        [Parameter(Mandatory=$false)]
        [String]$Alias1,
        
        [Parameter(Mandatory=$false)]
        [String]$Alias2,
        
        [Parameter(Mandatory=$false)]
        [String]$Alias3,
        
        [Parameter(Mandatory=$false)]
        [String]$Alias4,
        
        [Parameter(Mandatory=$false)]
        [String]$Realname,
        
        [Parameter(Mandatory=$false)]
        [String]$Firstname,
        
        [Parameter(Mandatory=$false)]
        [String]$Lastname,
        
        [Parameter(Mandatory=$false)]
        [String]$Email,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Active","Bypass","Disabled")]
        [String]$Status,
        
        [Parameter(Mandatory=$false)]
        [String]$Notes
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/users"
    [Hashtable]$DuoParams = @{}

    #Add Username
    $DuoParams.Add("username",$Username.ToLower())

    #Add Optional Parameters
    If($Alias1){$DuoParams.Add("alias1",$Alias1.ToLower())}
    If($Alias2){$DuoParams.Add("alias2",$Alias2.ToLower())}
    If($Alias3){$DuoParams.Add("alias3",$Alias3.ToLower())}
    If($Alias4){$DuoParams.Add("alias4",$Alias4.ToLower())}
    If($Realname){$DuoParams.Add("realname",$Realname)}
    If($Firstname){$DuoParams.Add("firstname",$Firstname)}
    If($Lastname){$DuoParams.Add("lastname",$Lastname)}
    If($Email){$DuoParams.Add("email",$Email.ToLower())}
    If($Status){$DuoParams.Add("status",$Status.ToLower())}
    If($Notes){$DuoParams.Add("notes",$Notes)}

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

Function Set-DuoUser{
<#
.SYNOPSIS
    Sets fields on a Duo user account.

.DESCRIPTION
    Sets fields on a Duo user account.

.PARAMETER Username
    Sync user by their Duo username

.PARAMETER UserID
    Sync user by their Duo UserID

.PARAMETER Directory
    The intended directory you wish to sync from

.Parameter Email
    Switch to change username search to email if normalization is on

.OUTPUTS
    [PSCustomObject]DuoRequest

.EXAMPLE
    Set-DuoUser -Username DuoUser1 -Directory "DuoDirectory"

.EXAMPLE
    Set-Duouser -Username DuoUser1@Duosecurity.com -Directory "DuoDirectory"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    Param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipleLine=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserID $_){$true}
            Else{Throw "Invalid User ID"}
        })]
        [String]$UserID,

        [Parameter(
            Mandatory=$false,
            ValueFromPipleLine=$true,
            Position=1
        )]
        [String]$Username,

        [Parameter(Mandatory=$false)]
        [String]$Alias1,

        [Parameter(Mandatory=$false)]
        [String]$Alias2,

        [Parameter(Mandatory=$false)]
        [String]$Alias3,

        [Parameter(Mandatory=$false)]
        [String]$Alias4,

        [Parameter(Mandatory=$false)]
        [String]$RealName,
        
        [Parameter(Mandatory=$false)]
        [String]$FirstName,
        
        [Parameter(Mandatory=$false)]
        [String]$LastName,
        
        [Parameter(Mandatory=$false)]
        [String]$Email,
        
        [ValidateSet("Active","Bypass","Disabled")]
        [String]$Status,
        
        [Parameter(Mandatory=$false)]
        [String]$Notes
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/users/$($UserID)"
    [Hashtable]$DuoParams = @{}

    #Create claim with selected attributes to be modified
    If($Username){$DuoParams.Add("username",$Username.ToLower())}
    If($Alias1){$DuoParams.Add("Alias1",$alias1.ToLower())}
    If($Alias2){$DuoParams.Add("Alias2",$alias2.ToLower())}
    If($Alias3){$DuoParams.Add("Alias3",$alias3.ToLower())}
    If($Alias4){$DuoParams.Add("Alias4",$alias4.ToLower())}
    If($RealName){$DuoParams.Add("realname",$RealName)}
    If($FirstName){$DuoParams.Add("firstname",$FirstName)}
    If($LastName){$DuoParams.Add("lastname",$LastName)}
    If($Email){$DuoParams.Add("email",$Email.ToLower())}
    If($Status){$DuoParams.Add("status",$Status.ToLower())}
    If($Notes){$DuoParams.Add("Notes",$Notes)}

    #Creates the request
    $Request = New-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
    $Response = Invoke-RestMethod @Request
    #Error Handling
    If($Response.stat -ne 'OK'){
        Write-Warning 'DUO REST Call Failed'
        Write-Warning "Arguments:"+($DuoParams | Out-String)
        Write-Warning "Method:$Method    Path:$Uri"
    }
    #Returning request
    Else{
        $Output = $Response | Select-Object -ExpandProperty Response 
        $Output
    }
}

Function Remove-DuoUser{
<#
.SYNOPSIS
    Removes a Duo user.

.DESCRIPTION
    This function removes a specified Duo user by UserID. It includes an optional confirmation prompt unless the Force switch is used.

.PARAMETER UserID
    The user ID of the Duo user to be removed. This parameter is mandatory.

.PARAMETER Force
    If specified, the user will be removed without a confirmation prompt.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>

    PARAM(
        [Parameter(
            Mandatory=$true,
            ValueFromPipleLine=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserID $_){$true}
            Else{Throw "Invalid User ID"}
        })]$UserID,

        [Switch]$Force
    )
    $Username = (Get-DuoUser -UserID $UserID).username
    If($Force -eq $false){
        $Confirm = $Host.UI.PromptForChoice("Please Confirm","Are you sure you want to delete $($Username) from Duo?",@("Yes","No"),1)
    }

    #
    If(($Force -eq $true) -or ($Confirm -eq 0)){
        #Base claim
        [String]$Method = "POST"
        [String]$Uri = "/admin/v1/users/$($UserID)"

        #Creates the request
        $Request = New-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
        $Response = Invoke-RestMethod @Request
        
        #Error Handling
        If($Response.stat -ne 'OK'){
            Write-Warning 'DUO REST Call Failed'
            Write-Warning "Arguments:"+($DuoParams | Out-String)
            Write-Warning "Method:$Method    Path:$Uri"
        }
        #Returning request
        Else{
            $Output = $Response | Select-Object -ExpandProperty Response 
            $Output
        }
    }
}

Function New-DuoUserEnrollment{
<#
.SYNOPSIS
    Enrolls a new Duo user.

.DESCRIPTION
    This function enrolls a new Duo user by specifying the username and email. It also allows setting an expiration time for the enrollment.

.PARAMETER Username
    The Duo username to be enrolled. This parameter is mandatory.

.PARAMETER Email
    The email address to be enrolled. This parameter is mandatory.

.PARAMETER ExpirationDate
    The date and time when the enrollment expires. This parameter is optional and is part of the DateTime parameter set.

.PARAMETER TimeToExpire
    The number of seconds until the enrollment expires. This parameter is optional and is part of the Seconds parameter set.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>

    Param(
        [Parameter(
            Mandatory=$true,
            HelpMessage="Duo username to be enrolled",
            ValueFromPipleLine=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -Username $_){$true}
            Else{Throw "Invalid User ID"}
        })]
        [String]$Username,

        [Parameter(
            Mandatory=$true,
            HelpMessage="Email to be enrolled",
            ValueFromPipeline=$true,
            Position=1
        )]
        [MailAddress]$Email,

        [Parameter(ParameterSetName="DateTime",
            HelpMessage="DateTime for when enrollment expires",
            Mandatory=$false,
            ValueFromPipeline=$false,
            Position=2
        )]
        [DateTime]$ExpirationDate,

        [Parameter(ParameterSetName="Seconds",
            HelpMessage="How many seconds until enrollment expires",
            Mandatory=$false,
            ValueFromPipeline=$false,
            Position=2
        )]
        [Int]$TimeToExpire
    )

    If($ExpirationDate){
        $Time = ($ExpirationDate - (Get-Date)).TotalSeconds
    }
    ElseIf($TimeToExpire){
        $Time = $TimeToExpire
    }


    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/users/enroll"
    [Hashtable]$DuoParams = @{}

    $DuoParams.Add("username",$Username.ToLower())
    $DuoParams.Add("email",$Email.ToString().ToLower())
    If($Time){
        $Time = [Math]::Round($Time)
        $DuoParams.Add("valid_secs",$Time.ToString())
    }

    #Creates the request
    $Request = New-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
    $Response = Invoke-RestMethod @Request
    
    #Error Handling
    If($Response.stat -ne 'OK'){
        Write-Warning 'DUO REST Call Failed'
        Write-Warning "Arguments:"+($DuoParams | Out-String)
        Write-Warning "Method:$Method    Path:$Uri"
    }
    #Returning request
    Else{
        $Output = $Response | Select-Object -ExpandProperty Response 
        $Output
    }
}

Function New-DuoUserBypassCode{
<#
.SYNOPSIS
    Creates new bypass codes for a Duo user.

.DESCRIPTION
    This function creates new bypass codes for a specified Duo user. It allows for defining the number of codes, specific codes, number of uses, and expiration time.

.PARAMETER Username
    The username of the Duo user. This parameter is mandatory.

.PARAMETER Count
    The number of bypass codes to create. The maximum is 10. This parameter is optional.

.PARAMETER Codes
    Specific bypass codes to be used. The maximum is 10. This parameter is optional.

.PARAMETER NumberOfUses
    The number of times the bypass codes can be used. The default is 1. This parameter is optional.

.PARAMETER ExpirationDate
    The expiration date and time for the bypass codes. This parameter is optional and is part of the DateTime parameter set.

.PARAMETER TimeToExpire
    The number of seconds until the bypass codes expire. This parameter is optional and is part of the Seconds parameter set.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>

    Param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipleLine=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -Username $_){$true}
            Else{Throw "Invalid User ID"}
        })]
        [String]$Username,

        [Parameter(
            Mandatory=$false,
            HelpMessage="Define bypass codes to be used. Maximum of 10",
            ValueFromPipeline=$false
        )]
        [Int]$Count,
        
        [Parameter(
            Mandatory=$false,
            HelpMessage="Define bypass codes to be used. Maximum of 10",
            ValueFromPipeline=$false
        )]
        [String]$Codes,

        [Parameter(
            Mandatory=$false,
            HelpMessage="Number of times the bypass codes can be used. Default of 1",
            ValueFromPipeline=$false
        )]
        [Int]$NumberOfUses,

        [Parameter(ParameterSetName="DateTime",
            HelpMessage="DateTime for when bypass codes expire",
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [DateTime]$ExpirationDate,

        [Parameter(ParameterSetName="Seconds",
            HelpMessage="How many seconds until bypass code expires",
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [Int]$TimeToExpire
    )
    $UserID = (Get-DuoUser -Username $Username).user_id

    If($ExpirationDate){
        $Time = [Math]::Round(($ExpirationDate - (Get-Date)).TotalSeconds)
    }
    ElseIf($TimeToExpire){
        $Time = $TimeToExpire
    }
    Else{
        $Time = 3600
    }

    If($Count -eq $null){
        $Count = 1
    }

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/users/$($UserID)/bypass_codes"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("count",$Count.ToString())
    If($Codes){
        $Codes = $Codes | ConvertTo-Csv -NoTypeInformation
        $DuoParams.Add("codes",$Codes)
    }
    If($NumberOfUses){
        $DuoParams.Add("resuse_count",$NumberOfUses)
    }
    $DuoParams.Add("valid_secs",$Time.ToString())

    #Creates the request
    $Request = New-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
    $Response = Invoke-RestMethod @Request
    
    #Error Handling
    If($Response.stat -ne 'OK'){
        Write-Warning 'DUO REST Call Failed'
        Write-Warning "Arguments:"+($DuoParams | Out-String)
        Write-Warning "Method:$Method    Path:$Uri"
    }
    #Returning request
    Else{
        $Output = $Response | Select-Object -ExpandProperty Response 
        $Output
    }
}

Function Get-DuoUserBypassCode{
<#
.SYNOPSIS
    Retrieves bypass codes associated with a Duo user.

.DESCRIPTION
    This function retrieves bypass codes associated with a Duo user based on the provided parameters. It can fetch bypass codes by Username or UserID.

.PARAMETER Username
    The username of the Duo user. This parameter is optional and can be piped.

.PARAMETER UserID
    The user ID of the Duo user. This parameter is optional.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>

    [CmdletBinding(DefaultParameterSetName="Uname")]
    PARAM(
        [Parameter(ParameterSetName="UName",
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=0
            )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "User: $($_) doesn't exist in Duo"}
        })]
        [String]$Username,
        
        [Parameter(ParameterSetName="UID",
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=0
            )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "UserID: $($_) doesn't exist in Duo"}
        })]
        [String]$UserID
    )

    If($Username){
        $UserID = (Get-DuoUser -Username $Username).user_id
    }

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/users/$($UserID)/bypass_codes"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("limit","300")
    $DuoParams.Add("offset","0")

    #Creates the request
    $Request = New-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
    $Response = Invoke-RestMethod @Request
    
    #Call private function to validate and format the request
    $Request = New-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
    $Offset = 0

    #Duo has a 500 bypass code limit in their api. Loop to return all bypass codes
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
            $Offset += 500
        }
    }Until($Output.Count -lt 500)
}

Function Get-DuoUserGroup{
<#
.SYNOPSIS
    Retrieves groups associated with a Duo user.

.DESCRIPTION
    This function retrieves groups associated with a Duo user based on the provided parameters. It can fetch groups by Username or UserID.

.PARAMETER Username
    The username of the Duo user. This parameter is optional and can be piped.

.PARAMETER UserID
    The user ID of the Duo user. This parameter is optional.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>

    [CmdletBinding(DefaultParameterSetName="Uname")]
    PARAM(
        [Parameter(ParameterSetName="UName",
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=0
            )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "User: $($_) doesn't exist in Duo"}
        })]
        [String]$Username,
        
        [Parameter(ParameterSetName="UID",
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=0
            )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "UserID: $($_) doesn't exist in Duo"}
        })]
        [String]$UserID
    )

    If($Username){
        $UserID = (Get-DuoUser -Username $Username).user_id
    }

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/users/$($UserID)/groups"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("limit","300")
    $DuoParams.Add("offset","0")

    #Creates the request
    $Request = New-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
    $Response = Invoke-RestMethod @Request
    
    #Call private function to validate and format the request
    $Request = New-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
    $Offset = 0

    #Duo has a 500 bypass code limit in their api. Loop to return all bypass codes
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
            $Offset += 500
        }
    }Until($Output.Count -lt 500)
}

Function Add-DuoGroupMember{
<#
.SYNOPSIS
    Adds a user to a Duo group.

.DESCRIPTION
    This function adds a user to a specified Duo group based on the provided parameters. It can add users by Username or UserID.

.PARAMETER Username
    The username of the Duo user. This parameter is mandatory when using the Uname parameter set.

.PARAMETER UserID
    The user ID of the Duo user. This parameter is mandatory when using the UID parameter set.

.PARAMETER GroupID
    The ID of the Duo group to which the user will be added. This parameter is mandatory.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>

    [CmdletBinding(DefaultParameterSetName="Uname")]
    Param(
        [Parameter(ParameterSetName="Uname",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "User: $($_) doesn't exist in Duo"}
        })]
        [String]$Username,

        [Parameter(ParameterSetName="UID",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserID $_){$true}
            Else{Throw "UserID: $($_) doesn't exist in Duo"}
        })]
        [String]$UserID,
        
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=1
        )]
        [ValidateScript({
            If(Test-DuoGroup -GroupID $_){$true}
            Else{Throw "GroupID: $($_) doesn't exist in Duo"}
        })]
        [String]$GroupID
    )

    If($Username){
        $UserID = (Get-DuoUser -Username $Username).user_id
    }

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/users/$($UserID)/groups"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("group_id",$GroupID)

    #Creates the request
    $Request = New-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
    $Response = Invoke-RestMethod @Request
    
    #Error Handling
    If($Response.stat -ne 'OK'){
        Write-Warning 'DUO REST Call Failed'
        Write-Warning "Arguments:"+($DuoParams | Out-String)
        Write-Warning "Method:$Method    Path:$Uri"
    }
    #Returning request
    Else{
        $Output = $Response | Select-Object -ExpandProperty Response 
        $Output
    }
}

Function Remove-DuoGroupMember{
<#
.SYNOPSIS
    Removes a user from a Duo group.

.DESCRIPTION
    This function removes a user from a specified Duo group based on the provided parameters. It can remove users by Username or UserID.

.PARAMETER Username
    The username of the Duo user. This parameter is mandatory when using the Uname parameter set.

.PARAMETER UserID
    The user ID of the Duo user. This parameter is mandatory when using the UID parameter set.

.PARAMETER GroupID
    The ID of the Duo group from which the user will be removed. This parameter is mandatory.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>

    [CmdletBinding(DefaultParameterSetName="Uname")]
    Param(
        [Parameter(ParameterSetName="Uname",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "User: $($_) doesn't exist in Duo"}
        })]
        [String]$Username,

        [Parameter(ParameterSetName="UID",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserID $_){$true}
            Else{Throw "UserID: $($_) doesn't exist in Duo"}
        })]
        [String]$UserID,

        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=1
        )]
        [ValidateScript({
            If(Test-DuoGroup -GroupID $_){$true}
            Else{Throw "GroupID: $($_) doesn't exist in Duo"}
        })]
        [String]$GroupID
    )

    If($Username){
        $UserID = (Get-DuoUser -Username $Username).user_id
    }

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/users/$($UserID)/groups/$($GroupID)"
    [Hashtable]$DuoParams = @{}

    #Creates the request
    $Request = New-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
    $Response = Invoke-RestMethod @Request
    
    #Error Handling
    If($Response.stat -ne 'OK'){
        Write-Warning 'DUO REST Call Failed'
        Write-Warning "Arguments:"+($DuoParams | Out-String)
        Write-Warning "Method:$Method    Path:$Uri"
    }
    #Returning request
    Else{
        $Output = $Response | Select-Object -ExpandProperty Response 
        $Output
    }
}

Function Get-DuoUserPhone{
<#
.SYNOPSIS
    Retrieves phones associated with a Duo user.

.DESCRIPTION
    This function retrieves phones associated with a Duo user based on the provided parameters. It can fetch phones by Username or UserID.

.PARAMETER Username
    The username of the Duo user. This parameter is mandatory when using the Uname parameter set.

.PARAMETER UserID
    The user ID of the Duo user. This parameter is mandatory when using the UID parameter set.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>

    [CmdletBinding(DefaultParameterSetName="Uname")]
    Param(
        [Parameter(ParameterSetName="Uname",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "User: $($_) doesn't exist in Duo"}
        })]
        [String]$Username,

        [Parameter(ParameterSetName="UID",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserID $_){$true}
            Else{Throw "UserID: $($_) doesn't exist in Duo"}
        })]
        [String]$UserID
    )

    If($Username){
        $UserID = (Get-DuoUser -Username $Username).user_id
    }

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/users/$($UserID)/phones"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("limit","500")
    $DuoParams.Add("offset","0")
    
    $Offset = 0

    #Duo has a 500 phone limit in their api. Loop to return all phones
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
            #Increment offset to return the next 500 phones
            $Offset += 500
        }
    }Until($Output.Count -lt 500)
}

Function Add-DuoPhoneMember{
<#
.SYNOPSIS
    Adds a phone to a Duo user.

.DESCRIPTION
    This function adds a phone to a Duo user based on the provided parameters. It can add phones by Username or UserID and PhoneNumber or PhoneID.

.PARAMETER Username
    The username of the Duo user. This parameter is mandatory when using the Uname parameter set.

.PARAMETER UserID
    The user ID of the Duo user. This parameter is mandatory when using the UID parameter set.

.PARAMETER PhoneNumber
    The phone number to add. This parameter is mandatory when using the Pnumber parameter set. The phone number must be in E.164 format.

.PARAMETER PhoneID
    The phone ID to add. This parameter is mandatory when using the PID parameter set.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>

[CmdletBinding(DefaultParameterSetName="Uname")]
    Param(
        [Parameter(ParameterSetName="Uname",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "User: $($_) doesn't exist in Duo"}
        })]
        [String]$Username,

        [Parameter(ParameterSetName="UID",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserID $_){$true}
            Else{Throw "UserID: $($_) doesn't exist in Duo"}
        })]
        [String]$UserID,

        [Parameter(ParameterSetName="Pnumber",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=1
        )]
        [ValidateScript({
            If(Validate-PhoneNumber -PhoneNumber $_){
                If(Test-DuoPhone -Number $_){$true}
                Else{Throw "User: $($_) doesn't exist in Duo"}
            }
            Else{Throw "Invalid phone number. Please use E. 164 format."}
        })]
        [String]$PhoneNumber,

        [Parameter(ParameterSetName="PID",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=1
        )]
        [ValidateScript({
            If(Test-DuoPhone -PhoneID $_){$true}
            Else{Throw "UserID: $($_) doesn't exist in Duo"}
        })]
        [String]$PhoneID
    )

    If($Username){
        $UserID = (Get-DuoUser -Username $Username).user_id
    }
    If($PhoneNumber){
        $PhoneID = (Get-DuoPhone -Number $PhoneNumber).phone_id
    }

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/users/$($UserID)/phones"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("phone_id",$PhoneID)

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

Function Remove-DuoPhoneMember{
<#
.SYNOPSIS
    Removes a phone from a Duo user.

.DESCRIPTION
    This function removes a phone associated with a Duo user based on the provided parameters. It can remove phones by Username or UserID and PhoneNumber or PhoneID.

.PARAMETER Username
    The username of the Duo user. This parameter is mandatory when using the Uname parameter set.

.PARAMETER UserID
    The user ID of the Duo user. This parameter is mandatory when using the UID parameter set.

.PARAMETER PhoneNumber
    The phone number to remove. This parameter is mandatory when using the Pnumber parameter set. The phone number must be in E.164 format.

.PARAMETER PhoneID
    The phone ID to remove. This parameter is mandatory when using the PID parameter set.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>

    [CmdletBinding(DefaultParameterSetName="Uname")]
    Param(
        [Parameter(ParameterSetName="Uname",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "User: $($_) doesn't exist in Duo"}
        })]
        [String]$Username,

        [Parameter(ParameterSetName="UID",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserID $_){$true}
            Else{Throw "UserID: $($_) doesn't exist in Duo"}
        })]
        [String]$UserID,

        [Parameter(ParameterSetName="Pnumber",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=1
        )]
        [ValidateScript({
            If(Validate-PhoneNumber -PhoneNumber $_){
                If(Test-DuoPhone -Number $_){$true}
                Else{Throw "User: $($_) doesn't exist in Duo"}
            }
            Else{Throw "Invalid phone number. Please use E. 164 format."}
        })]
        [String]$PhoneNumber,

        [Parameter(ParameterSetName="PID",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=1
        )]
        [ValidateScript({
            If(Test-DuoPhone -PhoneID $_){$true}
            Else{Throw "UserID: $($_) doesn't exist in Duo"}
        })]
        [String]$PhoneID
    )

    If($Username){
        $UserID = (Get-DuoUser -Username $Username).user_id
    }
    If($PhoneNumber){
        $PhoneID = (Get-DuoPhone -Number $PhoneNumber).phone_id
    }

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/users/$($UserID)/phones"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("phone_id",$PhoneID)

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

Function Get-DuoUserToken{
<#
.SYNOPSIS
    Returns all tokens assocaited with a particular user.

.DESCRIPTION
    Get all tokens associated with a user.

.PARAMETER Username
    Duo user's username

.PARAMETER UserID
    Dou user's ID

.PARAMETER TokenID
    Duo token's ID

.Parameter Serial
    Token's serial number. Requires -Type

.Parameter Type
    Token type, HOTP-6,HOTP-8,YubiKey, or Duo-D100. Requires -Serial

.OUTPUTS
    [PSCustomObject]DuoRequest

.EXAMPLE
    Get-DuoUserToken -UserID 123ABCDE456FGH -TokenID 12356879456DFD

.EXAMPLE
    Get-DuoUserToken -Username duouser -Serial DDF2341DFBKL5457 -Type YubiKey

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    [CmdletBinding(DefaultParameterSetName="Uname")]
    Param(
        [Parameter(ParameterSetName="Uname",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "User: $($_) doesn't exist in Duo"}
        })]
        [String]$Username,

        [Parameter(ParameterSetName="UID",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserID $_){$true}
            Else{Throw "UserID: $($_) doesn't exist in Duo"}
        })]
        [String]$UserID
    )

    If($Username){
        $UserID = (Get-DuoUser -Username $Username).user_id
    }

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/users/$($UserID)/tokens"
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

Function Add-DuoTokenMember{
<#
.SYNOPSIS
    Associates a token token from a user.

.DESCRIPTION
    Adds a token from a Duo user.

.PARAMETER Username
    Duo user's username

.PARAMETER UserID
    Dou user's ID

.PARAMETER TokenID
    Duo token's ID

.Parameter Serial
    Token's serial number. Requires -Type

.Parameter Type
    Token type, HOTP-6,HOTP-8,YubiKey, or Duo-D100. Requires -Serial

.OUTPUTS
    [PSCustomObject]DuoRequest

.EXAMPLE
    Add-DuoTokenMember -UserID 123ABCDE456FGH -TokenID 12356879456DFD

.EXAMPLE
    Add-DuoTokenMember -Username duouser -Serial DDF2341DFBKL5457 -Type YubiKey

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>    
    [CmdletBinding(DefaultParameterSetName="Uname")]
    Param(
        [Parameter(ParameterSetName="Uname",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "User: $($_) doesn't exist in Duo"}
        })]
        [String]$Username,

        [Parameter(ParameterSetName="UID",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserID $_){$true}
            Else{Throw "UserID: $($_) doesn't exist in Duo"}
        })]
        [String]$UserID,

        [Parameter(ParameterSetName="TID",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=1
        )]
        [ValidateScript({
            If(Test-DuoToken -UserID $_){$true}
            Else{Throw "UserID: $($_) doesn't exist in Duo"}
        })]
        [String]$TokenID,

        [Parameter(ParameterSetName="Tserial",
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=1
        )]
        [String]$Serial,

        [Parameter(ParameterSetName="Tserial",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=2
        )]
        [ValidateSet("HOTP-6","HOTP-8","YubiKey","Duo-D100")]
        [String]$Type
    )

    If($Username){
        $UserID = (Get-DuoUser -Username $Username).user_id
    }
    If($Serial){
        $TokenID = (Get-DuoTokens -Serial $Serial -Type $Type).token_id
    }

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/users/$($UserID)/tokens"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("token_id",$TokenID)

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

Function Remove-DuoTokenMember{
<#
.SYNOPSIS
    Disassociates a token token from a user.

.DESCRIPTION
    Removes a token from a Duo user.

.PARAMETER Username
    Duo user's username

.PARAMETER UserID
    Dou user's ID

.PARAMETER TokenID
    Duo token's ID

.Parameter Serial
    Token's serial number. Requires -Type

.Parameter Type
    Token type, HOTP-6,HOTP-8,YubiKey, or Duo-D100. Requires -Serial

.OUTPUTS
    [PSCustomObject]DuoRequest

.EXAMPLE
    Remove-DuoTokenMember -UserID 123ABCDE456FGH -TokenID 12356879456DFD

.EXAMPLE
    Remove-DuoTokenMember -Username duouser -Serial DDF2341DFBKL5457 -Type YubiKey

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    [CmdletBinding(DefaultParameterSetName="Uname")]
    Param(
        [Parameter(ParameterSetName="Uname",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "User: $($_) doesn't exist in Duo"}
        })]
        [String]$Username,

        [Parameter(ParameterSetName="UID",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserID $_){$true}
            Else{Throw "UserID: $($_) doesn't exist in Duo"}
        })]
        [String]$UserID,

        [Parameter(ParameterSetName="TID",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=1
        )]
        [ValidateScript({
            If(Test-DuoToken -UserID $_){$true}
            Else{Throw "UserID: $($_) doesn't exist in Duo"}
        })]
        [String]$TokenID,
        
        [Parameter(ParameterSetName="Tserial",
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=1
            )]
        [String]$Serial,
        
        [Parameter(ParameterSetName="Tserial",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=2
        )]
        [ValidateSet("HOTP-6","HOTP-8","YubiKey","Duo-D100")]
        [String]$Type
    )

    If($Username){
        $UserID = (Get-DuoUser -Username $Username).user_id
    }
    If($Serial){
        $TokenID = (Get-DuoTokens -Serial $Serial -Type $Type).token_id
    }

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/users/$($UserID)/tokens"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("token_id",$TokenID)

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

Function Get-DuoUserWebAuthN{<#
.SYNOPSIS
    Get all WebAuthN keys associated with a particular user

.DESCRIPTION
    Returns all WebAuthN keys assocaited with an individual user    

.PARAMETER Username
    Duo User's username

.PARAMETER UserID
    Duo User's User DI

.OUTPUTS
    [PSCustomObject]DuoRequest

.EXAMPLE
    Get-DuoUseWebAuthN -UserID 123ABCDE456FGH

.EXAMPLE
  Get-DuoUserWebAuthN -Username duouser  

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    [CmdletBinding(DefaultParameterSetName="Uname")]
    Param(
        [Parameter(ParameterSetName="Uname",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "User: $($_) doesn't exist in Duo"}
        })]
        [String]$Username,
        
        [Parameter(ParameterSetName="UID",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserID $_){$true}
            Else{Throw "UserID: $($_) doesn't exist in Duo"}
        })]
        [String]$UserID
    )

    If($Username){
        $UserID = (Get-DuoUser -Username $Username).user_id
    }

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/users/$($UserID)/webauthncredentials"
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

Function Get-DuoUserDesktop {
<#
.SYNOPSIS
    Return Desktops associated with a particular user

.DESCRIPTION
    Returns all desktops associated with an individual user

.PARAMETER Username
    Duo user's username

.PARAMETER UserID
    Duo user's ID

.OUTPUTS
    [PSCustomObject]DuoRequest

.EXAMPLE
    Get-DuoUserDesktop -Username duouser@duosecurity.com

.EXAMPLE
    Get-DuoUserDesktop -UserID 123ABDE456FGH

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    [CmdletBinding(DefaultParameterSetName="Uname")]
    Param(
        [Parameter(ParameterSetName="Uname",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "User: $($_) doesn't exist in Duo"}
        })]
        [String]$Username,
        
        [Parameter(ParameterSetName="UID",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserID $_){$true}
            Else{Throw "UserID: $($_) doesn't exist in Duo"}
        })]
        [String]$UserID
    )

    If($Username){
        $UserID = (Get-DuoUser -Username $Username).user_id
    }

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/users/$($UserID)/desktopauthenticators"
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

Function Send-DuoPush {
<#
.SYNOPSIS
    Send a Duo Push Verification to identified user.

.DESCRIPTION
    Can send a Dup Push Verification to a specific user and returns the PushID for use with Get-DuoVerificationResponse

.PARAMETER Username
    Duo user's Username

.PARAMETER UserID
    Duo user's Duo user ID

.PARAMETER PhoneNumber
    Phone number of the phone associated with the user.

.Parameter PhoneID
    Duo's phone ID

.OUTPUTS
    [PSCustomObject]DuoRequest

.EXAMPLE
    Send-DuoPush -UserID 123ABCDE456FGHI -PhoneID 9875645ADFD

.EXAMPLE
    Send-DuoPush -Username Duouser@duosecurity.com -PhoneNumber +15555555555

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    [CmdletBinding(DefaultParameterSetName="Uname")]
    Param(
        [Parameter(ParameterSetName="Uname",
            Mandatory=$true,
            ValueFromPipeline=$false,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "User: $($_) doesn't exist in Duo"}
        })]
        [String]$Username,
        
        [Parameter(ParameterSetName="UID",
            Mandatory=$true,
            ValueFromPipeline=$false,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserID $_){$true}
            Else{Throw "UserID: $($_) doesn't exist in Duo"}
        })]
        [String]$UserID,

        [Parameter(ParameterSetName="UID",
            Mandatory=$true,
            ValueFromPipeline=$false,
            Position=1
        )]
        [ValidateScript({
            If(Test-DuoPhone -PhoneID $_){$true}
            Else{Throw "PhoneID: $($_) doesn't exist in Duo"}
        })]
        [String]$PhoneID,
        
        [Parameter(ParameterSetName="Uname",
            Mandatory=$true,
            ValueFromPipeline=$false,
            Position=1
        )]
        [ValidateScript({
            If(Test-DuoPhone -Number $_){$true}
            Else{Throw "Phone Number: $($_) doesn't exist in Duo"}
        })]
        [String]$PhoneNumber
    )

    If($Username){
        $UserID = (Get-DuoUser -Username $Username).user_id
    }
    IF($PhoneNumber){
        $PhoneID = (Get-DuoPhone -Number $PhoneNumber).phone_id
    }

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/users/$($UserID)/send_verification_push"
    [Hashtable]$DuoParams = @{}

    $DuoParams.Add("phone_id",$PhoneID)

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

Function Get-DuoVerificationResponse {
<#
.SYNOPSIS
    Check the response to a identified verification request.

.DESCRIPTION
    Returns the user's response to the verifictaion request.

.PARAMETER Username
    The user's username within Duo

.PARAMETER UserID
    The user's Duo ID

.PARAMETER PushID
    The ID of the Push request that was sent to the user.

.OUTPUTS
    [PSCustomObject]DuoRequest

.EXAMPLE
    Get-DuoVerificationResponse -UID 123ABCD456EFGH -PushID 987654ZYX

.EXAMPLE
    Get-DuoVerificationResponse -Username DuoUser@Duosecurity.com -PushID 987654ZYX

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    [CmdletBinding(DefaultParameterSetName="Uname")]
    Param(
        [Parameter(ParameterSetName="Uname",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "User: $($_) doesn't exist in Duo"}
        })]
        [String]$Username,

        [Parameter(ParameterSetName="UID",
            Mandatory=$true,
            ValueFromPipeline=$false,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserID $_){$true}
            Else{Throw "UserID: $($_) doesn't exist in Duo"}
        })]
        [String]$UserID,

        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=1
        )]
        [String]$PushID
    )

    If($Username){
        $UserID = (Get-DuoUser -Username $Username).user_id
    }
    IF($PhoneNumber){
        $PhoneID = (Get-DuoPhone -Number $PhoneNumber).phone_id
    }

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/users/$($UserID)/verification_push_response"
    [Hashtable]$DuoParams = @{}

    $DuoParams.Add("push_id",$PushID)

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