Function Get-DuoBypassCode{
<#
.SYNOPSIS
    Retrieves bypass codes from Duo.

.DESCRIPTION
    This function retrieves bypass codes from Duo based on the provided parameters. It can fetch bypass codes by BypassCodeID or return all bypass codes if no ID is specified.

.PARAMETER BypassCodeID
    The ID of the Duo bypass code. This parameter is optional.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    PARAM(
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true
        )]
        [ValidateScript({
            If(Test-DuoBypassCode -BypassCodeID $_){$true}
            Else{Throw "Invalid User ID"}
        })]
            [String]$BypassCodeID
    )
    #Base claim
    [String]$Method = "GET"
    If($BypassCodeID){
        [String]$Uri = "/admin/v1/bypass_codes/$($BypassCodeID)"
    }
    Else{
        [String]$Uri = "/admin/v1/bypass_codes"
    }
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("limit","500")
    $DuoParams.Add("offset","0")

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
            #Increment offset to return the next 500 Bypass codes
            $Offset += 500
        }
    }Until($Output.Count -lt 500)
}

Function Remove-DuoBypassCode{
<#
.SYNOPSIS
    Removes a bypass code from Duo.

.DESCRIPTION
    This function removes a specified bypass code from Duo by BypassCodeID.

.PARAMETER BypassCodeID
    The ID of the Duo bypass code to be removed. This parameter is mandatory.

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>

    Param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true
        )]
        [ValidateScript({
            If(Test-DuoBypassCode -BypassCodeID $_){$true}
            Else{Throw "Invalid User ID"}
        })]
            [String]$BypassCodeID
    )

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/bypass_codes/$($BypassCodeID)"
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