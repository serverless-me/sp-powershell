Add-PSSnapin Microsoft.SharePoint.PowerShell

$spWeb = Get-SPWeb -Identity http://yourserver:44444/lernportal

$listCol = $spWeb.Lists
$contentList = $listCol["Contents"]

$contentItems = $contentList.getItems()

# Metadaten aus Excel abrufen
$excelConn = New-Object -ComObject "ADODB.Connection"
$file = "C:\Projekte\Sharepoint\ABC 2010\Lernportal-Skripte\Contents-Test.xlsx"
$excelConn.Open("Provider=Microsoft.ACE.OLEDB.12.0;Data Source="+$file+";Extended Properties=Excel 12.0;")
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