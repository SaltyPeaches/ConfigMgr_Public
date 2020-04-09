Function Write-Log {
    ##########################################################################################################
    <#
    .SYNOPSIS
       Log to a file in a format that can be read by Trace32.exe / CMTrace.exe 
    
    .DESCRIPTION
       Write a line of data to a script log file in a format that can be parsed by Trace32.exe / CMTrace.exe
    
       The severity of the logged line can be set as:
    
            1 - Information
            2 - Warning
            3 - Error
    
       Warnings will be highlighted in yellow. Errors are highlighted in red.
    
       The tools to view the log:
    
       CM Trace - Installation directory on Configuration Manager 2012 Site Server - <Install Directory>\tools\
    
    .EXAMPLE
       Write-Log c:\output\update.log "Application of MS15-031 failed" Apply_Patch 3
    
       This will write a line to the update.log file in c:\output stating that "Application of MS15-031 failed".
       The source component will be Apply_Patch and the line will be highlighted in red as it is an error 
       (severity - 3).
    
    #>
    ##########################################################################################################
    
    #Define and validate parameters
    [CmdletBinding()]
    Param(
          #Path to the log file
          [parameter(Mandatory=$True)]
          [String]$LogFile,
    
          #The information to log
          [parameter(Mandatory=$True)]
          [String]$Value,
    
          #The source of the error
          [parameter(Mandatory=$True)]
          [String]$Component,
    
          #The severity (1 - Information, 2- Warning, 3 - Error)
          [parameter(Mandatory=$True)]
          [ValidateRange(1,3)]
          [Single]$Severity
          )
    
    #Obtain UTC offset
    $DateTime = New-Object -ComObject WbemScripting.SWbemDateTime 
    $DateTime.SetVarDate($(Get-Date))
    $UtcValue = $DateTime.Value
    $UtcOffset = $UtcValue.Substring(21, $UtcValue.Length - 21)
    
    #Create the line to be logged
    $LogLine =  "<![LOG[$Value]LOG]!>" +`
                "<time=`"$(Get-Date -Format HH:mm:ss.fff)$($UtcOffset)`" " +`
                "date=`"$(Get-Date -Format M-d-yyyy)`" " +`
                "component=`"$Component`" " +`
                "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
                "type=`"$Severity`" " +`
                "thread=`"$($pid)`" " +`
                "file=`"`">"
    
    #Write the line to the passed log file
    Out-File -InputObject $LogLine -Append -NoClobber -Encoding Default -FilePath $LogFile -WhatIf:$False
    
}

    
    $logfile = 'C:\Windows\CCM\Logs\AppLogs\Install-Languages.log'
    [bool]$rebootRequired=$false

    if(!(Test-Path $logfile)){
        New-Item -ItemType File -Path $logfile -Force
    }

    Write-Log $logfile "Starting execution of DISM_Loop.ps1" Start 1

    #Gather DISM packages
    Write-Log $logfile "Gathering packages to install via DISM" Gather 1

    $TODOpkgs = Get-ChildItem $PSSCriptRoot -Filter '*LanguageFeatures*.cab'
    if($TODOpkgs){
        Write-Log $logfile "The following packages will be installed:" Gather 1
        foreach($pkg in $TODOpkgs){
            Write-Log $logfile $pkg.Name Gather 1
        }
        foreach($pkg in $TODOpkgs){
            $DISMpkg = "$PSScriptRoot\$($pkg.Name)"
            
            #Install package
            if($pkg.Name -match 'LanguageFeatures-(?<Pack>[A-Z]*(?=-))-((?<lang>.*)(?=-Package))'){
                $pack = $matches['Pack']
                $lang = $matches['lang']
                try{
                    Write-Log $logfile "Installing [$pack] pack for [$lang]" Install 1
                    DISM /Online /Add-Package /PackagePath:$DISMpkg /Quiet /NoRestart
                    if($LASTEXITCODE -eq 0){
                        Write-Log $logfile "Successfully installed [$pack] pack for [$lang] [Reboot Required=FALSE]" Install 1
                    } elseif($LASTEXITCODE -eq 3010){
                        Write-Log $logfile "Successfully installed [$pack] pack for [$lang] [Reboot Required=TRUE]" Install 2
                        if(!$rebootRequired){
                            $rebootRequired=$true
                        }
                    }
                }
                catch{
                    Write-Log $logfile "Failed to install [$pack] pack for [$lang]" Install 3
                }
            } else {
                Write-Log $logfile "Package [$($pkg.Name)] was queued but is not a Language Feature. Skipping package." Install 2
            }
        }

    } else {
        Write-Log $logfile "No packages found. Nothing to do." Gather 2
    }

    if($rebootRequired){
        Write-Log $logfile "Ending execution with return code [3010] - Reboot Required" Finalize 2
        exit 3010
    } else{
        Write-Log $logfile "Ending execution with return code [0]" Finalize 1
        exit 0
    }

   