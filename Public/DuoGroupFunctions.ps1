Function Get-DuoGroup{
<#
.SYNOPSIS
    Retrieves details of Duo groups.

.DESCRIPTION
    This function retrieves details of Duo groups based on the provided parameters. It can fetch groups by Name or GroupID.

.PARAMETER Name
    The name of the Duo group. This parameter is optional and is part of the Gname parameter set.

.PARAMETER GroupID
    The ID of the Duo group. This parameter is optional and is part of the GID parameter set.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    [CmdletBinding(DefaultParameterSetName="Gname")]
    Param(
        [Parameter(
            ParameterSetName="Gname",
            Mandatory=$false
        )]
        [String]$Name,

        [Parameter(
            ParameterSetName="GID",
            Mandatory=$false
        )]
        [String]$GroupID
    )

    #Base Claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v2/groups"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("limit","100")
    $DuoParams.Add("offset","0")

    If($GroupID){
        $Groups = $null
        Write-host "ID"
    }
    ElseIf($Name){
        $Groups = Get-AllDuoGroups | Where-Object Name -Like "$($Name)*"
    }
    Else{
        $Groups = Get-AllDuoGroups
    }
    If($null -eq $Groups){
        [String]$Uri = "/admin/v2/groups/$($GroupID)"
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
    Else{
        ForEach($Group in $Groups){
            $GroupID = $Group.group_id
            [String]$Uri = "/admin/v2/groups/$($GroupID)"
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
}

Function Get-DuoGroupMember{
<#
.SYNOPSIS
    Retrieves members of a Duo group.

.DESCRIPTION
    This function retrieves members of a specified Duo group. It can fetch group members by Group Name or Group ID.

.PARAMETER Name
    The name of the Duo group. This parameter is mandatory when using the Gname parameter set.

.PARAMETER GroupID
    The ID of the Duo group. This parameter is mandatory when using the GID parameter set.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>

    [CmdletBinding(DefaultParameterSetName="GID")]
    Param(
        [Parameter(
            ParameterSetName="Gname",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoGroup -GroupName $_){$true}
            Else{Throw "Invalid Group"}
        })]
        [String]$Name,

        [Parameter(
            ParameterSetName="GID",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoGroup -GroupName $_){$true}
            Else{Throw "Invalid Group ID"}
        })]
        [String]$GroupID
    )

    If($Name){
        $Group = Get-DuoGroup -GroupName $Name
        If($Group.group_id.count -gt 1){
            Write-Warning "Multiple groups returned"
            Return "Please use exact group name."
        }
        Else{
            $GroupID = $Group.group_id
        }
    }
    If($GroupID){
        [String]$Uri = "/admin/v2/groups/$($GroupID)/users"
        $Method = "GET"
        [Hashtable]$DuoParams = @{}
        $DuoParams.Add("limit","500")
        $DuoParams.Add("offset","0")
        $Offset = 0

        Do{
            $DuoParams.offset = $Offset
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
                $Offset += 500
            }
        }Until($Output.count -lt 500)
    }
}

Function New-DuoGroup{
<#
.SYNOPSIS
    Creates a new group in Duo.

.DESCRIPTION
    This function creates a new group in Duo with the specified name, description, and status.

.PARAMETER Name
    The name of the Duo group. This parameter is mandatory. The group name must be unique.

.PARAMETER Description
    The description of the Duo group. This parameter is optional.

.PARAMETER Status
    The status of the Duo group. Valid values are "Active", "Bypass", and "Disabled". This parameter is optional.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>

    Param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0)]
        [ValidateScript({
            If(Test-DuoGroup -GroupName $_){Throw "Group $_ already exist"}
            Else{$true}
        })]
        [String]$Name,

        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=1
        )]
        [String]$Description,

        [Parameter(Mandatory=$false)]
        [ValidateSet("Active","Bypass","Disabled")]
        [String]$Status
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/groups"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("name",$Name)
    If($Description){
        $DuoParams.Add("desc",$Description)
    }
    If($Status){
        $DuoParams.Add("status",$Status)
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

Function Update-DuoGroup{
<#
.SYNOPSIS
    Updates the details of a Duo group.

.DESCRIPTION
    This function updates the details of a specified Duo group. It allows modifying the group's name, description, and status.

.PARAMETER GroupID
    The ID of the Duo group to be updated. This parameter is mandatory.

.PARAMETER Name
    The new name for the Duo group. This parameter is optional.

.PARAMETER Description
    The new description for the Duo group. This parameter is optional.

.PARAMETER Status
    The new status for the Duo group. Valid values are "Active", "Bypass", and "Disabled". This parameter is optional.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>

    Param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0)]
        [ValidateScript({
            If(Test-DuoGroup -GroupName $_){$true}
            Else{Throw "Invalid Group ID"}
        })]
        [String]$GroupID,

        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=1
        )]
        [Parameter(Mandatory=$false,
            ValuefromPipeline=$true,
            Position=2
        )]
        [String]$Name,

        [Parameter(Mandatory=$false,
            ValueFromPipeline=$false
        )]
        [String]$Description,

        [Parameter(Mandatory=$false)]
        [ValidateSet("Active","Bypass","Disabled")]
        [String]$Status
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/groups/$($GroupID)"
    [Hashtable]$DuoParams = @{}
    If($Name){
        $DuoParams.Add("name",$Name)
    }
    If($Status){
        $DuoParams.Add("status",$Status)
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

Function Remove-DuoGroup{
<#
.SYNOPSIS
    Removes a group from Duo.

.DESCRIPTION
    This function removes a specified group from Duo by GroupID.

.PARAMETER GroupID
    The ID of the Duo group to be removed. This parameter is mandatory.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>

    Param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0)]
        [ValidateScript({
            If(Test-DuoGroup -GroupName $_){$true}
            Else{Throw "Invalid Group ID"}
        })]
        [String]$GroupID
    )

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/groups/$($GroupID)"
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