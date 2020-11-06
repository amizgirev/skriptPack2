<##########################################################
# Autor: AMI
# Datum: 03.11.2020
#
# BESCHREIBUNG
#
# INFO
#
##########################################################>


function xmlToHashtable {
    [CmdletBinding()]
    param (
        [String] $filePath
    )
    # XML parsen und binär ausgeben oder so
}

function propertiesToHashtable {
    [CmdletBinding()]
    param (
        [String] $filePath
    )
    $propertiesConfigs = Get-Content $filePath | ConvertFrom-StringData #-Delimiter '='
    $propertiesHashtable = @{}
    for ($i = 0; $i -lt $propertiesConfigs.Length; $i++) {
        try { $propertiesHashtable.Add($propertiesConfigs.Keys[$i], $propertiesConfigs.Values[$i]) }
        catch { } #$counter++; Write-Host "$($i): $($propertiesConfigs[$i].Keys)" }
    }
    $propertiesHashtable
}

function readFileToHashtable {
    [CmdletBinding()]
    param (
        [String] $fileType,
        [String] $filePath
    )
    # readProperties aufrufen und dann in die Hashtabel verwandeln
    if ($fileType -eq "properties") {

        Write-Host "Input file is of type $fileType"
        propertiesToHashtable -filePath $filePath

    } elseif ($fileType -eq "xml") {

        Write-Host "Input file is of type $fileType"
        xmlToHashtable -filePath $filePath
        
    } else {
        Write-Host "Unknown type $fileType"
    }
}

function changeConfigs {
    [CmdletBinding()]
    param (
        [System.Collections.Hashtable] $serviceConfigs,
        [System.Collections.Hashtable] $ribConfigs
    )
    
    foreach ($serviceKey in $($serviceConfigs.Keys)) {
        foreach ($ribKey in $($ribConfigs.Keys)) {
            if ($serviceKey -match $ribKey) {
                $serviceConfigs.Set_Item($serviceKey, $ribConfigs[$ribKey])
            }
        }
        
    }
    $serciveConfigs
}

function writeChangedConfigs {
    [CmdletBinding()]
    param (
        [System.Collections.Hashtable] $binarConfig,
        [String] $outputFilePath
    )
    
    foreach ($item in $binarConfig.GetEnumerator() | Sort-Object -Property Key) {
        Add-Content $outputFilePath "$($item.Key)=$($item.Value)"
    }
}



#Export-ModuleMember -Function *

