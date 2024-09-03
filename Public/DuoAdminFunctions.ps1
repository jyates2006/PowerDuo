Function Get-DuoAdminUnit {
<#
.SYNOPSIS
    Retrieves administrative unit details from Duo.

.DESCRIPTION
    This function sends a GET request to the Duo Admin API to retrieve details of administrative units. 
    It supports filtering by AdminUnitID, AdminID, GroupID, or IntegrationKey.

.PARAMETER AdminUnitID
    The ID of the administrative unit to retrieve details for.

.PARAMETER AdminID
    The ID of the admin to filter the administrative units.

.PARAMETER GroupID
    The ID of the group to filter the administrative units.

.PARAMETER IntegrationKey
    The integration key to filter the administrative units.

.EXAMPLE
    PS C:\> Get-DuoAdminUnit -AdminUnitID "123456"

.EXAMPLE
    PS C:\> Get-DuoAdminUnit -AdminID "admin123"

.EXAMPLE
    PS C:\> Get-DuoAdminUnit -GroupID "group123"

.EXAMPLE
    PS C:\> Get-DuoAdminUnit -IntegrationKey "ikey123"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>
    PARAM(
        [Parameter(ParameterSetName="AUDetails",
            Mandatory = $false,
            ValueFromPipeLine = $true
            )]
            [String]$AdminUnitID,
        [Parameter(ParameterSetName="AID",
            Mandatory = $false,
            ValueFromPipeLine = $true
            )]
            [String]$AdminID,
        [Parameter(ParameterSetName="GID",
            Mandatory = $false,
            ValueFromPipeLine = $true
            )]
            [String]$GroupID,
        [Parameter(ParameterSetName="iKey",
            Mandatory = $false,
            ValueFromPipeLine = $true
            )]
            [String]$IntegrationKey
    )    

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/administrative_units"
    [Hashtable]$DuoParams = @{}

    If($AdminUnitID){
        [String]$Uri = "/admin/v1/adminstrative_units/$($AdminUnitID)"
    }
    ElseIf($AdminID){
        $DuoParams.Add("admni_id",$AdminID)
    }
    ElseIf($GroupID){
        $DuoParams.Add("GroupID",$GroupID)
    }
    ElseIf($IntegrationKey){
        $DuoParams.Add("integration_key",$IntegrationKey)
    }

    $DuoParams.Add("limit","300")
    $DuoParams.Add("offset","0")
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

Function New-DuoAdminUnit {
<#
.SYNOPSIS
    Creates a new administrative unit in Duo.

.DESCRIPTION
    This function sends a POST request to the Duo Admin API to create a new administrative unit. 
    It allows you to specify various parameters such as name, description, and restrictions by groups or integrations.

.PARAMETER Name
    The name of the administrative unit.

.PARAMETER Description
    The description of the administrative unit.

.PARAMETER RestrictByGroups
    Boolean to indicate whether the administrative unit is restricted by groups.

.PARAMETER RestrictByIntegrations
    Boolean to indicate whether the administrative unit is restricted by integrations.

.PARAMETER AdminIDs
    A comma-separated list of admin IDs to be associated with the administrative unit.

.PARAMETER GroupIDs
    A comma-separated list of group IDs to be associated with the administrative unit.

.PARAMETER IntegrationKeys
    A comma-separated list of integration keys to be associated with the administrative unit.

.EXAMPLE
    PS C:\> New-DuoAdminUnit -Name "Finance" -Description "Finance Department" -RestrictByGroups $true -AdminIDs "admin1,admin2"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>

    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true,
            Position=0
            )]
            [String]$Name,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true,
            Position=1
            )]
            [String]$Description,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true,
            Position=2
            )]
            [Bool]$RestrictByGroups,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=3
            )]
            [Bool]$RestrictByIntegrations,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=4
            )]
            [String]$AdminIDs,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=5
            )]
            [String]$GroupIDs,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=6
            )]
            [String]$IntegrationKeys
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/administrative_units"
    [Hashtable]$DuoParams = @{}

    $DuoParams.Add("name",$Name)
    $DuoParams.Add("description",$Description)
    $DuoParams.Add("restrict_by_groups",$RestrictByGroups)
    If($RestrictByIntegrations){
        $DuoParams.Add("restrict_by_integrations",$RestrictByIntegrations)
    }
    If($AdminIDs){
        $DuoParams.Add("admins",$AdminIDs)
    }
    If($IntegrationKeys){
        $DuoParams.Add("integrations",$IntegrationKeys)
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

Function Set-DuoAdminUnit {
<#
.SYNOPSIS
    Sets or updates an administrative unit in Duo.

.DESCRIPTION
    This function sends a POST request to the Duo Admin API to set or update an administrative unit. 
    It allows you to specify various parameters such as name, description, and restrictions by groups or integrations.

.PARAMETER AdminUnitID
    The ID of the administrative unit to be set or updated.

.PARAMETER Name
    The name of the administrative unit.

.PARAMETER Description
    The description of the administrative unit.

.PARAMETER RestrictByGroups
    Boolean to indicate whether the administrative unit is restricted by groups.

.PARAMETER RestrictByIntegrations
    Boolean to indicate whether the administrative unit is restricted by integrations.

.PARAMETER AdminIDs
    A comma-separated list of admin IDs to be associated with the administrative unit.

.PARAMETER GroupIDs
    A comma-separated list of group IDs to be associated with the administrative unit.

.PARAMETER IntegrationKeys
    A comma-separated list of integration keys to be associated with the administrative unit.

.EXAMPLE
    PS C:\> Set-DuoAdminUnit -AdminUnitID "123456" -Name "Finance" -Description "Finance Department" -RestrictByGroups $true -AdminIDs "admin1,admin2"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true,
            Position=0
            )]
            [String]$AdminUnitID,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=1
            )]
            [String]$Name,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=2
            )]
            [String]$Description,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=3
            )]
            [Bool]$RestrictByGroups,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=4
            )]
            [Bool]$RestrictByIntegrations,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=4
            )]
            [String]$AdminIDs,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=5
            )]
            [String]$GroupIDs,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=6
            )]
            [String]$IntegrationKeys
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/administrative_units/$($AdminUnitID)"
    [Hashtable]$DuoParams = @{}

    $DuoParams.Add("name",$Name)
    $DuoParams.Add("description",$Description)
    $DuoParams.Add("restrict_by_groups",$RestrictByGroups)
    If($RestrictByIntegrations){
        $DuoParams.Add("restrict_by_integrations",$RestrictByIntegrations)
    }
    If($AdminIDs){
        $DuoParams.Add("admins",$AdminIDs)
    }
    If($IntegrationKeys){
        $DuoParams.Add("integrations",$IntegrationKeys)
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

Function Add-DuoAdminUnitMember {
<#
.SYNOPSIS
    Adds a member to an administrative unit in Duo.

.DESCRIPTION
    This function sends a POST request to the Duo Admin API to add a member to an administrative unit. 
    The member can be specified by AdminID, GroupID, or IntegrationKey.

.PARAMETER AdminUnitID
    The ID of the administrative unit to which the member will be added.

.PARAMETER AdminID
    The ID of the admin to be added to the administrative unit.

.PARAMETER GroupID
    The ID of the group to be added to the administrative unit.

.PARAMETER IntegrationKey
    The integration key of the integration to be added to the administrative unit.

.EXAMPLE
    PS C:\> Add-DuoAdminUnitMember -AdminUnitID "123456" -AdminID "admin123"

.EXAMPLE
    PS C:\> Add-DuoAdminUnitMember -AdminUnitID "123456" -GroupID "group123"

.EXAMPLE
    PS C:\> Add-DuoAdminUnitMember -AdminUnitID "123456" -IntegrationKey "ikey123"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true
        )]
        [String]$AdminUnitID,

        [Parameter(ParameterSetName="AID",
            Mandatory = $true,
            ValueFromPipeLine = $false
        )]
        [String]$AdminID,

        [Parameter(ParameterSetName="GID",
            Mandatory = $true,
            ValueFromPipeLine = $false
        )]
        [String]$GroupID,

        [Parameter(ParameterSetName="IKey",
            Mandatory = $true,
            ValueFromPipeLine = $false
        )]
        [String]$IntegrationKey
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/administrative_units/$($AdminUnitID)"
    [Hashtable]$DuoParams = @{}

    If($AdminID){
        [String]$Uri = "/admin/v1/administrative_units/$($AdminUnitID)/admin/$($AdminID)"
    }
    ElseIf($GroupID){
        [String]$Uri = "/admin/v1/administrative_units/$($AdminUnitID)/group/$($GroupID)"
    }
    ElseIf($IntegrationKey){
        [String]$Uri = "/admin/v1/administrative_units/$($AdminUnitID)/integration/$($IntegrationKey)"
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

Function Remove-DuoAdminUnitMember {
<#
.SYNOPSIS
    Removes a member from an administrative unit in Duo.

.DESCRIPTION
    This function sends a DELETE request to the Duo Admin API to remove a member from an administrative unit. 
    The member can be specified by AdminID, GroupID, or IntegrationKey.

.PARAMETER AdminUnitID
    The ID of the administrative unit from which the member will be removed.

.PARAMETER AdminID
    The ID of the admin to be removed from the administrative unit.

.PARAMETER GroupID
    The ID of the group to be removed from the administrative unit.

.PARAMETER IntegrationKey
    The integration key of the integration to be removed from the administrative unit.

.EXAMPLE
    PS C:\> Remove-DuoAdminUnitMember -AdminUnitID "123456" -AdminID "admin123"

.EXAMPLE
    PS C:\> Remove-DuoAdminUnitMember -AdminUnitID "123456" -GroupID "group123"

.EXAMPLE
    PS C:\> Remove-DuoAdminUnitMember -AdminUnitID "123456" -IntegrationKey "ikey123"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true
        )]
        [String]$AdminUnitID,

        [Parameter(ParameterSetName="AID",
            Mandatory = $true,
            ValueFromPipeLine = $false
        )]
        [String]$AdminID,

        [Parameter(ParameterSetName="GID",
            Mandatory = $true,
            ValueFromPipeLine = $false
        )]
        [String]$GroupID,

        [Parameter(ParameterSetName="IKey",
            Mandatory = $true,
            ValueFromPipeLine = $false
        )]
        [String]$IntegrationKey
    )

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/administrative_units/$($AdminUnitID)"
    [Hashtable]$DuoParams = @{}

    If($AdminID){
        [String]$Uri = "/admin/v1/administrative_units/$($AdminUnitID)/admin/$($AdminID)"
    }
    ElseIf($GroupID){
        [String]$Uri = "/admin/v1/administrative_units/$($AdminUnitID)/group/$($GroupID)"
    }
    ElseIf($IntegrationKey){
        [String]$Uri = "/admin/v1/administrative_units/$($AdminUnitID)/integration/$($IntegrationKey)"
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

Function Remove-DuoAdminUnit {
<#
.SYNOPSIS
    Removes an administrative unit from Duo.

.DESCRIPTION
    This function sends a DELETE request to the Duo Admin API to remove an administrative unit specified by its ID.

.PARAMETER AdminUnitID
    The ID of the administrative unit to be removed.

.EXAMPLE
    PS C:\> Remove-DuoAdminUnit -AdminUnitID "123456"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true
        )]
        [String]$AdminUnitID
    )

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/administrative_units/$($AdminUnitID)"
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

