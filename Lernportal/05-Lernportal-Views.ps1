# In jeder Bibliothek wird eine Ansicht für die Admins zur Verfügung gestellt (AllItems.aspx) und 
# eine Ansicht für die Ausbilder (Ausbilder.aspx), sowie eine Ansicht für die Teilnehmer (Teilnehmer.aspx).
# Der Zugriff der Teilnehmer erfolgt über Webpartseiten: Es gibt 2 Bibliotheken mit Webpartseiten (Ausbilder, 
# Teilnehmer) Die einzelnen Webpartseiten enthalten Ansichten der restlichen Bibliotheken.

# ============================
# === Ansichten customizen ===
# ============================
Start-SPAssignment -Global

$spWeb = Get-SPWeb -Identity http://yourserver:44444/lernportal
$spLists = $spWeb.Lists

$spListNames = "Links", "Skripte", "Übungen", "CAD-Zeichnungen", "Contents", "Content-Gruppen", "Bildungspakete"

foreach ($listname in $spListNames){
	$spList = $spLists[$listname]
	
	foreach ($view in $spList.Views) {
		if($view.url -like "*AllItems.aspx") { $spView = $view }
	}
	$spViewFields = $spView.ViewFields
	$spViewFields.DeleteAll()
	$spFieldNames = "DocIcon","Title"
    if ($listname -eq "Links") { $spFieldNames[1] = "Link" }
	if ($spList.BaseType -eq "DocumentLibrary"){ $spFieldNames += "FileSizeDisplay"}
    if ("Links", "Skripte", "Übungen", "CAD-Zeichnungen" -contains $listname) {$spFieldNames +=  "Freigabe"}
	if ($listname -eq "Skripte") {$spFieldNames += "_ModerationStatus"}
	$spFieldNames += "Author", "ID"
	foreach ($spFieldName in $spFieldNames) { 
		$spFields = $spList.Fields
		$spField = $spFields.GetFieldByInternalName($spFieldName)
		$spViewFields.Add($spField) 
	}
	$spView.Update()
	$spList.Update()
}
$listname = "Lerngruppen"
$spList = $spLists[$listname]
	
# ===================================
# AllItems-View anpassen
$spView = $spList.Views | Where-Object {$_.url -like "*AllItems.aspx"}
$spViewFields = $spView.ViewFields
$spViewFields.DeleteAll()
$spFieldNames = "Lerngruppensite", "Maßnahmenort","Teilnehmer","Aktiv","Author"
foreach ($spFieldName in $spFieldNames) { 
	$spFields = $spList.Fields
	$spField = $spFields.GetFieldByInternalName($spFieldName)
	$spViewFields.Add($spField) 
}
$spView.Update()
$spList.Update()

Stop-SPAssignment -Global
