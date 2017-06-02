Add-PSSnapin Microsoft.SharePoint.PowerShell

# Sharepoint-Daten laden
$spWeb = Get-SPWeb -Identity http://yourserver:44444/lernportal

$listCol = $spWeb.Lists
$contentList = $listCol["Contents"]
$gruppenList = $listCol["Content-Gruppen"]

$contentItems = $contentList.getItems()
$gruppenItems = $gruppenList.getItems()

# Excelliste laden
$excelConn = New-Object -ComObject "ADODB.Connection"
$file = "C:\Projekte\Sharepoint\ABC 2010\Lernportal-Skripte\Contents-Test.xlsx"
$excelConn.Open("Provider=Microsoft.ACE.OLEDB.12.0;Data Source="+$file+";Extended Properties=Excel 12.0;")
$strQuery = "Select * from [Tabelle1$]"
$contentSet = $excelConn.Execute($strQuery)

$fields = $contentSet.Fields | Select-Object -Property Name

# Geh die Excel-Datei Zeile für Zeile durch
$contentSet.MoveFirst()
do{
	$obj = New-Object -TypeName PSObject
	$fields | ForEach-Object{
		$obj | Add-Member -MemberType NoteProperty -Name $_.Name -Value $contentSet.Fields.Item($_.Name).Value
	}
	$obj
	
	# Prüfe in jeder Zeile ob es ein Element in Contentgruppen gibt, das genauso heißt wie das Gruppenkürzel in dieser Zeile
	
	$aktGruppe = $gruppenItems | Where-Object {$_.Name -eq $obj.Gruppenkürzel}
	
	# WENN NEIN: Erzeuge ein neues Element, mit dem Namen des Gruppenkürzel
	if($aktGruppe -eq $null){
		$aktGruppe = $gruppenList.AddItem()
		$aktGruppe["Titel"] = $obj.Gruppenkürzel
		$aktGruppe.Update()
	}
	
	# In jedem Fall: Füge das Element aus Contents, das so heißt wie der Dateiname, der Contentgruppe hinzu, die genauso heißt wie das aktuelle Gruppenkürzel
	$lookupItem = $contentItems | Where-Object {$_.Name -eq $obj.Dateiname}
	if($lookupItem -isnot $null){
		$lookupVal = $lookupItem.ID + ";#" + $lookupItem.Title
		$aktGruppe.Fields["Contents"] += $lookupVal
	}
	
	$contentSet.MoveNext()
}until($contentSet.EOF)

$contentSet.Close()
$excelConn.Close()
$gruppenList.Update()
