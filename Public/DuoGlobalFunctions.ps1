Function New-DuoConfig{
<#
.Synopsis
    DUO REST API Configuration
.DESCRIPTION
    Sets the default configuration for PSDUO with and option to save it.
.EXAMPLE
    New-DUOConfig -IntergrationKey SDFJASKLDFJASLKDJ -SecretKey ASDKLFJSM<NVCIWJRFKSDM<>SMVNFNSKLF -apiHost api-###XXX###.duosecurity.com
    Generate a module scoped variable for DUO's REST API
.EXAMPLE
   New-DUOConfig -IntergrationKey SDFJASKLDFJASLKDJ -SecretKey ASDKLFJSM<NVCIWJRFKSDM<>SMVNFNSKLF -apiHost api-###XXX###.duosecurity.com -SaveConfig -Path C:\Duo\DuoConfig.xml
    Generates the global variable for DUO's REST API
.OUTPUTS
    [PSCustomObject]$DuoConfig
.NOTES
   
.COMPONENT
    PSDuo
#>
    [CmdLetBinding(DefaultParameterSetName="None")]   
    Param(
        [Parameter(Position=0,Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$IntergrationKey,

        [Parameter(Position=1,Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$SecretKey,
        
        [Parameter(Position=2,Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$apiHost,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String[]]$DirectoryKeys,

        [Parameter(ParameterSetName='SaveConfig',Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Switch]$SaveConfig,

        [Parameter(ParameterSetName='SaveConfig',Mandatory = $true)]
        [ValidateScript({
            If(Test-Path (Split-Path -Path $_ -Parent)){$true}
            Else{throw "Path $_ is not valid"}
        })]
        [String]$Path
        )

    $iKey = $IntergrationKey | ConvertTo-SecureString -AsPlainText -Force
    $sKey = $SecretKey | ConvertTo-SecureString -AsPlainText -Force
    $DuoAPIHost = $apiHost | ConvertTo-SecureString -AsPlainText -Force

    $DuoConfig = @{}
    $DuoConfig.Add("IntergrationKey",$iKey)
    $DuoConfig.Add("SecretKey", $sKey)
    $DuoConfig.Add("ApiHost", $DuoAPIHost)
    
    If($DirectoryKeys){
        $i = 0
        ForEach($DirectoryKey in $DirectoryKeys){
            $i+1
            $DirectoryKey = $DirectoryKey | ConvertToSecureString -AsPlainText -Force
            $DuoConfig.Add("DirectoryKey$($i)",$DirectoryKey)
        }
    }

    If($SaveConfig){
        $DuoConfig.Add("Config",$Path)
        $DuoConfig | Export-Clixml -Path $Path
    }
    $Script:DuoConfig = $DuoConfig
}

Function Add-DuoDirectoryKeys{
<#
.Synopsis
    Adds DUO directory connector key values
.DESCRIPTION
    Sets the key values and names in configuration for later use.
.EXAMPLE
    Add-DuoDirectoryKeys - KeyName "Directory" -Value "ABC123456789EFG"
.OUTPUTS
    [PSCustomObject]$DuoConfig
.NOTES
   
.COMPONENT
    PSDuo
#>
    [CmdLetBinding(DefaultParameterSetName="None")]   
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
            [String]$KeyName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
            [String]$KeyValue,
        [Parameter(ParameterSetName="Save",Mandatory = $false)]
            [Switch]$SaveConfig,
        [Parameter(ParameterSetName="Save",Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            If(Test-Path (Split-Path -Path $_ -Parent)){$true}
            Else{throw "Path $_ is not valid"}
        })]
        [String]$Path
    )

    $dKey = $KeyValue | ConvertTo-SecureString -AsPlainText -Force
    $Script:DuoConfig.Add($KeyName,$dKey)

    If($SaveConfig -and $Path){
        #If(Test-Path $Script:DuoConfig){
        #    $Path = $Script:DuoConfig.Config
        #}
        #Else{
        #    Write-Warning "Running Config is not saved."
        #    $Path = Read-Host "Please enter desired save path."
        #}
        Try{
            $DuoConfig = $Script:DuoConfig
            $DuoConfig | Export-Clixml -Path $Path
        }
        Catch{
            Write-Error "Invalid entry"
        }
    }
}

Function Get-DuoDirectoryNames{
    $DuoConfig = Get-DuoConfig
    $IgnoreValues = @("apiHost","SecretKey","IntergrationKey")
    $Output = $DuoConfig.GetEnumerator() | Where-Object Name -NotIn $IgnoreValues
    $Output.Name
}

Function Import-DuoConfig{
<#
.Synopsis
   DUO REST API Configuration Import
.DESCRIPTION
   Imports a previously saved Duo Configuration
.EXAMPLE
    Import-DuoConfig -Path C:\Duo\DuoConfig.xml
    Generate a module scoped variable for DUO's REST API
.OUTPUTS
    [PSCustomObject]$DuoConfig
.NOTES
   
.COMPONENT
    PSDuo
.ROLE
   
.FUNCTIONALITY
   
#>
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
        If(Test-Path $_){$true}
            Else{throw "Path $_ is not valid"}
        })]
        [String]$Path
    )
    $Imported = Import-Clixml -Path $Path
    $DuoConfig.apiHost = $Imported.apiHost
    
    $Script:DuoConfig = $DuoConfig
    $DuoConfig
}

#Get Duo Config
Function Get-DuoConfig{
<#
.Synopsis
   Return the DUO REST API Configuration Settings
.DESCRIPTION
   Gets the default configuration for PSDUO.
.EXAMPLE
   Get-DuoConfig 
   Returns the Config for the current DUO Session.
.OUTPUTS
   [PSCustomObject]$DuoConfig
.NOTES
   
.COMPONENT
   PSDuo
.ROLE
   
.FUNCTIONALITY
   
#>
    [CmdletBinding(
    )]
    PARAM()
    If(!($Script:DuoConfig)){
        Write-Warning "Please set up a DUO Configuration via New-DuoConfig cmdlet"
    }
    Write-Output $Script:DuoConfig
}