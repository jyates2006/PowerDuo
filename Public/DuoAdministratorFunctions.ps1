Function Get-DuoAdmin {
<#
.SYNOPSIS
    Retrieves information about Duo administrators.

.DESCRIPTION
    The Get-DuoAdmin function retrieves information about Duo administrators using the Duo Admin API. 
    It can retrieve details for a specific administrator if an AdminID is provided, or it can retrieve all administrators with pagination if no AdminID is specified.

.PARAMETER AdminID
    The ID of the administrator to retrieve. If not specified, the function retrieves all administrators with pagination.

.EXAMPLE
    Get-DuoAdmin -AdminID "12345"
    Retrieves information about the administrator with ID 12345.

.EXAMPLE
    Get-DuoAdmin
    Retrieves information about all administrators, handling pagination to ensure all administrators are retrieved.

.NOTES
    This function requires the New-DuoRequest function to create the API request and the Invoke-RestMethod cmdlet to send the request.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    PARAM(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoAdmin -AdminID $_){$true}
            Else{Throw "Error: Invalid Admin ID"}
        })]
        [String]$AdminID
    )

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/admins"
    [Hashtable]$DuoParams = @{}

    If($AdminID){    
        $Uri = "/admin/v1/admins/$($AdminID)"
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

Function New-DuoAdmin {
<#
.SYNOPSIS
    Creates a new Duo administrator.

.DESCRIPTION
    The New-DuoAdmin function creates a new Duo administrator with the specified details. 
    It sends a POST request to the Duo Admin API to perform this action.

.PARAMETER Email
    The email address of the new administrator. This parameter is mandatory.

.PARAMETER Name
    The name of the new administrator. This parameter is mandatory.

.PARAMETER Phone
    The phone number of the new administrator. Optional.

.PARAMETER RequirePasswordChange
    A boolean indicating whether the new administrator is required to change their password. Optional.

.PARAMETER Role
    The role of the new administrator. Optional.

.PARAMETER RestricedBy_AdminUnits
    A boolean indicating whether the new administrator is restricted by admin units. Optional.

.PARAMETER SendEmail
    A boolean indicating whether an email should be sent to the new administrator. Optional.

.PARAMETER TokenID
    The token ID for the new administrator. Optional.

.PARAMETER ExpirationDays
    The number of days the activation link should be valid. Optional.

.EXAMPLE
    New-DuoAdmin -Email "admin@example.com" -Name "John Doe" -Phone "555-1234" -Role "Owner" -SendEmail $true -ExpirationDays 7
    Creates a new administrator with the specified details and sends an email with an activation link valid for 7 days.

.NOTES
    This function requires the New-DuoRequest function to create the API request and the Invoke-RestMethod cmdlet to send the request.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
        )]
        [String]$Email,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=1
        )]
        [String]$Name,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$Phone,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$RequirePasswordChange,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false
        )]
        [ValidateSet("Owner", "Administrator", "Application Manager", "User Manager", "Security Analyst", "Help Desk", "Billing", "Phishing Manager","Read-only")]
        [String]$Role,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$RestricedBy_AdminUnits,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$SendEmail,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$TokenID,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Int]$ExpirationDays
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/admins"
    [Hashtable]$DuoParams = @{}

    $DuoParams.Add("email",$Email)
    $DuoParams.Add("name",$Name)
    If($Phone){
        $DuoParams.Add("phone",$Phone)
    }
    If($RequirePasswordChange){
        $DuoParams.Add("password_change_required",$RequirePasswordChange)
    }
    If($Role){
        $DuoParams.Add("role",$Role)
    }
    If($RestricedBy_AdminUnits){
        $DuoParams.Add("restricted_by_admin_units",$RestricedBy_AdminUnits)
    }
    If($SendEmail){
        Switch($SendEmail){
            $true {$DuoParams.Add("send_email",1)}
            $false {$DuoParams.Add("send_email",0)}
        }
    }
    If($TokenID){
        $DuoParams.Add("token_id",$TokenID)
    }
    If($ExpirationDays){
        $DuoParams.Add("valid_days",$ExpirationDays)
    }

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

