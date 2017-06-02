# Benötigte Listen definieren
# Übungsaufgaben und Lerngruppen im 3 Prototyp nicht mehr enthalten
$listHashtable = 
@{"Title"="Skripte";"Description"="Skripte können von Ausbildern erstellt werden, anderen freigegeben und in Lerngruppen verwendet werden";"ListType"=$libTemplate},
@{"Title"="Übungen";"Description"="Übungen können von Ausbildern erstellt werden, anderen freigegeben und in Lerngruppen verwendet werden";"ListType"=$libTemplate},
@{"Title"="CAD-Zeichnungen";"Description"="CAD-Zeichnungen können von Ausbildern erstellt werden, anderen freigegeben und in Lerngruppen verwendet werden";"ListType"=$libTemplate},
@{"Title"="Contents";"Description"="E-Learning Contents können hier verwaltet werden und in Lerngruppen wiederverwendet werden";"ListType"=$libTemplate},
@{"Title"="Links";"Description"="Links können von Ausbildern erstellt werden, anderen freigegeben und in Lerngruppen verwendet werden";"ListType"=$linkTemplate},
@{"Title"="Übungsaufgaben";"Description"="Werden Übungsaufgaben in einer Lerngruppe verwendet, dann wird für jeden Teilnehmer der Lerngruppe eine separate Aufgabe erstellt";"ListType"=$taskTemplate},
#@{"Title"="Lerngruppen";"Description"="In Lerngruppen werden Ausbildungsinhalte und Rehabilitanden verwaltet";"ListType"=$listTemplate},
@{"Title"="Content-Gruppen";"Description"="Content-Gruppen stellen ein wiederverwendbares Element dar und fassen mehrere Contents zu einer Gruppe zusammen";"ListType"=$listTemplate},
@{"Title"="Bildungspakete";"Description"="Bildungspakete stellen ein wiederverwendbares Element dar und fassen unterschiedliche Ausbildungsinhalte oder Content-Gruppen zusammen";"ListType"=$listTemplate}

$spWeb = Get-SPWeb -Identity http://yourserver:24816/lernportal3
$spListCollection = $spWeb.Lists
$spFieldType = [Microsoft.SharePoint.SPFieldType]::User
$listlist = "Skripte","Übungen","CAD-Zeichnungen","Links"
foreach ($list in $listlist) { 
 	$spList = $spListCollection[$list]
	$spList.Fields.Add("Lerngruppen",$spFieldType, $false)
	$spField = $spList.Fields["Lerngruppen"]
	$spField.Description = "Lerngruppen, die Zugriff auf das Dokument haben."
	$spField.ShowInEditForm = $false
	$spField.AllowMultipleValues = $true
	$spField.SelectionMode =  [Microsoft.SharePoint.SPFieldUserSelectionMode]::PeopleAndGroups
	$spField.Update()
}

