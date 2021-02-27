function Restart-IISAppPool {
    <#
    .SYNOPSIS
    .
    .DESCRIPTION
    Checks the status of an IIS App Pool and if stopped it will start it, if started then it will stop and start the app pool. 

    .PARAMETER AppPoolName
    This is the name of the IIS App Pool you want to restart.

    .NOTES
    Author: Ieuan Payne
    Created: 30/01/2021
    Updated: 31/01/2021
    Version: 1.1
    #>

    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$True)]
        [string]$AppPoolName
    )

    Import-Module WebAdministration

    #Check state of app pool
    $AppPoolState = (Get-WebAppPoolState -Name $AppPoolName).value

    if($AppPoolState.value -ne 'Started'){
        Write-Output '$AppPoolName is not started'
        Start-WebAppPool -Name $AppPoolName
        $PostStartAppPoolState = (Get-WebAppPoolState -Name $AppPoolName).value
        Write-Output $PostStartAppPoolState.value
        elseif ($AppPoolState.value -eq 'Started') {
            Write-Output '$AppPoolName is already started, restart required'
            Stop-WebAppPool -Name $AppPoolName
            Start-Sleep -Seconds 5
            Start-WebAppPool -Name $AppPoolName
            Start-Sleep -Seconds 5
            $PostRestartAppPoolState = (Get-WebAppPoolState -Name $AppPoolName).value
            Write-Output $PostRestartAppPoolState.value
        }
    }
}

function New-IISAppPool {

    <#
    .SYNOPSIS
    .
    .DESCRIPTION
    Creates application pool folder structure, IIS application pool and web application under one or all IIS websites except the default one. 

    .PARAMETER AppPoolName
    The name of the IIS App Pool you wish to create.

    .NOTES
    Author: Ieuan Payne
    Created: 31/01/2021
    Updated:
    Version: 1.0
    #>

    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$True)]
        [string]$AppPoolName
    )
    
        if(Test-Path IIS:\AppPools\$AppPoolName)
        {
        Write-Output "AppPool is already there"
        return $true;
        }
        else
        {
        "AppPool is not present"
        Write-Output "Creating new AppPool: $AppPoolName"
        New-WebAppPool -Name "$AppPoolName" -Force
        return $false;
    }
}

function New-IISApplication {

    <#
    .SYNOPSIS
    .
    .DESCRIPTION
    Creates application under a predefined IIS Site and will be contained in a IIS App Pool

    .PARAMETER ApplicationName
    This is the name of the Application you want to install the application into IIS as.

    .PARAMETER SiteName
    This is the name of the Site you want to install the application under. 

    .PARAMETER FilesPath
    This is the location to the folder that contains the install files for the IIS Application.

    .PARAMETER AppPool
    This is the name of the IIS App Pool to contain the new application

    .NOTES
    Author: Ieuan Payne
    Created: 31/01/2021
    Updated:
    Version: 1.0 
    #>

    [CmdletBinding()]
        Param(
        [Parameter(Mandatory=$True)]
            [string]$ApplicationName,
        [Parameter(Mandatory=$True)]
            [string]$SiteName,
        [Parameter(Mandatory=$True)]
            [string]$FilesPath,
        [Parameter(Mandatory=$True)]
            [string]$AppPool
        )

        #Test that folder that contains install files exists
        if (-not (Test-Path -LiteralPath $FilesPath)) {
            try {
                New-Item -Path $FilesPath -ItemType Directory -ErrorAction Stop
            }
            catch {
                Write-Error -Message "Unable to create directory '$FilesPath'. Error was: $_" -ErrorAction Stop
            }
            "Successfully created directory '$FilesPath'."
        }
        else {
            "Directory already existed"
        }

        #Test that the App Pool exists - if not create it
        if(Test-Path IIS:\AppPools\$AppPool)
            {
            Write-Output "AppPool is already there"
            return $true;
            }
        else
            {
            "AppPool is not present"
            Write-Output "Creating new AppPool: $AppPool"
            New-WebAppPool -Name "$AppPool" -Force
            return $false;
        }

        #Create new IIS Application
        New-WebApplication -Name $ApplicationName -Site $SiteName -PhysicalPath $FilesPath -ApplicationPool $AppPool
}