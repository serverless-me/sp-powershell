##############################################################################
##
## Methadaten zu Excel-Contents hinzufügen
##
##############################################################################

<#

.DESCRIPTION
Das Skript fügt die Metadaten gemäß der Excelliste in der Bibliothek der Contents hinzu

.PARAMETER url
Die URL gibt die Website an, auf der sich die Liste "Contents" befindet

.PARAMETER path
Der Pfad gibt Pfad und Dateinamen der Excel-Datei an

.EXAMPLE

#>
param([string]$url, [string]$path)

$snapin = Get-PSSnapin | where-Object {$_.Name -eq "Microsoft.SharePoint.PowerShell"}
if($snapin -eq $null){Add-PsSnapin Microsoft.SharePoint.PowerShell}

$spWeb = Get-SPWeb -Identity $url

$listCol = $spWeb.Lists
$contentList = $listCol["Contents"]

# Neue Spalten erstellen (Kürzel, Hinweis)
$contentList.Fields.Add("Kürzel",[Microsoft.SharePoint.SPFieldType]::Text, $false)
$spField = $contentList.Fields["Kürzel"]
$spField.ShowInEditForm = $true;
$spField.ShowInDisplayForm = $true;
$spField.ShowInNewForm = $true;
$spField.Update()

$contentList.Fields.Add("Hinweis",[Microsoft.SharePoint.SPFieldType]::Note, $false)
$spField = $contentList.Fields["Hinweis"]
$spField.Description = "Der Hinweis enthält zusätzliche Informationen zum Content (z.B. Systemvoraussetzungen etc.)";
$spField.ShowInEditForm = $true;
$spField.ShowInDisplayForm = $true;
$spField.ShowInNewForm = $true;
$spField.Update()

$contentItems = $contentList.getItems()

# Metadaten aus Excel abrufen
$excelConn = New-Object -ComObject "ADODB.Connection"
$excelConn.Open("Provider=Microsoft.ACE.OLEDB.12.0;Data Source="+$path+";Extended Properties=Excel 12.0;")
$strQuery = "Select * from [Tabelle1$]"
$contentSet = $excelConn.Execute($strQuery)

$fields = $contentSet.Fields | Select-Object -Property Name

# Contents aus Excel mit Dateinamen in SP vergleichen und Werte setzen
$contentSet.MoveFirst()

do{
	$obj = New-Object -TypeName PSObject
	$fields | ForEach-Object{
		$obj | Add-Member -MemberType NoteProperty -Name $_.Name -Value $contentSet.Fields.Item($_.Name).Value
	}
	$obj
	
	foreach($contentItem in $contentItems){
	
		if($contentItem["Name"] -eq $obj.Dateiname){
			#$spFile = $spWeb.GetFile("Contents/"+$contentItem["Name"])
			#$spFile.CheckOut()
			$contentItem["Title"] = $obj.Titel
			$contentItem["Kürzel"] = $obj.Kürzel
			$contentItem["Hinweis"] = $obj.Hinweis
			$contentItem["Ausbildungsrichtung"] = $obj.Ausbildungsrichtung
			$contentItem.Update()
			#$spFile.CheckIn("CheckIn Using PowerShell")
		}
		
	}
	$contentSet.MoveNext()
}until($contentSet.EOF)

$contentSet.Close()
$excelConn.Close()
$contentList.Update()