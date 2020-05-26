param(
    [parameter(Mandatory=$true,HelpMessage="Enter the path to the content source location (e.g., \\server\Sources\Applications\LangFoD)")]
    [string]$SourcePath,
    [parameter(Mandatory=$true,HelpMessage="Please select a Windows 10 Build (e.g., 1903)")]
    [ValidateSet('1809','1903','1909')]
    $Build
)

$BuildTranslate = @{
    '1809'='17763'
    '1903'='18362'
    '1909'='18363'
}
$count = 0
# Get Language Feature applications
Get-CMApplication -Name "Language Features | *" | ForEach{

$count++
write-output "$count - Processing $($_.LocalizedDisplayName)..."

# Get the Language
$_.LocalizedDisplayName -match '(?<lang>[a-z]*-[a-z]*)' | Out-Null
$lang = $matches['lang']

# Construct Requirement Object
$RuleObj = Get-CMGlobalCondition -Name "Windows 10 Build Number" | New-CMRequirementRuleCommonValue -Value1 $BuildTranslate.$Build -RuleOperator IsEquals

# Construct the ContentLocation
$ContentLocation = "$SourcePath\$Build\$lang"

if(!(Test-Path $("filesystem::$ContentLocation"))){
    Write-Output "$ContentLocation does not exist! Please make sure you have extracted the language pack files appropriately!"
    exit 5
}

# Construct the PacksToCheck for the Detection Method
$FoundPacks = @()
Get-ChildItem $("filesystem::$ContentLocation") | ForEach{
    if($_.Name -match 'Basic'){
        $FoundPacks += 'Basic'
    }
    if($_.Name -match 'Handwriting'){
        $FoundPacks += 'Handwriting'
    }
    if($_.Name -match 'OCR'){
        $FoundPacks += 'OCR'
    }
    if($_.Name -match '-Speech'){
        $FoundPacks += 'Speech'
    }
    if($_.Name -match 'TextToSpeech'){
        $FoundPacks += 'TextToSpeech'
    }
}

# Reconstruct $FoundPacks as a string
$StringPacks = $FoundPacks -Join "','"
$StringPacks = "'"+$StringPacks+"'"

# Construct Detection Method
$ScriptBlock = @"
    `$PacksToCheck = @($StringPacks)

    `$installed = `$false

    ForEach(`$pack in `$PacksToCheck){
        if(Get-WindowsPackage -Online -PackageName "Microsoft-Windows-LanguageFeatures-`$pack-$lang-*"){
            `$installed = `$true
        } else{
            `$installed = `$false
            break
        }
    }

    if(`$installed){
        write-host "Installed!"
    }
"@

$DTSplat = @{
    ContentLocation = $ContentLocation
    DeploymentTypeName = "DISM Installer | FoD Packs | $Build"
    InstallCommand = "powershell.exe -ExecutionPolicy Bypass -File DISM_Loop.ps1"
    InstallationBehaviorType = "InstallForSystem"
    LogonRequirementType = "WhetherOrNotUserLoggedOn"
    RebootBehavior = "BasedOnExitCode"
    ScriptLanguage = "PowerShell"
    ScriptText = $ScriptBlock
    AddRequirement = $RuleObj
}

# Add the deployment type for the new build
$_ | Add-CMScriptDeploymentType @DTSplat | out-null

}