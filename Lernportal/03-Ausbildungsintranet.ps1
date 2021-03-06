##############################################################################
##
## Installation Ausbildungsintranet
##
##############################################################################

<#

.DESCRIPTION
Installiert Listen, Bibliotheken und zugehörige Felder im Ausbildungsintranet

.PARAMETER url
Gibt die URL des Ausbildungsintranet an

.EXAMPLE
PS > .\Create-Ausbildungsintranet.ps1 http://yourserver:44444

#>
param([string]$url)

$snapin = Get-PSSnapin | where-Object {$_.Name -eq "Microsoft.SharePoint.PowerShell"}
if($snapin -eq $null){Add-PsSnapin Microsoft.SharePoint.PowerShell}

if((get-spweb $url) -eq $null){
	throw "Zu der angegebenen URL konnte keine Sharepoint-Website gefunden werden."
}
else{
	$spAssignment = Start-SPAssignment
	if(! $url.EndsWith("/")){$url += "/"}
	$spWeb = Get-SPWeb -Identity $url
	$url += "rehablog"
	
	# ABC M Blog als Unter-Website anlegen
	Write-Host "Rehablog anlegen"
	New-SPWeb -Url $url -Name "Bildungsinstitut Blog" -Template "BLOG#0" -Description "Ausbildungs- und Rehabilitandenblog des Berufsförderungswerk München" -AddToQuickLaunch -UseParentTopNav 

	# Benötigte Listen hinzufügen
	$newLists = 
	@{"Title"="Veranstaltungen";"Beschreibung"="Veranstaltungen im ABC";"Typ"=[Microsoft.SharePoint.SPListTemplateType]::Events},
	@{"Title"="Aufgaben";"Beschreibung"="Freigabe von Veranstaltungen";"Typ"=[Microsoft.SharePoint.SPListTemplateType]::Tasks},
	@{"Title"="Essensplan";"Beschreibung"="Der aktuelle Essensplan zum Download";"Typ"=[Microsoft.SharePoint.SPListTemplateType]::DocumentLibrary},
	@{"Title"="Stellenanzeigen";"Beschreibung"="Stellenanzeigen";"Typ"=[Microsoft.SharePoint.SPListTemplateType]::DocumentLibrary},
	@{"Title"="Links";"Beschreibung"="Hyperlinks zu externen Seiten";"Typ"=[Microsoft.SharePoint.SPListTemplateType]::Links}

	foreach ($newList in $newLists){
		Write-Host 'Liste "'+$newList.Title+'" anlegen'
		$spWeb.Lists.Add($newList.Title, $newList.Beschreibung, $newList.Typ) 
		$spList = $spWeb.Lists[$newList.Title]
		$spList.OnQuickLaunch = $true
		$spList.Update()
	}

	# Felder in Stellenanzeigen anlegen
	$stellenFields = 
	@{"Title"="Stellentitel";"FeldTyp"=[Microsoft.SharePoint.SPFieldType]::Text;"Beschreibung"="Geben Sie hier eine Bezeichnung für die Stellenanzeige ein."},
	@{"Title"="Branche";"FeldTyp"=[Microsoft.SharePoint.SPFieldType]::Text;"Beschreibung"="Geben Sie hier die Branchenbezeichnung ein, die für diese Stelle zutrifft."},
	@{"Title"="Tätigkeit der Stelle";"FeldTyp"=[Microsoft.SharePoint.SPFieldType]::Note;"Beschreibung"="Beschreiben Sie hier die Tätigkeit der Stelle."},
	@{"Title"="Eintrittstermin";"FeldTyp"=[Microsoft.SharePoint.SPFieldType]::DateTime;"Beschreibung"="Geben Sie hier das Datum ein, ab dem diese Stelle besetzt wird."},
	@{"Title"="Ort";"FeldTyp"=[Microsoft.SharePoint.SPFieldType]::Text;"Beschreibung"="Geben Sie hier den Ort der Stelle ein."}

	$spList = $spWeb.Lists["Stellenanzeigen"]
	foreach ($field in $stellenFields) {
		Write-Host 'Feld "'+$field.Title+'" in "Stellenanzeigen" anlegen'
	    $spList.Fields.Add($field.Title,$field.FeldTyp, $false)
	    $spField = $spList.Fields[$field.Title]
	    $spField.Description = $field.Beschreibung
	    $spField.ShowInEditForm = $true;
	    $spField.ShowInDisplayForm = $true;
	    $spField.ShowInNewForm = $true;
	    $spField.Update()
	}
	$spList.Update()

	# Zielgruppe in Veranstaltungen ergänzen / ausblenden
	Write-Host 'Feld "Zielgruppe" in "Veranstaltungen" anlegen'
	$spList = $spWeb.Lists["Veranstaltungen"]
	$spList.Fields.Add("Zielgruppe",[Microsoft.SharePoint.SPFieldType]::Note, $false)
	$spField = $spList.Fields["Zielgruppe"]
	$spField.Description = "Beschreiben Sie, an wen sich die Veranstaltunge richtet.";
	$spField.ShowInEditForm = $true;
	$spField.ShowInDisplayForm = $true;
	$spField.ShowInNewForm = $true;
	$spField.Update()

	$spField = $spList.Fields["Arbeitsbereich"]
	Write-Host 'Feld "Arbeitsbereich" in "Veranstaltungen" ausblenden'
	$spField.Hidden = $true
	$spField.Update()
	$spList.Update()

	# Items in der Link-Liste anlegen

	$spList = $spWeb.Lists["Links"]
	Write-Host 'Items in "Links" anlegen'
	$spItem = $spList.AddItem()
	$spItem["URL"] = "http://www.Beispiel-Agentur.de, Beispiel-Agentur"
	$spItem.Update()
	$spItem = $spList.AddItem()
	$spItem["URL"] = "http://www.Beispiel-Bildungsinstitut.de, Beispiel-Bildungsinstituts"
	$spItem.Update()
	$spItem = $spList.AddItem()
	$spItem["URL"] = "http://www.Beispiel-Verbund.de, Beispiel-Verbund"
	$spItem.Update()
	$spList.Update()

	Write-Host 'Installation Ausbildungsintranet abgeschlossen'
	Stop-SPAssignment $spAssignment
}