Function Set-DuoAdmin {
<#
.SYNOPSIS
    Modifies the details of a Duo administrator.

.DESCRIPTION
    The Set-DuoAdmin function updates various details of a specified Duo administrator using their AdminID. 
    It supports multiple parameter sets to handle different types of updates, including resetting authentication attempts and clearing expiration.

.PARAMETER AdminID
    The ID of the administrator to be modified. This parameter is mandatory.

.PARAMETER Name
    The new name of the administrator. Optional.

.PARAMETER Phone
    The new phone number of the administrator. Optional.

.PARAMETER RequirePasswordChange
    A boolean indicating whether the administrator is required to change their password. Optional.

.PARAMETER Role
    The new role of the administrator. Optional.

.PARAMETER RestricedBy_AdminUnits
    A boolean indicating whether the administrator is restricted by admin units. Optional.

.PARAMETER Status
    The new status of the administrator. Optional.

.PARAMETER TokenID
    The new token ID for the administrator. Optional.

.PARAMETER ResetAuthAttempts
    A switch to reset the authentication attempts for the administrator. Optional.

.PARAMETER ClearExpiration
    A switch to clear the inactivity expiration for the administrator. Optional.

.EXAMPLE
    Set-DuoAdmin -AdminID "12345" -Name "John Doe" -Phone "555-1234" -Role "Owner"
    Updates the name, phone number, and role of the administrator with ID 12345.

.EXAMPLE
    Set-DuoAdmin -AdminID "12345" -ResetAuthAttempts
    Resets the authentication attempts for the administrator with ID 12345.

.EXAMPLE
    Set-DuoAdmin -AdminID "12345" -ClearExpiration
    Clears the inactivity expiration for the administrator with ID 12345.

.NOTES
    This function requires the New-DuoRequest function to create the API request and the Invoke-RestMethod cmdlet to send the request.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoAdmin -AdminID $_){$true}
            Else{Throw "Error: Invalid Admin ID"}
        })]
        [String]$AdminID,

        [Parameter(ParameterSetName="AdminFields",
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$Name,

        [Parameter(ParameterSetName="AdminFields",
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$Phone,

        [Parameter(ParameterSetName="AdminFields",
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$RequirePasswordChange,

        [Parameter(ParameterSetName="AdminFields",
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
        [ValidateSet("Owner", "Administrator", "Application Manager", "User Manager", "Security Analyst", "Help Desk", "Billing", "Phishing Manager","Read-only")]
        [String]$Role,

        [Parameter(ParameterSetName="AdminFields",
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$RestricedBy_AdminUnits,

        [Parameter(ParameterSetName="AdminFields",
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$Status,

        [Parameter(ParameterSetName="AdminFields",
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$TokenID,

        [Parameter(ParameterSetName="Reset",
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Switch]$ResetAuthAttempts,

        [Parameter(ParameterSetName="Clear",
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Switch]$ClearExpiration
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/admins/$($AdminID)"
    [Hashtable]$DuoParams = @{}

    If($Name){
        $DuoParams.Add("name",$Name)
    }
    If($Phone){
        $DuoParams.Add("phone",$Phone)
    }
    If($RequirePasswordChange){
        $DuoParams.Add("password_change_required",$RequirePasswordChange)
    }
    If($Role){
        $DuoParams.Add("role",$Role)
    }
    If($RestricedBy_AdminUnits){
        $DuoParams.Add("restricted_by_admin_units",$RestricedBy_AdminUnits)
    }
    If($Status){
        $DuoParams.Add("status",$Status)
    }
    If($TokenID){
        $DuoParams.Add("token_id",$TokenID)
    }
    If($ResetAuthAttempts){
        [String]$Uri = "/admin/v1/admins/$($AdminID)/reset"
    }
    ElseIf($ClearExpiration){
        [String]$Uri = "/admin/v1/admins/$($AdminID)/clear_inactivity"
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

Function Remove-DuoAdmin {
<#
.SYNOPSIS
    Removes a Duo administrator.

.DESCRIPTION
    The Remove-DuoAdmin function deletes a specified Duo administrator using their AdminID. 
    It sends a DELETE request to the Duo Admin API to perform this action.

.PARAMETER AdminID
    The ID of the administrator to be removed. This parameter is mandatory.

.EXAMPLE
    Remove-DuoAdmin -AdminID "12345"
    Deletes the administrator with ID 12345.

.NOTES
    This function requires the New-DuoRequest function to create the API request and the Invoke-RestMethod cmdlet to send the request.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>

    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoAdmin -AdminID $_){$true}
            Else{Throw "Error: Invalid Admin ID"}
        })]
        [String]$AdminID
    )

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/admins/$($AdminID)"
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

Function Send-DuoAdminActivationLink {
<#
.SYNOPSIS
    Sends an activation link email to a Duo administrator.

.DESCRIPTION
    The Send-DuoAdminActivationLink function sends an activation link email to a specified Duo administrator using their AdminID. 
    It sends a POST request to the Duo Admin API to perform this action.

.PARAMETER AdminID
    The ID of the administrator to whom the activation link email is to be sent. This parameter is mandatory.

.EXAMPLE
    Send-DuoAdminActivationLink -AdminID "12345"
    Sends an activation link email to the administrator with ID 12345.

.NOTES
    This function requires the New-DuoRequest function to create the API request and the Invoke-RestMethod cmdlet to send the request.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoAdmin -AdminID $_){$true}
            Else{Throw "Error: Invalid Admin ID"}
        })]
        [String]$AdminID
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/admins/$($AdminID)/activation_link/email"
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

Function Remove-DuoAdminActivationLink {
<#
.SYNOPSIS
    Removes an activation link for a Duo administrator.

.DESCRIPTION
    The Remove-DuoAdminActivationLink function deletes the activation link for a specified Duo administrator using their AdminID. 
    It sends a DELETE request to the Duo Admin API to perform this action.

.PARAMETER AdminID
    The ID of the administrator whose activation link is to be removed. This parameter is mandatory.

.EXAMPLE
    Remove-DuoAdminActivationLink -AdminID "12345"
    Deletes the activation link for the administrator with ID 12345.

.NOTES
    This function requires the New-DuoRequest function to create the API request and the Invoke-RestMethod cmdlet to send the request.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>

    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoAdmin -AdminID $_){$true}
            Else{Throw "Error: Invalid Admin ID"}
        })]
        [String]$AdminID
    )

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/admins/$($AdminID)"
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

Function New-DuoAdminActivationLink {
<#
.SYNOPSIS
    Creates a new activation link for a Duo administrator or retrieves an existing one.

.DESCRIPTION
    The New-DuoAdminActivationLink function either creates a new activation link for a Duo administrator or retrieves an existing one based on the provided parameters. 
    It supports two parameter sets: "Existing" for retrieving an existing activation link using an AdminID, and "New" for creating a new activation link using email, name, role, and other details.

.PARAMETER AdminID
    The ID of the existing administrator for whom the activation link is to be retrieved. Used in the "Existing" parameter set.

.PARAMETER Email
    The email address of the new administrator. Used in the "New" parameter set.

.PARAMETER Name
    The name of the new administrator. Optional in the "New" parameter set.

.PARAMETER Role
    The role of the new administrator. Used in the "New" parameter set.

.PARAMETER SendEmail
    A switch to indicate whether an email should be sent to the new administrator. Used in the "New" parameter set.

.PARAMETER Valid_Days
    The number of days the activation link should be valid. Used in the "New" parameter set.

.EXAMPLE
    New-DuoAdminActivationLink -AdminID "12345"
    Retrieves the activation link for the administrator with ID 12345.

.EXAMPLE
    New-DuoAdminActivationLink -Email "admin@example.com" -Name "John Doe" -Role "Owner" -SendEmail -Valid_Days 7
    Creates a new activation link for a new administrator with the specified details and sends an email.

.NOTES
    This function requires the New-DuoRequest function to create the API request and the Invoke-RestMethod cmdlet to send the request.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>

    PARAM(
        [Parameter(ParameterSetName="Existing",
            Mandatory = $true,
            ValueFromPipeLine = $true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoAdmin -AdminID $_){$true}
            Else{Throw "Error: Invalid Admin ID"}
        })]
        [String]$AdminID,

        [Parameter(ParameterSetName="New",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
        )]
        [String]$Email,

        [Parameter(ParameterSetName="New",
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=1
        )]
        [String]$Name,

        [Parameter(ParameterSetName="New",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
        )]
        [ValidateSet("Owner", "Administrator", "Application Manager", "User Manager", "Security Analyst", "Help Desk", "Billing", "Phishing Manager","Read-only")]
        [String]$Role,

        [Parameter(ParameterSetName="New",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
        )]
        [Switch]$SendEmail,

        [Parameter(ParameterSetName="New",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
        )]
        [Int]$Valid_Days
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/admins/activations"
    [Hashtable]$DuoParams = @{}

    If($AdminID){
        [String]$Uri = "/admin/v1/admins/$($AdminID)/activation_link"
    }
    Else{
        [String]$Uri = "/admin/v1/admins/activations"
        $DuoParams.Add("email",$Email)
        If($Name){
            $DuoParams.Add("admin_name",$Name)
        }
        If($Role){
            $DuoParams.Add("admin_role",$Role)
        }
        If($SendEmail){
            $DuoParams.Add("send_email",1)
        }
        Else{
            $DuoParams.Add("send_email",0)
        }
        If($Valid_Days){
            $DuoParams.Add("valid_days",$Valid_Days)
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

Function Get-DuoAdminActivationLink {
<#
.SYNOPSIS
    Retrieves activation links for Duo administrators.

.DESCRIPTION
    The Get-DuoAdminActivationLink function retrieves activation links for Duo administrators using the Duo Admin API. 
    It handles pagination to ensure all administrators are retrieved, even if there are more than 300.

.PARAMETER Method
    The HTTP method used for the API request. Default is "GET".

.PARAMETER Uri
    The URI path for the API request. Default is "/admin/v1/admins/activations".

.PARAMETER DuoParams
    A hashtable containing parameters for the API request. Initially empty but updated with the offset for pagination.

.PARAMETER Offset
    The offset used for pagination. Starts at 0 and increments by 300 until all administrators are retrieved.

.EXAMPLE
    Get-DuoAdminActivationLink
    Retrieves and displays activation links for all Duo administrators.

.NOTES
    This function requires the New-DuoRequest function to create the API request and the Invoke-RestMethod cmdlet to send the request.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/admins/activations"
    [Hashtable]$DuoParams = @{}

    
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

Function Remove-DuoPendingActivation {
<#
.SYNOPSIS
    Removes a pending activation for a Duo administrator.

.DESCRIPTION
    This function removes a specified pending activation for a Duo administrator by ActivationID.

.PARAMETER ActivationID
    The ID of the pending activation to be removed. This parameter is mandatory.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>

    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$ActivationID
    )

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/admins/activations/$($ActivationID)"
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

Function Sync-DuoAdmin {
<#
.SYNOPSIS
    Synchronizes a Duo administrator with a directory.

.DESCRIPTION
    This function synchronizes a Duo administrator with a specified directory using either the directory name or directory key. It requires the administrator's email for synchronization.

.PARAMETER DirectoryName
    The name of the directory to synchronize with. This parameter is mandatory when using the Name parameter set.

.PARAMETER DirectoryKey
    The key of the directory to synchronize with. This parameter is mandatory when using the Key parameter set.

.PARAMETER Email
    The email of the Duo administrator to be synchronized. This parameter is mandatory.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    PARAM(
        [Parameter(ParameterSetName="Name",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$DirectoryName,
        [Parameter(ParameterSetName="Key",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$DirectoryKey,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=1
            )]
            [String]$Email
    )
    
    If($DirectoryName){
        $DirectoryKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR((Get-DuoDirectoryKey -DirectoryName $DirectoryName)))
    }

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/admins/directorysync/$($DirectoryKey)/syncadmin"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("email",$Email)

    
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

Function Get-DuoAdminExternalPwManagement {
<#
.SYNOPSIS
    Retrieves external password management settings for Duo administrators.

.DESCRIPTION
    This function retrieves the external password management settings for Duo administrators. It can fetch settings for a specific administrator by AdminID or return all settings if no ID is specified.

.PARAMETER AdminID
    The ID of the Duo administrator. This parameter is optional.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    PARAM(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoAdmin -AdminID $_){$true}
            Else{Throw "Error: Invalid Admin ID"}
        })]
        [String]$AdminID
    )

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/admins/password_mgmt"
    [Hashtable]$DuoParams = @{}

    If($AdminID){    
        $Uri = "/admin/v1/admins/$($AdminID)/password_mgmt"
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

Function Set-DuoAdminExternalPwManagement {
<#
.SYNOPSIS
    Configures external password management for a Duo administrator.

.DESCRIPTION
    This function sets up external password management for a specified Duo administrator by AdminID. It requires the administrator's password and a flag indicating whether external password management is enabled.

.PARAMETER AdminID
    The ID of the Duo administrator. This parameter is mandatory.

.PARAMETER Password
    The password for the Duo administrator. This parameter is mandatory.

.PARAMETER ExternalPassword_Mgmt
    A boolean flag indicating whether external password management is enabled. This parameter is mandatory.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoAdmin -AdminID $_){$true}
            Else{Throw "Error: Invalid Admin ID"}
        })]
        [String]$AdminID,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=1
        )]
        [String]$Password,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=1
        )]
        [Bool]$ExternalPassword_Mgmt
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/admins/$($AdminID)/password_mgmt"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("has_external_password_mgmt",$true)
    $DuoParams.Add("password",$Password)

    
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

Function Get-DuoAuthFactors {
<#
.SYNOPSIS
    Retrieves the allowed authentication factors for Duo administrators.

.DESCRIPTION
    This function retrieves the current configuration of allowed authentication factors for Duo administrators.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/admins/allowed_auth_methods"
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

Function Set-DuoAuthFactors {
<#
.SYNOPSIS
    Configures the allowed authentication factors for Duo administrators.

.DESCRIPTION
    This function sets the allowed authentication factors for Duo administrators. It allows enabling or disabling various authentication methods such as hardware tokens, mobile OTP, push notifications, SMS, voice, WebAuthN, and YubiKey.

.PARAMETER HardwareToken
    Enables or disables hardware token authentication. This parameter is optional.

.PARAMETER MobileOTP
    Enables or disables mobile OTP authentication. This parameter is optional.

.PARAMETER Push
    Enables or disables push notification authentication. This parameter is optional.

.PARAMETER SMS
    Enables or disables SMS authentication. This parameter is optional.

.PARAMETER Voice
    Enables or disables voice call authentication. This parameter is optional.

.PARAMETER WebAuthN
    Enables or disables WebAuthN authentication. This parameter is optional.

.PARAMETER YubiKey
    Enables or disables YubiKey authentication. This parameter is optional.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    PARAM(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$HardwareToken,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$MobileOTP,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$Push,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$SMS,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$Voice,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$WebAuthN,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$YubiKey
    )
    If($HardwareToken -or $MobileOTP -or $Push -or $SMS -or $Voice -or $WebAuthN -or $YubiKey){

    }
    Else{
        #Write-Host "You must include at least one option." -ForegroundColor Red -BackgroundColor Black
    }

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/admins/allowed_auth_methods"
    [Hashtable]$DuoParams = @{}

    If($HardwareToken){
        $DuoParams.Add("hardware_token_enabled",$HardwareToken)
    }
    If($MobileOTP){
        $DuoParams.Add("mobile_opt_enabled",$MobileOTP)
    }
    If($Push){
        $DuoParams.Add("push_enabled",$Push)
    }
    If($SMS){
        $DuoParams.Add("sms_enabled",$SMS)
    }
    If($Voice){
        $DuoParams.Add("voice_enabled",$Voice)
    }
    If($WebAuthN){
        $DuoParams.Add("webauthn_enabled",$WebAuthN)
    }
    If($YubiKey){
        $DuoParams.Add("yubikey_enabled",$YubiKey)
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