Function Get-DuoLog {
<#
.SYNOPSIS
    Retrieves logs from Duo based on the specified log type.

.DESCRIPTION
    This function sends a GET request to the Duo Admin API to retrieve logs of a specified type. 
    It supports filtering logs based on a Unix timestamp.

.PARAMETER Log
    The type of log to retrieve. Valid values are "Authentication", "Administrator", "Telephony", and "OfflineEnrollment".

.PARAMETER Since
    The Unix timestamp to filter logs from.

.EXAMPLE
    PS C:\> Get-DuoLog -Log "Authentication"

.EXAMPLE
    PS C:\> Get-DuoLog -Log "Administrator" -Since 1622505600

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false
        )]
        
        [String]$Log,

        [Parameter(ParameterSetName="Unix",
            Mandatory = $false,
            ValueFromPipeLine = $True
        )]
        [INT]$Since
    )

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/logs"
    [Hashtable]$DuoParams = @{}

    Switch($Log){
        "Authentication" {
            [String]$Uri = "/admin/v1/logs/authentication"
        }
        "Administrator" {
            [String]$Uri = "/admin/v1/logs/administrator"
        }
        "Telephony" {
            [String]$Uri = "/admin/v1/logs/telephony"
        }
        "OfflineEnrollment" {
            [String]$Uri = "/admin/v1/logs/offline_enrollment"
        }
    }

    If($Since){
        $DuoParams.Add("mintime",$Since)
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

Function Get-DuoTrustMonitor {
<#
.SYNOPSIS
    Retrieves trust monitor events from Duo within a specified time range.

.DESCRIPTION
    This function sends a GET request to the Duo Admin API to retrieve trust monitor events within the specified Unix time range. 
    It supports pagination to handle the API's limit of 200 events per request.

.PARAMETER MinTime
    The minimum Unix time for the events to be retrieved.

.PARAMETER MaxTime
    The maximum Unix time for the events to be retrieved.

.PARAMETER Type
    The type of events to be retrieved (optional).

.EXAMPLE
    PS C:\> Get-DuoTrustMonitor -MinTime 1622505600 -MaxTime 1625097600

.EXAMPLE
    PS C:\> Get-DuoTrustMonitor -MinTime 1622505600 -MaxTime 1625097600 -Type "login"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>
    PARAM(
        [Parameter(ParameterSetName="Unix",
            Mandatory = $true,
            ValueFromPipeLine = $false
        )]
        [INT]$MinTime,

        [Parameter(ParameterSetName="Unix",
            Mandatory = $true,
            ValueFromPipeLine = $false
        )]
        [INT]$MaxTime,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$Type
    )

    $Offset = 0

    #Duo has a 200 Trust Monitor limit in their api. Loop to return all events
    Do{
        #Base claim
        [String]$Method = "GET"
        [String]$Uri = "/admin/v1/trust_monitor/events"
        [Hashtable]$DuoParams = @{}
        $DuoParams.Offset = $Offset

        $DuoParams.Add("mintime",$MinTime)
        $DuoParams.Add("maxtime",$MaxTime)
        If($Type){
            $DuoParams.Add("type",$Type)
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
            #Increment offset to return the next 300 users
            $Offset += 200
        }
    }Until($Output.Count -lt 300)
}

Function Get-DuoSetting {
<#
.SYNOPSIS
    Retrieves the current settings from Duo.

.DESCRIPTION
    This function sends a GET request to the Duo Admin API to retrieve the current settings.

.EXAMPLE
    PS C:\> Get-DuoSetting

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>
    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/settings"
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

Function Set-DuoSetting {
<#
.SYNOPSIS
    Sets various settings for Duo using the Admin API.

.DESCRIPTION
    This function sends a POST request to the Duo Admin API to set various settings such as Caller ID, Mobile OTP type, email notifications, and more.

.PARAMETER CallerID
    The caller ID to be used.

.PARAMETER MobileOTP_Type
    The type of mobile OTP to be used.

.PARAMETER EmailActivityNotification
    Boolean to enable or disable email activity notifications.

.PARAMETER Enrollment_UniverseralPrompt
    Boolean to enable or disable the universal prompt for enrollment.

.PARAMETER FraudEmail
    The email address to be used for fraud notifications.

.PARAMETER EnableFraudEmail
    Boolean to enable or disable fraud email notifications.

.PARAMETER EnforceGlobalSS_Policy
    Boolean to enforce the global self-service policy.

.PARAMETER HelpDesk_Bypass
    The help desk bypass setting.

.PARAMETER BypassExpiration
    The expiration time for help desk bypass.

.PARAMETER AllowHelpDesk_SendEnrollment
    Boolean to allow help desk to send enrollment emails.

.PARAMETER Inactive_Expiration
    The expiration time for inactive users.

.PARAMETER KeyPressConfirm
    The key press for confirmation.

.PARAMETER KeyPressFraud
    The key press for fraud reporting.

.PARAMETER Language
    The language setting.

.PARAMETER LockDuration
    The duration for lockout expiration.

.PARAMETER LockoutThreshold
    The threshold for lockout.

.PARAMETER LogRetention
    The number of days to retain logs.

.PARAMETER MinPasswordLength
    The minimum password length.

.PARAMETER EnableMobleOTP
    Boolean to enable or disable mobile OTP.

.PARAMETER Name
    The name setting.

.PARAMETER PassRequiresLowerAlpha
    Boolean to require lowercase alphabet in passwords.

.PARAMETER PassRequiresNumeric
    Boolean to require numeric characters in passwords.

.PARAMETER PassRequiresSpecial
    Boolean to require special characters in passwords.

.PARAMETER PassRequiresUpperAlpha
    Boolean to require uppercase alphabet in passwords.

.PARAMETER EnableActivityNofication
    Boolean to enable or disable activity notifications.

.PARAMETER SMS_BatchSize
    The batch size for SMS.

.PARAMETER SMS_Expiration
    The expiration time for SMS.

.PARAMETER SMS_Message
    The SMS message content.

.PARAMETER SMS_Refresh
    The refresh interval for SMS.

.PARAMETER Telephony_Warning
    The warning threshold for telephony.

.PARAMETER Timezone
    The timezone setting.

.PARAMETER EnableU2F
    Boolean to enable or disable U2F.

.PARAMETER Unenrolled_LockoutThreshold
    The lockout threshold for unenrolled users.

.PARAMETER Allow_UserManagersBypass
    The setting to allow user managers to bypass.

.PARAMETER MaxTelephonyCredit
    The maximum telephony credit.

.PARAMETER EnableVoice
    Boolean to enable or disable voice.

.EXAMPLE
    PS C:\> Set-DuoSetting -CallerID "1234567890" -EmailActivityNotification $true -Language "en"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>
    PARAM(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$CallerID,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$MobileOTP_Type,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$EmailActivityNotification,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$Enrollment_UniverseralPrompt,
        
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$FraudEmail,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$EnableFraudEmail,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$EnforceGlobalSS_Policy,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$HelpDesk_Bypass,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$BypassExpiration,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$AllowHelpDesk_SendEnrollment,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Int]$Inactive_Expiration,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$KeyPressConfirm,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$KeyPressFraud,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$Language,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Int]$LockDuration,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Int]$LockoutThreshold,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Int]$LogRetention,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$MinPasswordLength,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$EnableMobleOTP,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$Name,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$PassRequiresLowerAlpha,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$PassRequiresNumeric,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$PassRequiresSpecial,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$PassRequiresUpperAlpha,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$EnableActivityNofication,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Int]$SMS_BatchSize,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Int]$SMS_Expiration,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$SMS_Message,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Int]$SMS_Refresh,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Int]$Telephony_Warning,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$Timezone,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$EnableU2F,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Int]$Unenrolled_LockoutThreshold,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$Allow_UserManagersBypass,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Int]$MaxTelephonyCredit,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$EnableVoice
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/settings"
    [Hashtable]$DuoParams = @{}

    If($CallerID){
        $DuoParams.Add("caller_id",$CallerID)
    }
    If($MobileOTP_Type){
        $DuoParams.Add("duo_mobile_otp_type",$MobileOTP_Type)
    }
    If($EnableMobleOTP){
        $DuoParams.Add("mobile_otp_enabled",$EnableMobleOTP)
    }
    If($EmailActivityNotification){
        $DuoParams.Add("email_activity_notification_enabled",$EmailActivityNotification)
    }
    If($Enrollment_UniverseralPrompt){
        $DuoParams.Add("enrollment_universal_prompt_enabled",$Enrollment_UniverseralPrompt)
    }
    If($FraudEmail){
        $DuoParams.Add("fraud_email",$FraudEmail)
    }
    If($EnableFraudEmail){
        $DuoParams.Add("fraud_email_enabled",$EnableFraudEmail)
    }
    If($EnforceGlobalSS_Policy){
        $DuoParams.Add("global_ssp_policy_enforced",$EnforceGlobalSS_Policy)
    }
    If($HelpDesk_Bypass){
        $DuoParams.Add("helpdesk_bypass",$HelpDesk_Bypass)
    }
    If($BypassExpiration){
        $DuoParams.Add("helpdesk_bypass_expiration",$BypassExpiration)
    }
    If($AllowHelpDesk_SendEnrollment){
        $DuoParams.Add("helpdesk_can_send_enroll_email",$AllowHelpDesk_SendEnrollment)
    }
    If($Inactive_Expiration){
        $DuoParams.Add("inactive_user_expiration",$Inactive_Expiration)
    }
    If($KeyPressConfirm){
        $DuoParams.Add("keypress_confirm",$KeyPressConfirm)
    }
    If($KeyPressFraud){
        $DuoParams.Add("keypress_fraud",$KeyPressFraud)
    }
    If($Language){
        $DuoParams.Add("language",$Language)
    }
    If($LockDuration){
        $DuoParams.Add("lockout_expire_duration",$LockDuration)
    }
    If($LockoutThreshold){
        $DuoParams.Add("lockout_threshold",$LockoutThreshold)
    }
    If($LogRetention){
        $DuoParams.Add("log_retention_days",$LogRetention)
    }
    If($MinPasswordLength){
        $DuoParams.Add("minimum_password_length",$MinPasswordLength)
    }
    If($Name){
        $DuoParams.Add("name",$Name)
    }
    If($PassRequiresLowerAlpha){
        $DuoParams.Add("password_requires_lower_alpha",$PassRequiresLowerAlpha)
    }
    If($PassRequiresNumeric){
        $DuoParams.Add("password_requires_numeric",$PassRequiresNumeric)
    }
    If($PassRequiresSpecial){
        $DuoParams.Add("password_requires_special",$PassRequiresSpecial)
    }
    If($EnableActivityNofication){
        $DuoParams.Add("push_activity_notification_enabled",$EnableActivityNofication)
    }
    If($SMS_BatchSize){
        $DuoParams.Add("sms_batch",$SMS_BatchSize)
    }
    If($SMS_Expiration){
        $DuoParams.Add("sms_expiration",$SMS_Expiration)
    }
    If($SMS_Message){
        $DuoParams.Add("sms_message",$SMS_Message)
    }
    If($SMS_Refresh){
        $DuoParams.Add("sms_refresh",$SMS_Refresh)
    }
    If($Telephony_Warning){
        $DuoParams.Add("telephony_warning_min",$Telephony_Warning)
    }
    If($Timezone){
        $DuoParams.Add("timezone",$Timezone)
    }
    If($Unenrolled_LockoutThreshold){
        $DuoParams.Add("unenrolled_user_lockout_threshold",$Unenrolled_LockoutThreshold)
    }
    If($Allow_UserManagersBypass){
        $DuoParams.Add("user_managers_can_put_users_in_bypass",$Allow_UserManagersBypass)
    }
    If($MaxTelephonyCredit){
        $DuoParams.Add("user_telephony_cost_max",$MaxTelephonyCredit)
    }
    If($EnableVoice){
        $DuoParams.Add("voice_enabled",$EnableVoice)
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

Function Get-DuoLogo {
<#
.SYNOPSIS
    Retrieves the current logo from Duo branding settings.

.DESCRIPTION
    This function sends a GET request to the Duo Admin API to retrieve the current logo used in the branding settings.

.EXAMPLE
    PS C:\> Get-DuoLogo

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>
    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/logo"
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

Function Set-DuoLogo {
<#
.SYNOPSIS
    Sets the logo for Duo branding settings.

.DESCRIPTION
    This function sends a POST request to the Duo Admin API to set the logo for the branding settings. 
    The logo image is converted to a Base64 string before being sent.

.PARAMETER ImagePath
    The path to the image file that will be used as the logo.

.EXAMPLE
    PS C:\> Set-DuoLogo -ImagePath "C:\Images\logo.png"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true
        )]
        [String]$ImagePath
    )

    $Logo = (Get-Base64Image -ImagePath $ImagePath).Base64String

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/logo"
    [Hashtable]$DuoParams = @{}

    $DuoParams.Add("logo",$Logo)

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

