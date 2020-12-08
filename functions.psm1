<##########################################################
# Autor: AMI
# Datum: 07.12.2020
#
# BESCHREIBUNG
# ------------
# Dies ist der Ausführungsscript
#
##########################################################>




##### CONFIG SERVICE #####
    ### loadConfigsFromJson() Method ********************************
        function loadConfigsFromJson {
            [CmdletBinding()]
            param (
                [string] $filePath,
                [string] $filter,
                [string] $node
            )
            
            $configsFile = Get-ChildItem -Path "$filePath" -File -Filter $filter -Depth 2
            $configsAsJson = (Get-Content -Path $($configsFile.FullName)) | ConvertFrom-Json
            $configsAsJson = $configsAsJson.$node

            return $configsAsJson
        }
    ### loadConfigsFromJson() Method ________________________________
    
    ### loadConfigsFromXML() Method ********************************
        function loadConfigsFromXML {
            [CmdletBinding()]
            param (
                [string] $filePath,
                [string] $filter,
                [string] $node
            )

            $configFile = Get-ChildItem -Path $filePath -File -Filter $filter -Depth 1
            [xml] $configsAsXML = Get-Content -Path $($configFile.FullName)

            return $configsAsXML
        }
    ### loadConfigsFromXML() Method ________________________________

    ### processConfigs() Method ********************************
        function processConfigs {
            [CmdletBinding()]
            param (
                [System.Object] $configsAsJson,
                [System.Array] $configFiles
            )

            foreach ($configFile in $configFiles) {
                if ($configsAsJson."$($configFile.Name)") {
                    if ($configFile.Extension -eq ".xml") {
                        [xml] $serviceConfigs = Get-Content -Path "$($configFile.FullName)"
                        $nodes = $serviceConfigs.ChildNodes
                        $attributes = $serviceConfigs.Attributes
                    } elseif ($configFile.Extension -eq ".properties") {
                        $serviceConfigs = propertiesToHashtable -filePath "$($configFile.FullName)"
                        $configsToEnter = convertJsonToHashtable -jsonObj $($configsAsJson[0]."$($configFile.Name)")
                        
                        $changedConfigs = changeProperties -serviceConfigsToChange $serviceConfigs -configsToEnter $configsToEnter
                        writeChangedConfigs -binarConfig $changedConfigs -outputFilePath "$($configFile.FullName)_test"
                    }
                }
            } #>
        }
    ### processConfigs() Method ________________________________
        
    ### convertJsonToHashtable() Method ********************************
    function convertJsonToHashtable {
        [CmdletBinding()]
        param (
            [System.Object] $jsonObj
        )
        
        $hashtable = @{}
        $jsonObj.psobject.properties | ForEach-Object { $hashtable[$_.Name] = $_.Value }

        return $hashtable
    }
    ### convertJsonToHashtable() Method ________________________________

    ### propertiesToHashtable() Method ********************************
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
        return $propertiesHashtable
    }
    ### propertiesToHashtable() Method ________________________________
    
    ### changeProperties() Method ********************************
    function changeProperties {
        [CmdletBinding()]
        param (
            [System.Collections.Hashtable] $serviceConfigsToChange,
            [System.Collections.Hashtable] $configsToEnter
        )
        
        foreach ($enterKey in $($configsToEnter.Keys)) {
            $keysMatch = $false
            foreach ($serviceKey in $($serviceConfigsToChange.Keys)) {
                if ($enterKey -eq $serviceKey) {
                    $serviceConfigsToChange.Set_Item($serviceKey, $configsToEnter[$enterKey])
                    $keysMatch = $true
                }
            }
            if (!$keysMatch) {
                $serviceConfigsToChange.Add($enterKey, $configsToEnter[$enterKey])
            }
        }
        return $serviceConfigsToChange
    }
    ### changeProperties() Method ________________________________
    
    ### writeChangedConfigs() Method ********************************
    function writeChangedConfigs {
        [CmdletBinding()]
        param (
            [System.Collections.Hashtable] $binarConfig,
            [String] $outputFilePath
        )
        
        foreach ($item in $binarConfig.GetEnumerator()) { # | Sort-Object -Property Key) {
            Add-Content $outputFilePath "$($item.Key)=$($item.Value)"
        }
    }
    ### writeChangedConfigs() Method ________________________________

    ### convertStringToBytes() Method ********************************
    function convertStringToBytes {
        [CmdletBinding()]
        param (
            [string] $stringToConvert
        )
        
        $byteArray = [System.Text.Encoding]::UTF8.GetBytes($stringToConvert) | %{ [System.Convert]::ToString($_,2).PadLeft(8,'0') }

        return $byteArray
    }
    ### convertStringToBytes() Method ________________________________
