##############################################################################
##
## Installation der Lernportal-Website
##
##############################################################################

<#

.DESCRIPTION
Creates a Lernportal-Subsite under the specified root-url and creates all lists
and libraries, fields and lookups, configures the visibility of fields in forms and
configures versioning.

.PARAMETER url
Specifies the URL of the Root-Website, where Lernportal will be installed as subwebsite

.EXAMPLE
PS > .\Create-Lernportal.ps1 http://yourserver:44444

#>
param([string]$url)

$snapin = Get-PSSnapin | where-Object {$_.Name -eq "Microsoft.SharePoint.PowerShell"}
if($snapin -eq $null){Add-PsSnapin Microsoft.SharePoint.PowerShell}

function Update-Progress ($currentOperation)
{
	if($total -le ($perc+1)){$total = $perc+1}
	$sounter = (++$perc)/$total*100
	Write-Progress "Installation von Listen und Bibliotheken" "Installation" -PercentComplete $counter -CurrentOperation $currentOperation
}

$perc = 0
$total = 55
if((get-spweb $url)-eq $null){
	throw "Zu der angegebenen URL konnte keine Sharepoint-Website gefunden werden."
}
else{
	Update-Progress ('Installation starten')
	if(! $url.EndsWith("/")){$url += "/"}
	$url += "lernportal"

	# Lernportal als Unter-Website anlegen
	Update-Progress  ('Website "Lernportal" erstellen')
	New-SPWeb -Url $url -Name "Lernportal" -Template "STS#1" -Description "Lernportal des Bildungsinstituts" -UseParentTopNav -AddToTopNav
	$spWeb = Get-SPWeb $url


	# Zugriff auf die Listen der Website bereitstellen
	$spListCollection = $spWeb.Lists

	# Verwendete ListTypes definieren
	$libTemplate = $spWeb.ListTemplates | Where-Object{$_.Type -eq "DocumentLibrary"}
	$linkTemplate = $spWeb.ListTemplates | Where-Object{$_.Type -eq "Links"}
	$taskTemplate = $spWeb.ListTemplates | Where-Object{$_.Type -eq "Tasks"}
	$listTemplate = $spWeb.ListTemplates | Where-Object{$_.Type -eq "GenericList"}

	# Benötigte Listen definieren
	# Übungsaufgaben und Lerngruppen im 3 Prototyp nicht mehr enthalten
	$listHashtable = 
	@{"Title"="Skripte";"Description"="Skripte können von Ausbildern erstellt werden, anderen freigegeben und in Lerngruppen verwendet werden";"ListType"=$libTemplate},
	@{"Title"="Übungen";"Description"="Übungen können von Ausbildern erstellt werden, anderen freigegeben und in Lerngruppen verwendet werden";"ListType"=$libTemplate},
	@{"Title"="CAD-Zeichnungen";"Description"="CAD-Zeichnungen können von Ausbildern erstellt werden, anderen freigegeben und in Lerngruppen verwendet werden";"ListType"=$libTemplate},
	@{"Title"="Contents";"Description"="E-Learning Contents können hier verwaltet werden und in Lerngruppen wiederverwendet werden";"ListType"=$libTemplate},
	@{"Title"="Links";"Description"="Links können von Ausbildern erstellt werden, anderen freigegeben und in Lerngruppen verwendet werden";"ListType"=$listTemplate},
	@{"Title"="Content-Gruppen";"Description"="Content-Gruppen stellen ein wiederverwendbares Element dar und fassen mehrere Contents zu einer Gruppe zusammen";"ListType"=$listTemplate},
	@{"Title"="Bildungspakete";"Description"="Bildungspakete stellen ein wiederverwendbares Element dar und fassen unterschiedliche Ausbildungsinhalte oder Content-Gruppen zusammen";"ListType"=$listTemplate}

	# Liste der Lerngruppen anlegen und Link zu Lerngruppensite und Teilnehmerfeld hinzufügen
	Update-Progress ('Liste "Lerngruppen" hinzufügen')
	$spWeb.Lists.Add("Lerngruppen", "In Lerngruppen werden Ausbildungsinhalte und Rehabilitanden verwaltet",$listTemplate) 
	
	Update-Progress ('Feld "Titel" in Liste "Lerngruppen" konfigurieren')
	$spList = $spWeb.Lists["Lerngruppen"]
	$spList.OnQuickLaunch = $false
	$spList.EnableFolderCreation = $false
	$spField = $spList.Fields["Titel"]
	$spField.Description = "Das Anlegen einer Lerngruppe kann bis zu einer Minute dauern. Laden Sie die Seite anschließend mit F5 neu."
	$spField.ShowInEditForm = $false;
	$spField.ShowInDisplayForm = $true;
	$spField.ShowInNewForm = $false;
	$spField.EnforceUniqueValues = $true
	$spField.Update()

	Update-Progress ('Feld "Lerngruppensite" in Liste "Lerngruppen" konfigurieren')
	$spList.Fields.Add("Lerngruppensite",[Microsoft.SharePoint.SPFieldType]::URL, $false)
	$spField = $spList.Fields["Lerngruppensite"]
	$spField.Description = "Die Lerngruppensite ist die Homepage, die die Teilnehmer und Ausbilder der Lerngruppe gemeinsam nutzen.";
	$spField.ShowInEditForm = $false;
	$spField.ShowInDisplayForm = $true;
	$spField.ShowInNewForm = $false;
	$spField.Update()

	Update-Progress ('Feld "Maßnahmenort" in Liste "Lerngruppen" konfigurieren')
	$spChoices = New-Object System.Collections.Specialized.StringCollection
	$spChoices.Add("Rehazentrum")
	$spChoices.Add("Geschäftsstelle")
	$spFieldType = [Microsoft.SharePoint.SPFieldType]::Choice
	$spList.Fields.Add("Maßnahmenort",$spFieldType, $true, $false, $spChoices)
	$spField = $spList.Fields["Maßnahmenort"]
	$spField.Description = "Die Angabe des Maßnahmenortes (Rehazentrum oder Außenstelle) ermöglicht die getrennte Auswertung der Daten";
	$spField.EditFormat = "Dropdown"
	$spField.ShowInEditForm = $true;
	$spField.ShowInDisplayForm = $true;
	$spField.ShowInNewForm = $true;
	$spField.Update()
		
	Update-Progress ('Feld "Teilnehmer" in Liste "Lerngruppen" konfigurieren')
	$spList.Fields.Add("Teilnehmer",[Microsoft.SharePoint.SPFieldType]::User, $false)
	$spField = $spList.Fields["Teilnehmer"]
	$spField.Description = "Die Teilnehmer, die in dieser Lerngruppe mitarbeiten.";
	$spField.AllowMultipleValues = $true
	$spField.SelectionMode =  [Microsoft.SharePoint.SPFieldUserSelectionMode]::PeopleOnly
	$spField.ShowInEditForm = $true;
	$spField.ShowInDisplayForm = $true;
	$spField.ShowInNewForm = $true;
	$spField.Update()

	Update-Progress ('Liste "Lerngruppen" mit Server synchronisieren')
	$spList.Update()
	$lgLookupID = $spList.ID
		
	foreach ($list in $listHashtable) { 
		Update-Progress ('Liste "'+$list.Title+'" hinzugefügen')
		$spListCollection.Add($list.Title, $list.Description,$list.ListType) 
		$spList = $spWeb.Lists[$list.Title]
		$spList.OnQuickLaunch = $true
	    $spList.EnableFolderCreation = $false
		
		# Ausbildungsrichtung: kaufmännisch, gewerblich-technisch, Bau - Mehrfachauswahl, Pflichtfeld

		Update-Progress ('Feld "Ausbildungsrichtung" in Liste "'+$list.Title+'" konfigurieren')
		$spChoices = New-Object System.Collections.Specialized.StringCollection
		$spChoices.Add("kaufmännisch")
		$spChoices.Add("gewerblich-technisch")
		$spChoices.Add("Bau")
		$spChoices.Add("übergreifend")
		$spFieldType = [Microsoft.SharePoint.SPFieldType]::Choice
		$spList.Fields.Add("Ausbildungsrichtung",$spFieldType, $true, $false, $spChoices)
		$spField = $spList.Fields["Ausbildungsrichtung"]
		$spField.Description = "Die Ausbildungsrichtung gibt an aus welchem Bereich der Ausbildungsinhalt stammt: kaufmännisch, gewerblich-technisch oder Bau";
		$spField.EditFormat = "RadioButtons"
		$spField.ShowInEditForm = $true;
	    $spField.ShowInDisplayForm = $true;
	    $spField.ShowInNewForm = $true;
		$spField.Update()

		# Beschreibung - Text - optional
		Update-Progress ('Feld "Beschreibung" in Liste "'+$list.Title+'" konfigurieren')
		$spList.Fields.Add("Beschreibung",[Microsoft.SharePoint.SPFieldType]::Note, $false)
		$spField = $spList.Fields["Beschreibung"]
		$spField.Description = "Die Beschreibung gibt Aufschluss über Inhalt und Umfang eines Ausbildungsinhalts";
		$spField.ShowInEditForm = $true;
	    $spField.ShowInDisplayForm = $true;
	    $spField.ShowInNewForm = $true;
		$spField.Update()

		# Lookup für Lerngruppen hinzufügen
		Update-Progress ('Feld "Lerngruppen" in Liste "'+$list.Title+'" konfigurieren')
		$spList.Fields.AddLookUp("Lerngruppen", $lgLookupID, $true)
		$spField = $spList.Fields["Lerngruppen"]
		$spField.Description = "Lerngruppen, in denen der Ausbildungsinhalt verwendet wird.";
		$spField.ShowInEditForm = $false;
	    $spField.ShowInDisplayForm = $true;
	    $spField.ShowInNewForm = $false;
		$spField.AllowMultipleValues = $true
		$spField.Required = $false
		$spField.Update()
		
	    if ($list.Title -like "Skripte" -or $list.Title -like "Übungen" -or $list.Title -like "CAD-Zeichnungen" -or $list.Title -like "Links") 
	    {
			Update-Progress ('Feld "Freigabe" in Liste "'+$list.Title+'" konfigurieren')
	      	$spList.Fields.Add("Freigabe",[Microsoft.SharePoint.SPFieldType]::Boolean, $false)
		   	$spField = $spList.Fields["Freigabe"]
		   	$spField.Description = "Eine Freigabe bedeutet, dass das Dokument von anderen Ausbildern in Lerngruppen verwendet werden kann.";
		   	$spField.ShowInEditForm = $false;
	       	$spField.ShowInDisplayForm = $true;
	       	$spField.ShowInNewForm = $true;
		   	$spField.Update()
	    }
	    
		$spList.Update()
	}

	# Lizenzpflicht (nur Contents) - Boolean
	Update-Progress ('Feld "Lizenzpflicht" in Liste "Contents" konfigurieren')
	$spList = $spWeb.Lists["Contents"]
	$spList.Fields.Add("Lizenzpflicht",[Microsoft.SharePoint.SPFieldType]::Boolean, $false)
	$spField = $spList.Fields["Lizenzpflicht"]
	$spField.Description = "Die Lizenzpflicht gibt an, ob für einen E-Learning Content eine Lizenzgebühr pro Benutzer gezahlt werden muss.";
	$spField.DefaultValue = $true;
	$spField.ShowInEditForm = $false;
	$spField.ShowInDisplayForm = $false;
	$spField.ShowInNewForm = $true;
	$spField.Update()

	# Lookup-Felder definieren
	$lookupHashtable = 
	@{"ID"=$spWeb.Lists["Contents"].ID;"FieldName"="Contents";"Description"="Hier können E-Learning Contents hinzugefügt werden"},
	@{"ID"=$spWeb.Lists["Skripte"].ID;"FieldName"="Skripte";"Description"="Hier können Skripte hinzugefügt werden"},
	@{"ID"=$spWeb.Lists["Übungen"].ID;"FieldName"="Übungen";"Description"="Hier können Übungen hinzugefügt werden"},
	@{"ID"=$spWeb.Lists["Links"].ID;"FieldName"="Links";"Description"="Hier können Links hinzugefügt werden"},
	@{"ID"=$spWeb.Lists["CAD-Zeichnungen"].ID;"FieldName"="CAD-Zeichnungen";"Description"="Hier können CAD-Zeichnungen hinzugefügt werden"},
	@{"ID"=$spWeb.Lists["Content-Gruppen"].ID;"FieldName"="Content-Gruppen";"Description"="Hier können Content-Gruppen hinzugefügt werden"}

	# in Bildungspakete (& Lerngruppen) einfügen
	$listArray = "Bildungspakete"
	foreach ($lookup in $lookupHashtable){
			foreach ($listname in $listArray){
				Update-Progress ('Feld "'+$lookup.FieldName+'" in Liste "'+$listname+'" konfigurieren')
				$spList = $spWeb.Lists[$listname]
				$spList.Fields.AddLookUp($lookup.FieldName, $lookup.ID, $false)
				$spField = $spList.Fields[$lookup.FieldName]
				$spField.Description = $lookup.Description;
		        $spField.ShowInEditForm = $true;
	            $spField.ShowInDisplayForm = $true;
	            $spField.ShowInNewForm = $true;
				$spField.AllowMultipleValues = $true
				$spField.Update()
	 		}
	}

	# Content-Lookup in Content-Gruppen
	Update-Progress ('Feld "'+$lookupHashtable[0].FieldName+'" in Liste "Content-Gruppen" konfigurieren')
	$spList = $spWeb.Lists["Content-Gruppen"]
	$spList.Fields.AddLookUp($lookupHashtable[0].FieldName, $lookupHashtable[0].ID, $false)
	$spField = $spList.Fields[$lookupHashtable[0].FieldName]
	$spField.Description = $lookupHashtable[0].Description;
	$spField.ShowInEditForm = $true;
	$spField.ShowInDisplayForm = $true;
	$spField.ShowInNewForm = $true;
	$spField.AllowMultipleValues = $true
	$spField.Update()

	# Set Versioning
	$library = "Skripte", "Übungen", "CAD-Zeichnungen", "Contents"

	foreach ($list in $library){
		Update-Progress ('Verwaltung von Content-Types und Versionierung in Liste "'+$list+'" aktivieren')
		$spList = $spWeb.Lists[$list]
		$spList.IsContentTypeAllowed = $true
		$spList.EnableVersioning = $true
		$spList.EnableMinorVersions = $true	
		$spList.Update()
	}

	$majorversions = "Links", "Content-Gruppen", "Bildungspakete"
	foreach ($list in $majorversions){
		Update-Progress ('Versionierung in Liste "'+$list+'" aktivieren')
		$spList = $spWeb.Lists[$list]
		$spList.EnableVersioning = $true
		$spList.EnableMinorVersions = $false	
		$spList.Update()
	}
	Update-Progress (100, 'Installation von Lernportal abgeschlossen')
}
