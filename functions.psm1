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
                [string] $serviceName,
                [string] $parentPath,
                [System.Object] $configsAsJson,
                [System.Array] $configFiles
            )

            foreach ($configFile in $configFiles) {
                if ($configsAsJson."$($configFile.Name)") {
                    if ($configFile.Extension -eq ".xml") {
                        changeXML -serviceName $serviceName -parentPath $parentPath -configsAsJson $configsAsJson -configFile $configFile
                    } elseif ($configFile.Extension -eq ".properties") {
                        $serviceConfigsToChange = propertiesToHashtable -filePath "$($configFile.FullName)"
                        $configsToEnter = convertJsonToHashtable -jsonObj $($configsAsJson[0]."$($configFile.Name)")
                        
                        $changedConfigs = changeProperties -serviceConfigsToChange $serviceConfigsToChange -configsToEnter $configsToEnter
                        writeChangedConfigs -binarConfig $changedConfigs -outputFilePath "$($configFile.FullName)"
                    }
                }
            } #>
        }
    ### processConfigs() Method ________________________________

    ### changeXML() Method ********************************
        function changeXML {
            [CmdletBinding()]
            param (
                [string] $serviceName,
                [string] $parentPath,
                [System.Object] $configsAsJson,
                [System.IO.FileSystemInfo] $configFile
            )
            
            $configFileNames = $configsAsJson `
                                | Get-Member -MemberType Properties `
                                | Select-Object -ExpandProperty Name `
                                | Where-Object { $_ -eq $configFile.Name}

            foreach ($configFileName in $configFileNames) {
                # $configFile = Get-ChildItem -Path "$parentPath\$serviceName" -Filter $configFileName -Depth 1 `
                #                 | Where-Object { $_.DirectoryName -eq "$parentPath\$serviceName\conf" `
                #                         -or $_.DirectoryName -eq "$parentPath\$serviceName\itwosite" }
                if (($configFile -ne $null) -and (Test-Path -Path $($configFile.FullName))) {
                    Copy-Item -Path $($configFile.FullName) -Destination "$($configFile.FullName).bak"
                }

                $jsonConfigsToEnter = $configsAsJson.$configFileName
                foreach ($jsonConfig in $jsonConfigsToEnter) {
                    $xmlNodesFromJson = $jsonConfig | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
                    foreach ($xmlNode in $xmlNodesFromJson) {
                        $elemToEnter = $configsAsJson.$configFileName.$xmlNode
                        foreach ($elem in $elemToEnter) {
                            if ($elem -ne $null) {
                                $tmp = convertJsonToHashtable -jsonObj $elem
                                switch ($configFileName) {
                                    "hibernate.cfg.xml" {
                                        ReplaceXML -path $($configFile.FullName) -xmlpath "$xmlNode[@name=`"$($tmp.Keys)`"]" -newValue $tmp.Values
                                        break;
                                    }
                                    "log4j2.xml" {
                                        ReplaceXML -path $($configFile.FullName) -xmlpath "$xmlNode[@name=`"$($tmp.Keys)`"]" -newValue $tmp.Values
                                        break;
                                    }
                                    "server.xml" {
                                        # if ($xmlNode -eq "Server/Service/Engine/Host/Valve") {
                                            ReplaceXML -path $($configFile.FullName) -xmlpath $xmlNode -attribute $($tmp.Keys) -newValue $tmp.Values
                                        # }
                                        # ReplaceXML -path $($configFile.FullName) -xmlpath "$xmlNode[@name=`"$($tmp.Keys)`"]" -newValue $tmp.Values
                                        break;
                                    }
                                    "context.xml" {
                                        [xml] $xmlConfig = Get-Content -Path $($configFile.FullName)
                                        if (!($xmlConfig.SelectSingleNode($xmlNode))) {
                                            $xmlConfig.Context.AppendChild($xmlConfig.CreateNode("element", "Resources", ""))
                                            $xmlConfig.Save($($configFile.FullName))
                                        }
                                        ReplaceXML -path $($configFile.FullName) -xmlpath $xmlNode -attribute $($tmp.Keys) -newValue $tmp.Values
                                        break;
                                    }
                                    Default {}
                                } # switch
                            }
                        } # foreach ($elem in $elemToEnter)
                    } # foreach ($xmlNode in $xmlNodesFromJson)
                } # foreach ($jsonConfig in $jsonConfigsToEnter)
            } # foreach ($configFileName in $configFileNames)
        }
    ### changeXML() Method ________________________________

    ### ReplaceXML() Method ********************************
        Function ReplaceXML {
            [CmdletBinding()]
            param (
                [String]$path,
                [String]$xmlpath,
                [String]$attribute,
                [String]$newValue
            )
            $Model = [xml]''
            $Model.Load($path)
            $node = SelectXMLNode -xml $Model -xmlpath $xmlpath
            if ($attribute) {
                Write-Verbose "Old: $($node.GetAttribute($attribute))"
                $node.SetAttribute($attribute, $newValue)
                Write-Verbose "New: $($node.GetAttribute($attribute))"
            }
            else {        
                Write-Verbose "Old $($node.InnerText)"
                $node.InnerText = $newValue
                Write-Verbose "New: $($node.InnerText)"
            }
            $Model.Save($path)
        }
    ### ReplaceXML() Method ________________________________

    ### SelectXMLNode() Method ********************************
        Function SelectXMLNode {
            [CmdletBinding()]
            Param(
                [xml]$xml, 
                [String]$xmlnamespace # would be xx for the following example        
                ,
                [String]$xmlpath # sth. like 'xx:DataSchemaModel/xx:Model/xx:Element/xx:Property[@Name="Collation"]'
            )
            $NameTable = $xml.Psbase.NameTable
            $mgr = new-object System.Xml.XmlNamespaceManager($NameTable)
            $mgr.AddNamespace($xmlnamespace, $xml.DocumentElement.NamespaceURI)
            $node = $xml.SelectNodes($xmlpath, $mgr)
            $node    
        }
    ### SelectXMLNode() Method ________________________________
        
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
        $binaryConfigs = Get-Content $filePath | ConvertFrom-StringData #-Delimiter '='
        $hashtable = @{}
        for ($i = 0; $i -lt $binaryConfigs.Length; $i++) {
            try { $hashtable.Add($binaryConfigs.Keys[$i], $binaryConfigs.Values[$i]) }
            catch { } #$counter++; Write-Host "$($i): $($binaryConfigs[$i].Keys)" }
        }
        return $hashtable
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
        
        if (Test-Path $outputFilePath) {
            Move-Item -Path $outputFilePath -Destination "$outputFilePath.bak"
        }

        foreach ($item in $binarConfig.GetEnumerator() | Sort-Object -Property Key) {
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
