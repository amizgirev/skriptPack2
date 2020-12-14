<##########################################################
# Autor: AMI
# Datum: 04.11.2020
#
# BESCHREIBUNG
# ------------
# Dies ist der Ausführungsscript
#
##########################################################>


[CmdletBinding()]
param (
    ## SHARE DRIVE ##
    #[Parameter(Mandatory)]
    [String] $server = "riblstickylos.file.core.windows.net",
    #[Parameter(Mandatory)]
    [String] $serverUser = "Azure\riblstickylos",
    #[Parameter(Mandatory)]
    [String] $serverPass = "6gf118BCU2Fx7GSEwzGPJU031qhqA0auJujAoxiJanHcZs8Tc8xzlWMHVnuw7OAZVX2aPEsVr2lQStIz/0sUog==",
    #[Parameter(Mandatory)]
    [String] $serverShareFile = "data",
    [string] $serverShareDrive = "\\$server\$serverShareFile",

    ## SERVICE NAME ##
    #[Parameter(Mandatory)]
    [ValidateSet('iTWOsite_Web','iTWOsite_DSWeb','iTWOsite_DLWeb')]
    [String[]] $serviceNames = @('iTWOsite_DSWeb', 'iTWOsite_Web', 'iTWOsite_DLWeb'),
    
    [string] $toolsRoot = "C",
    [string] $ribToolsPath = "$($toolsRoot):\RIBTools",
    [string] $externalToolsPath = "$($toolsRoot):\ExternalTools"

)

$modulePath = Get-Location
Import-Module -Name "$modulePath\functions.psm1"


##### MAIN #####

Get-Date -Format "dd.MM.yyyy HH:mm:ss"
$strartTime = Get-Date

## mount Share device
if (!(Test-Path $serverShareDrive)) {
    Import-Module -Name "C:\MyTools\vscode\installVMTools\functions.psm1"
    mountNetworkDevice -computerName $server `
                        -user $serverUser `
                        -pass $serverPass `
                        -shareFile $serverShareDrive
    Get-Module "C:\MyTools\vscode\installVMTools\functions.psm1" -ListAvailable | Remove-Module
} #>




# $ribConfigs = readFileToHashtable -fileType "properties" -filePath $ribConfigsPath
# $serviceConfigs = readFileToHashtable -fileType $fileType -filePath $log4jFilePath
# changeConfigs -serviceConfigs $serviceConfigs -ribConfigs $ribConfigs
# writeChangedConfigs -binarConfig $serviceConfigs -outputFilePath $outputFilePath


Write-Host "`n---------- AUSGABENBEREICH ----------`n"
Write-Host "Davor: TEST`n"


foreach ($serviceName in $serviceNames) {
    if (Test-Path -Path "$ribToolsPath\$serviceName") {
        $configFiles = Get-ChildItem -Path "$ribToolsPath\$serviceName" -Include "*.xml","*.properties" -Depth 1 `
                            | Where-Object { $_.DirectoryName -eq "$ribToolsPath\$serviceName\conf" `
                            -or $_.DirectoryName -eq "$ribToolsPath\$serviceName\itwosite" }
        
        $jsonConfigs = loadConfigsFromJson -filePath "$serverShareDrive\TMP" -filter "RIB_configs.json" -node $serviceName
        
        processConfigs -serviceName $serviceName `
                        -parentPath $ribToolsPath `
                        -serverShareDrive "$serverShareDrive\TMP" `
                        -configsAsJson $jsonConfigs `
                        -configFiles $configFiles
    }
}


Write-Host "`nDanach: TEST"
Write-Host "`n---------- AUSGABENBEREICH ----------`n"


Write-Host "Laufzeit der Anwendung: $(New-TimeSpan -Start $strartTime -End (get-date))"
Get-Module "$modulePath\functions.psm1" -ListAvailable | Remove-Module