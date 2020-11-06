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
    [Parameter()]
    [String] $ribConfigsPath = "C:\arbeit\automatisierung\ps-scripts\configTools\servicesConfigs\RIB_configs.properties",
    [Parameter()]
    [String] $dbFilePath = "C:\arbeit\automatisierung\ps-scripts\configTools\itwosite_web\servicesConfigs\db.properties",
    [Parameter()]
    [String] $log4jFilePath = "C:\arbeit\automatisierung\ps-scripts\configTools\servicesConfigs\iTWOsite_Web\itwosite\log4j.properties",
    [Parameter()]
    [String] $outputFilePath = "C:\arbeit\automatisierung\ps-scripts\configTools\servicesConfigs\iTWOsite_Web\itwosite\log4j_output.properties",
    [Parameter()]
    [String] $fileType = "properties"
)

$modulePath = Get-Location
Import-Module -Name "$modulePath\propertiesProcessing.ps1"


##### MAIN #####

$ribConfigs = readFileToHashtable -fileType "properties" -filePath $ribConfigsPath
$serviceConfigs = readFileToHashtable -fileType $fileType -filePath $log4jFilePath
changeConfigs -serviceConfigs $serviceConfigs -ribConfigs $ribConfigs
writeChangedConfigs -binarConfig $serviceConfigs -outputFilePath $outputFilePath


Write-Host "`n---------- AUSGABENBEREICH ----------`n"

Write-Host "Davor: TEST"
$ribConfigs
Write-Host "Danach: TEST"

Write-Host "`n---------- AUSGABENBEREICH ----------`n"



Get-Module "$modulePath\propertiesProcessing.ps1" -ListAvailable | Remove-Module