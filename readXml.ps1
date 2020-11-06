<##########################################################
# Autor: AMI
# Datum: 03.11.2020
#
# BESCHREIBUNG
#
# INFO
#
##########################################################>












Function SelectXMLNode {
    [CmdletBinding()]
    Param(
        [String]$xml, 
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
Function ReplaceInsideBacPacXML {
    [CmdletBinding()]
    Param(
        [String]$bacpac, 
        [String]$filename, 
        [String]$xmlnamespace,
        [String]$xmlpath,
        [String]$attribute,
        [String]$newValue
    )
    # Get file from zip
    $zip = $null
    if (Test-Path $bacpac -PathType Leaf) {
        $zip = [System.IO.Compression.ZipFile]::Open($bacpac, "Update")
    }
    else {
        Throw "`"$bacpac`" does not exist."
    }
    
    $files = $zip.Entries | Where-Object { $_.name -like $filename }
    
    if ($files) {
        # Get text from file
        $file = [System.IO.StreamReader]($files).Open()
        $text = $file.ReadToEnd()
        $xml = [xml]($text)
   
        $node = SelectXMLNode -xml $xml `
            -xmlnamespace $xmlnamespace `
            -xmlpath $xmlpath
        $node.SetAttribute($attribute, $newValue)                
        Write-Verbose "Set $attribute in $xmlpath to $newValue."
        $xml.Save($file)
        # Write file back to zip
        $file.Close()
        $file.Dispose()
        $zip.Dispose()
    }
    else {        
        $zip.Dispose()
        throw ("`"$file`" not found inside $bacpac")        
    }        
}