Function Remove-DuoLogo {
<#
.SYNOPSIS
    Removes the logo from Duo branding settings.

.DESCRIPTION
    This function sends a DELETE request to the Duo Admin API to remove the logo from the branding settings.

.EXAMPLE
    PS C:\> Remove-DuoLogo

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>
    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/logo"
    [Hashtable]$DuoParams = @{}

    $DuoParams.Add("logo",$Logo)

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

Function Get-DuoBranding {
<#
.SYNOPSIS
    Retrieves branding settings from Duo, including live and draft settings.

.DESCRIPTION
    This function sends a GET request to the Duo Admin API to retrieve the current branding settings. 
    You can specify whether to retrieve the settings for the live or draft environment.

.PARAMETER Live
    Switch to indicate that the branding settings are for the live environment.

.PARAMETER Draft
    Switch to indicate that the branding settings are for the draft environment.

.EXAMPLE
    PS C:\> Get-DuoBranding -Live

.EXAMPLE
    PS C:\> Get-DuoBranding -Draft

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>
    PARAM(
        [Parameter(ParameterSetName="Live",
            Mandatory = $true,
            ValueFromPipeLine = $true
        )]
        [Switch]$Live,
        
        [Parameter(ParameterSetName="Draft",
            Mandatory = $true,
            ValueFromPipeLine = $true
        )]
        [Switch]$Draft
    )
    
    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/"
    [Hashtable]$DuoParams = @{}

    If($Live){
        [String]$Uri = "/admin/v1/branding"
    }
    ElseIf($Draft){
        [String]$Uri = "/admin/v1/branding/draft"
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

Function Set-DuoBranding {
<#
.SYNOPSIS
    Sets branding options for Duo, including live and draft settings.

.DESCRIPTION
    This function allows you to set various branding options for Duo, such as background images, colors, logos, and custom labels. 
    You can specify whether the settings are for live or draft environments.

.PARAMETER Live
    Switch to indicate that the branding settings are for the live environment.

.PARAMETER Draft
    Switch to indicate that the branding settings are for the draft environment.

.PARAMETER background_img
    Path to the background image file to be used.

.PARAMETER CardAccentColor
    Hex color code for the card accent color.

.PARAMETER Logo
    Path to the logo image file to be used.

.PARAMETER BackgroundColor
    Hex color code for the page background color.

.PARAMETER PowerdByDuo
    Boolean to indicate whether to display "Powered by Duo".

.PARAMETER UsernameLabel
    Custom label for the username field.

.PARAMETER UserID
    User ID for the draft environment.

.PARAMETER Publish
    Switch to indicate that the draft settings should be published.

.EXAMPLE
    PS C:\> Set-DuoBranding -Live -background_img "C:\Images\background.png" -CardAccentColor "#FF5733" -Logo "C:\Images\logo.png" -BackgroundColor "#FFFFFF" -PowerdByDuo $true -UsernameLabel "User ID"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>
    PARAM(
        [Parameter(ParameterSetName="Live",
            Mandatory = $true,
            ValueFromPipeLine = $true
        )]
        [Switch]$Live,
        
        [Parameter(ParameterSetName="Draft",
            Mandatory = $true,
            ValueFromPipeLine = $true
        )]
        [Switch]$Draft,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$Background_Img,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$CardAccentColor,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$Logo,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$BackgroundColor,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$PowerdByDuo,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$UsernameLabel,

        [Parameter(ParameterSetName="Draft",
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$UserID,

        [Parameter(ParameterSetName="Draft",
            Mandatory = $true,
            ValueFromPipeLine = $true
        )]
        [Switch]$Publish
    )
    
    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/"
    [Hashtable]$DuoParams = @{}

    If($Live){
        [String]$Uri = "/admin/v1/branding"
    }
    ElseIf($Draft){
        [String]$Uri = "/admin/v1/branding/draft"
    }
    If($background_img){
        $BkgImg = (Get-Base64Image -ImagePath $background_img).Base64String
        $DuoParams.Add("background_img",$BkgImg)
    }
    If($CardAccentColor){
        $DuoParams.Add("card_accent_color",$CardAccentColor)
    }
    If($Logo){
        $LogoImg = (Get-Base64Image -ImagePath $Logo).Base64String
        $DuoParams.Add("logo",$LogoImg)
    }
    If($BackgroundColor){
        $DuoParams.Add("page_background_color",$BackgroundColor)
    }
    If($PowerdByDuo){
        $DuoParams.Add("powered_by_duo",$PowerdByDuo)
    }
    If($UsernameLabel){
        $DuoParams.Add("sso_custom_username_label",$UsernameLabel)
    }
    If($UserID){
        $DuoParams.Add("user_ids",$UserID)
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

Function Add-DuoDraftMember {
<#
.SYNOPSIS
    Adds a user to the Duo draft members list.

.DESCRIPTION
    This function sends a POST request to the Duo Admin API to add a user to the draft members list based on the provided UserID.

.PARAMETER UserID
    The ID of the user to be added to the draft members list.

.EXAMPLE
    PS C:\> Add-DuoDraftMember -UserID "123456"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>
    PARAM(
        [String]$UserID
    )
    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/branding/draft/users/$($UserID)"
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

Function Remove-DuoDraftMember {
<#
.SYNOPSIS
    Retrieves custom messaging settings from the Duo Admin API.

.DESCRIPTION
    This function sends a GET request to the Duo Admin API to retrieve the current custom messaging settings.

.EXAMPLE
    PS C:\> Get-DuoCustomMessaging

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>

    PARAM(
        [String]$UserID
    )
    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/branding/draft/users/$($UserID)"
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

Function Get-DuoCustomMessaging {
    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/branding/custom_messaging"
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

Function Set-DuoCustomMessaging {
<#
.SYNOPSIS
    Sets custom messaging for Duo Admin API.

.DESCRIPTION
    This script allows you to set custom messaging for Duo using the Admin API. 
    You can specify help links, help text, and locale.

.PARAMETER HelpLinks
    A string containing the help links to be added.

.PARAMETER HelpText
    A string containing the help text to be added.

.PARAMETER locale
    A string specifying the locale for the help text.

.EXAMPLE
    PS C:\> Set-DuoCustomMessaging -HelpLinks "http://example.com/help" -HelpText "Contact support for assistance." -locale "en"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Ensure you have the necessary permissions and API keys to interact with the Duo Admin API.
#>
    PARAM(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [String]$HelpLinks,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [String]$HelpText,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [String]$locale
    )
       
    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/branding/custom_messaging"
    [Hashtable]$DuoParams = @{}

    If($HelpLinks){
        $DuoParams.Add("help_links",$HelpLinks)
    }
    If($HelpText){
        $DuoParams.Add("help_text",$HelpText)
        $DuoParams.Add("locale",$locale)
    }
    ElseIf($locale){
        $DuoParams.Add("locale",$locale)
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

Function Get-DuoAccount {
<#
.SYNOPSIS
    Get the information on your organization's Duo account

.DESCRIPTION
    Return organization's Duo account information

.OUTPUTS
    [PSCustomObject]DuoRequest

.EXAMPLE
    Get-DuoAccount

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/info/summary"
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

Function Get-DuoReport {
<#
.SYNOPSIS
    Get Duo reports

.DESCRIPTION
    Return Duo report

.PARAMETER Report
	Required, Specify the report type

.PARAMETER MinTime
	Epoch time stamp, Start of the time frame to return

.PARAMETER MaxTime
	Epoch time stamp, End of the time frame to return

.PARAMETER CreditsUsed
	Integer, report only list logs that used this amount of credits or more

.OUTPUTS
    [PSCustomObject]DuoRequest

.EXAMPLE
    Get-DuoReport -Report AuthenticationAttempts -MinTime 1724170019 -MaxTime 1725034008

.EXAMPLE
    Get-DuoReport -Report TelephonyCredits -CreditsUsed 2

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    PARAM(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateSet("TelephonyCredits","AuthenticationAttempts","UsersWithAuthAttempts")]
        [String]$Report,

        [Parameter(ParameterSetName="Epoch",
            Mandatory=$false,
            ValueFromPipeline=$false,
            Position=1
        )]
        [ValidateScript({
            If(Test-EpochTimestamp -Timestamp $_){$true}
            Else{Throw "InvalidDate: $($_) ins't a valid epoch timestamp"}
        })]
        [Int]$MinTime,

        [Parameter(ParameterSetName="Epoch",
            Mandatory=$false,
            ValueFromPipeline=$false,
            Position=2
        )]
        [ValidateScript({
            If(Test-EpochTimestamp -Timestamp $_){$true}
            Else{Throw "InvalidDate: $($_) ins't a valid epoch timestamp"}
        })]
        [Int]$MaxTime,
        
        [Parameter(ParameterSetName="PSDate",
            Mandatory=$false,
            ValueFromPipeline=$false,
            Position=1
        )]
        [ValidateScript({
            If(Get-Date -Date $_){$true}
            Else{Throw "InvalidDate: $($_) is not a DateTime"}
        })]
        [DateTime]$StartTime,

        [Parameter(ParameterSetName="PSDate",
            Mandatory=$false,
            ValueFromPipeline=$false,
            Position=2
        )]
        [ValidateScript({
            If(Get-Date -Date $_){$true}
            Else{Throw "InvalidDate: $($_) is not a DateTime"}
        })]
        [DateTime]$EndTime,

        [Parameter(
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [Int]$CreditsUsed
    )

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/info/"
    [Hashtable]$DuoParams = @{}

    Switch($Report){
        "TelephonyCredits" {
            [String]$Uri = "/admin/v1/info/telephony_credits_used"
        }
        "AuthenticationAttempts" {
            [String]$Uri = "/admin/v1/info/authentication_attempts"
        }
        "UsersWithAuthAttempts" {
            [String]$Uri = "/admin/v1/info/user_authentication_attempts"
        }
    }

    If($MinTime){
        $DuoParams.Add("mintime",$MinTime)
    }
    If($MaxTime){
        $DuoParams.Add("maxtime",$MaxTime)
    }
    If($Report -eq "TelephonyCredits" -and $CreditsUsed){
        $DuoParams.Add("telephony_credits_used",$CreditsUsed)
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