param(
    [parameter(Mandatory=$true,HelpMessage="Enter the path to the source directory for the CAB files")]
    [ValidateScript({Test-Path $_ -PathType 'Container'})]
    [string]$SourcePath,
    [parameter(Mandatory=$true,HelpMessage="Enter the path to which the CAB files will be extracted")]
    [ValidateScript({Test-Path $_ -PathType 'Container'})]
    [string]$ExtractPath
)

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

function CopyFiles{
        param(
            $pkgSourcePath,
            $pkgDestPath
        )

        Write-Log $logfile "Extracting [$pack] pack for language [$lang] to [$pkgDestPath]" Extract 1
        if(!(Test-Path $pkgDestPath)){
            New-Item -ItemType Directory -Name $lang -Path $ExtractPath -Force
        }
        Copy-Item $pkgSourcePath $pkgDestPath
}

    #Sanitize inputs
    if($ExtractPath.Substring($ExtractPath.Length-1) -eq '\'){
        $ExtractPath = $ExtractPath.Substring(0,$ExtractPath.Length-1)   
    }
    if($SourcePath.Substring($SourcePath.Length-1) -eq '\'){
        $SourcePath = $SourcePath.Substring(0,$SourcePath.Length-1)   
    }

    $logfile = 'C:\Windows\Temp\Extract-Languages.log'

    if(!(Test-Path $logfile)){
        New-Item -ItemType File -Path $logfile -Force
    }
    
    $FontMapping = @{
        'Ethi'=@('am-ET','ti-ET')
        'Arab'=@('ar-SA','fa-IR','ku-Arab-IQ','pa-Arab-PK','prs-AF','sd-Arab-PK','ug-CN','ur-PK')
        'Syrc'=@('ar-SY','syr-SY')
        'Beng'=@('as-IN','bn-BD','bn-IN')
        'Cher'='chr-Cher-US'
        'Gujr'='gu-IN'
        'Hebr'='he-IL'
        'Deva'=@('hi-IN','kok-IN','mr-IN','ne-NP')
        'Jpan'='ja-JP'
        'Khmr'='km-KH'
        'Knda'='kn-IN'
        'Kore'='ko-KR'
        'Laoo'='lo-LA'
        'Mlym'='ml-IN'
        'Orya'='or-IN'
        'Guru'='pa-IN'
        'Sinh'='si-LK'
        'Taml'='ta-IN'
        'Telu'='te-IN'
        'Thai'='th-TH'
        'Hans'='zh-CN'
        'Hant'='zh-TW'
    }

    $SupportedLanguages=@{
        'af-za'=$false
        'ar-eg'=$true
        'ar-sa'=$true
        'as-in'=$false
        'az-latn-az'=$false
        'ba-ru'=$false
        'be-by'=$false
        'bg-bg'=$true
        'bn-bd'=$false
        'bn-in'=$false
        'bs-latn-ba'=$false
        'ca-es'=$true
        'cs-cz'=$true
        'cy-gb'=$false
        'da-dk'=$true
        'de-at'=$true
        'de-ch'=$true
        'de-de'=$true
        'el-gr'=$true
        'en-au'=$true
        'en-ca'=$true
        'en-gb'=$true
        'en-ie'=$true
        'en-in'=$true
        'en-us'=$true
        'es-es'=$true
        'es-mx'=$true
        'et-ee'=$true
        'eu-es'=$false
        'fa-ir'=$false
        'fi-fi'=$true
        'fil-ph'=$true
        'fr-ca'=$true
        'fr-ch'=$true
        'fr-fr'=$true
        'ga-ie'=$false
        'gd-gb'=$false
        'gl-es'=$false
        'gu-in'=$false
        'ha-latn-ng'=$false
        'haw-us'=$false
        'he-il'=$true
        'hi-in'=$false
        'hr-hr'=$true
        'hu-hu'=$true
        'hy-am'=$false
        'id-id'=$false
        'ig-ng'=$false
        'is-is'=$true
        'it-it'=$true
        'ja-jp'=$true
        'ka-ge'=$false
        'kk-kz'=$false
        'kl-gl'=$false
        'kn-in'=$false
        'kok-deva-in'=$false
        'ko-kr'=$true
        'ky-kg'=$false
        'lb-lu'=$false
        'lt-lt'=$true
        'lv-lv'=$true
        'mi-nz'=$false
        'mk-mk'=$false
        'ml-in'=$false
        'mn-mn'=$false
        'mr-in'=$false
        'ms-bn'=$true
        'ms-my'=$true
        'mt-mt'=$false
        'nb-no'=$true
        'ne-np'=$false
        'nl-be'=$true
        'nl-nl'=$true
        'nn-no'=$true
        'nso-za'=$false
        'or-in'=$false
        'pa-in'=$false
        'pl-pl'=$true
        'ps-af'=$false
        'pt-br'=$true
        'pt-pt'=$true
        'rm-ch'=$false
        'ro-ro'=$true
        'ru-ru'=$true
        'rw-rw'=$false
        'sah-ru'=$false
        'si-lk'=$false
        'sk-sk'=$false
        'sl-si'=$true
        'sq-al'=$false
        'sr-cyrl-rs'=$false
        'sr-latn-rs'=$false
        'sv-se'=$true
        'sw-ke'=$false
        'ta-in'=$false
        'te-in'=$false
        'tg-cyrl-tj'=$false
        'th-th'=$true
        'tk-tm'=$false
        'tn-za'=$false
        'tr-tr'=$true
        'tt-ru'=$false
        'ug-cn'=$false
        'uk-ua'=$true
        'ur-pk'=$false
        'uz-latn-uz'=$false
        'vi-vn'=$true
        'wo-sn'=$false
        'xh-za'=$false
        'yo-ng'=$false
        'zh-cn'=$true
        'zh-hk'=$true
        'zh-tw'=$true
        'zu-za'=$false
    }

    Write-Log $logfile "Starting execution of Extract-Languages.ps1" Start 1

    #Gather packages
    Write-Log $logfile "Gathering Language Feature CAB files from [$SourcePath]" Gather 1

    $TODOpkgs = Get-ChildItem $SourcePath -Filter '*LanguageFeatures*.cab'
    if($TODOpkgs){
        Write-Log $logfile "The following packages will be extracted:" Gather 1
        foreach($pkg in $TODOpkgs){
            Write-Log $logfile $pkg.Name Gather 1
        }

        foreach($pkg in $TODOpkgs){
            #Extract packages
            if($pkg.Name -match 'LanguageFeatures-(?<Pack>[A-Z]*(?=-))-((?<lang>.*)(?=-Package))'){
                $pack = $matches['Pack']
                $lang = $matches['lang']
                if($pack -eq 'Fonts'){
                    Write-Log $logfile "Found [$lang] Font pack, mapped to languages [$($FontMapping.$lang -join ',')]" Extract 1
                    foreach($l in $FontMapping.$lang){
                        if($SupportedLanguages.$l){
                            CopyFiles $pkg.FullName "$ExtractPath\$l"
                        }
                        else {
                            Write-Log $logfile "[$lang] Font pack maps to [$l], which is not a supported language. Skipping copy for [$l]." Extract 1
                        }
                    }
                }
                else {
                    if($SupportedLanguages.$lang){
                        CopyFiles $pkg.FullName "$ExtractPath\$lang"
                    }
                    else {
                        Write-Log $logfile "[$lang] is not a supported language. Skipping [$pack] pack for [$lang]" Extract 1
                    }
                } 
            } else {
                Write-Log $logfile "Package [$($pkg.Name)] was queued but does not appear to be a Language Feature. Skipping package." Extract 2
            }
        }

    } else {
        Write-Log $logfile "No packages found. Nothing to do." Gather 2
    }

   