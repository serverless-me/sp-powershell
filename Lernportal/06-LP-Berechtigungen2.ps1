function Main{
	try{
		$root = Read-Host "Bitte geben Sie die URL der Root-Website an:"
		$spweb = Get-SPWeb $root
		
		if($root.EndsWith("/")){$root.Remove($root.Length-1,1)}
		Set-LPGroups
		Set-LPRoleDefinitions
		Delete-RoleInheritance
		$path = Read-Host "Bitte geben Sie den vollständigen Pfad der CSV-Datei mit den Berechtigungen an (Bsp. C:\Files\Berechtigungen.csv):"
		$permissions = Import-Csv -Path $path -Delimiter ";"
		Delete-RoleInheritence
		foreach($perm in $permissions){
			Set-LPRoleAssignments $perm
		}
	}
	catch [SPCmdletPipeBindException]{
		Write-Error $error[0].Exception
	}
	catch [FileNotFoundException]{
		Write-Error $error[0].Exception
	}
	catch [Exception]{
		Write-Error $error[0].Exception
	}
	finally{
		Write-Warning "Das Anlegen der Berechtigungen wurde abgebrochen."
	}
}
# ===================
# = Gruppen anlegen =
# ===================
function Set-LPGroups {
	try{
		$spgroups = $spWeb.SiteGroups
		$owner = $spWeb.SiteGroups["Besitzer von Ausbildungsintranet"]
		# Site-Collection
		$spWeb.SiteGroups.Add("ABC-User",$owner, $defUser, "Alle Benutzer, die im ABC über einen Zugang verfügen, sollen auch auf das Ausbildungsintranet zugreifen können.")
		$spWeb.SiteGroups.Add("Lernportal-Manager",$owner, $null, "Die Lernportal-Manager verwalten die Mitgliedschaft in den Gruppen")
		
		$owner = $spWeb.SiteGroups["Lernportal-Manager"]

		# Ausbildungsintranet
		$spWeb.SiteGroups.Add("Veranstaltungs-Genehmiger",$owner, $null, "Mitglieder dieser Gruppe können Veranstaltungen genehmigen.")
		$spWeb.SiteGroups.Add("Veranstaltungs-Ersteller",$owner, $null, "Mitglieder dieser Gruppe können Veranstaltungen erstellen.")
		$spWeb.SiteGroups.Add("Blog-Moderatoren",$owner, $null, "Mitglieder dieser Gruppe können Blog-Einträge verwalten.")
		$spWeb.SiteGroups.Add("Kueche",$owner, $null, "Mitglieder dieser Gruppe können Essenspläne verwalten.")
		$spWeb.SiteGroups.Add("Stellenanzeigen-Verwaltung",$owner, $null, "Mitglieder dieser Gruppe können Stellenanzeigen einscannen und verwalten.")

		# Lernportal
		$spWeb.SiteGroups.Add("Ausbilder Gesamt",$owner, $null, "Ausbilder haben Zugriff auf das Lernportal, Lerngruppensites und darin enthaltene Bibliotheken und Listen.")
		$spWeb.SiteGroups.Add("Teilnehmer Gesamt",$owner, $null, "Ausbilder haben Zugriff auf  Lerngruppensites und einzelne Dokumente in den Bibliotheken und Listen.")
		$spWeb.SiteGroups.Add("Lerngruppen-Koordinatoren",$owner, $null, "Lerngruppen-Koordinatoren haben besondere Berechtigungen zum Erstellen von Lerngruppen, Content-Gruppen und Bildungspaketen")
		$spWeb.SiteGroups.Add("Skript-Genehmiger",$owner, $null, "Skript-Genehmiger können Skripte genehmigen.")
		
		Write-Host "ABC-User, Lernportal-Manager, Veranstaltungs-Genehmiger, Veranstaltungs-Ersteller, Blog-Moderatoren, Küche, Stellenanzeigen-Verwaltung, Ausbilder Gesamt, Teilnehmer Gesamt, Lerngruppen-Koordinatoren, Skript-Genehmiger erfolgreich angelegt."
	}
	catch [MethodInvocationException]{
		Write-Error $error[0].Exception
	}
	catch [Exception]{
		Write-Error $error[0].Exception
	}
	finally{
		Write-Warning "Das Anlegen der Gruppen wurde abgebrochen."
	}
}


# ===========================
# = Roledefinitions anlegen =
# ===========================
function Set-LPRoleDefinitions{
	[System.Collections.ArrayList]$roles = 
	@{"Name"="Vollzugriff";"Description"="Verwaltung von Websites, Listen und Items";"BasePermissions"="
	ManageLists,
	CancelCheckout,
	AddListItems,
	EditListItems,
	DeleteListItems,
	ViewListItems,
	ApproveItems,
	OpenItems,
	ViewVersions,
	DeleteVersions,
	CreateAlerts,
	ViewFormPages,
	ManagePermissions,
	ViewUsageData,
	ManageSubwebs,
	ManageWeb,
	AddAndCustomizePages,
	ApplyThemeAndBorder,
	ApplyStyleSheets,
	CreateGroups,
	BrowseDirectories,
	CreateSSCSite,
	ViewPages,
	EnumeratePermissions,
	BrowseUserInfo,
	ManageAlerts,
	UseRemoteAPIs,
	UseClientIntegration,
	Open,
	EditMyUserInfo"}, 
	@{"Name"="Entwerfen";"Description"="Erstellen von Unterwebsites und Verwaltung von Berechtigungen auf Lerngruppensites";"BasePermissions"="
	ManageLists,
	CancelCheckout,
	AddListItems,
	EditListItems,
	DeleteListItems,
	ViewListItems,
	ApproveItems,
	OpenItems,
	ViewVersions,
	DeleteVersions,
	CreateAlerts,
	ViewFormPages,
	ManagePermissions,
	ManageSubwebs,
	AddAndCustomizePages,
	ApplyThemeAndBorder,
	ApplyStyleSheets,
	BrowseDirectories,
	CreateSSCSite,
	ViewPages,
	EnumeratePermissions,
	BrowseUserInfo,
	ManageAlerts,
	UseRemoteAPIs,
	UseClientIntegration,
	Open"},
	@{"Name"="Mitwirken";"Description"="Bearbeiten-Berechtigung auf Item-Ebene";"BasePermissions"="
	AddListItems,
	EditListItems,
	ViewListItems,
	OpenItems,
	ViewVersions,
	DeleteVersions,
	CreateAlerts,
	ViewFormPages,
	ViewPages,
	BrowseUserInfo,
	UseClientIntegration,
	Open"},
	@{"Name"="Erstellen";"Description"="Erstellen von Einträgen in Blogs etc. und Öffnen von Elementen anderer User";"BasePermissions"="
	AddListItems,
	ViewListItems,
	OpenItems,
	CreateAlerts,
	ViewFormPages,
	ViewPages,
	BrowseUserInfo,
	Open"},
	@{"Name"="AusbildungsInhalte erstellen";"Description"="Erstellen neuer Elemente und Anzeigen anderer Elemente";"BasePermissions"="
	AddListItems,
	ViewListItems,
	ViewFormPages,
	ViewPages,
	Open"},
	@{"Name"="Lesen";"Description"="Öffnen und Herunterladen von Elementen";"BasePermissions"="
	OpenItems,
	ViewVersions,
	CreateAlerts,
	ViewFormPages,
	ViewPages,
	UseRemoteAPIs,
	UseClientIntegration,
	Open"},
	@{"Name"="Items anzeigen";"Description"="Anzeigen von Elementen";"BasePermissions"="
	ViewListItems,
	ViewVersions,
	ViewFormPages,
	ViewPages,
	UseClientIntegration,
	Open"},
	@{"Name"="Seite anzeigen";"Description"="Eine Webseite öffnen";"BasePermissions"="
	ViewPages,
	Open"},
	@{"Name"="Veranstaltungs-Genehmigung";"Description"="Verwalten und genehmigen von Veranstaltungen";"BasePermissions"="
	AddListItems,
	EditListItems,
	DeleteListItems,
	ViewListItems,
	ApproveItems,
	OpenItems,
	ViewVersions,
	ViewPages,
	Open"},
	@{"Name"="Skript-Genehmigung";"Description"="Öffnen und genehmigen von Skripten";"BasePermissions"="
	ViewListItems,
	ApproveItems,
	OpenItems,
	ViewVersions,
	ViewPages,
	Open"},
	@{"Name"="Gruppen-Verwaltung";"Description"="Öffnen der Website und Verwaltung der User und Gruppen";"BasePermissions"="
	ManagePermissions,
	ViewPages,
	Open"}

	for($i=0;$i -lt $roles.Count;$i++){
		$roleDef = $spWeb.RoleDefinitions[$roles[$i].Name]
		if($roleDef -eq $null){
			$roleDef = New-Object Microsoft.SharePoint.SPRoleDefinition
			$roleDef.Name = $roles[$i].Name
			$roleDef.Description = $roles[$i].Description
            $spWeb.RoleDefinitions.Add($roleDef)
		    $roleDef = $spWeb.RoleDefinitions[$roles[$i].Name]
		}
		$roleDef.BasePermissions = $roles[$i].BasePermissions
        $roleDef.Update()
		Write-Host "Berechtigungsstufe "$roles[$i].Name" erfolgreich angepasst"
	}
}

function Delete-RoleInheritance {
	try{
		# Ausbildungsintranet
		$spWeb = Get-SPWeb $root
		#$spWeb.BreakRoleInheritance($false)
		$spWeb.Update()
		$lpLists = "Essensplan","Stellenanzeigen","Veranstaltungen","Links"
		foreach ($lpList in $lpLists){
			$splist = $spWeb.Lists[$lpList]
			$splist.BreakRoleInheritance($false)
			$splist.Update()
		}
		Write-Host "Vererbung von Rollen im Ausbildungsintranet unterbrochen"
		# Rehablog
		$spWeb = Get-SPWeb $root"/rehablog"
		$spWeb.BreakRoleInheritance($false)
		$spWeb.Update()
		Write-Host "Vererbung von Rollen im Rehablog unterbrochen"
		# Lernportal
		$spWeb = Get-SPWeb $root"/lernportal"
		$spWeb.BreakRoleInheritance($false)
		$spWeb.Update()
		$lpLists = "Bildungspakete","CAD-Zeichnungen","Content-Gruppen","Contents","Lerngruppen","Links","Skripte","Übungen"
		foreach ($lpList in $lpLists){
			$splist = $spWeb.Lists[$lpList]
			$splist.BreakRoleInheritance($false)
			$splist.Update()
		}
		Write-Host "Vererbung von Rollen im Lernportal unterbrochen"
	}
	catch [Exception]{
		Write-Error $Error[0].Exception
	}
	finally {
		Write-Warning "Fehler beim Unterbrechen der Berechtigungen"
	}
}


# ===========================
# = Roleassignments anlegen =
# ===========================
function Set-LPRoleAssignments ($perm){
		try{
			# Instantiate the correct Web
			$objStr = $perm.LPObject
			if($objStr.StartsWith("/lernportal")){
				$url = $root + "/lernportal"
				$objStr = $objStr.Remove(0,11)
			}elseif($objStr.StartsWith("/rehablog")){
				$url = $root + "/rehablog"
				$objStr = $objStr.Remove(0,9)
			}else{
				$url = $root
			}
			$spWeb = Get-SPWeb $url
			
			# Instantiate $lpObj as Web, List or Lib
			if ($objStr.Equals("")){
				$lpObj = $spWeb
			}
			else {
				if($objStr.StartsWith("/Lists/")){
					$objStr = $objStr.Remove(0,7)
				}else{
					$objStr = $objStr.Remove(0,1)
				}
				$lpObj = $spWeb.Lists[$objStr]
			}
			
			# Instantiate Group
			$lpGroup = $spWeb.SiteGroups[$perm.LPGroup]
			
			# Instantiate RoleDefinition
			$lpRole = $spWeb.RoleDefinitions[$perm.LPRole]

			$lpAssignment = New-Object Microsoft.SharePoint.SPRoleAssignment($lpGroup)   
			$lpAssignment.RoleDefinitionBindings.Add($lpRole) 
			$lpObj.RoleAssignments.Add($lpAssignment)
			$lpObj.Update()
			Write-Host "Die Rolle "$perm.LPGroup" wurde erfolgreich als "$perm.LPRole" auf "$perm.LPObject" berechtigt."
		}
		catch [Exception]{
			Write-Error $error[0].Exception
		}
		finally{
			Write-Warning "Die Rolle "$perm.LPGroup" konnte nicht als "$perm.LPRole" auf "$perm.LPObject" berechtigt werden."
		}
	
}

# SHAREPOINT\system in allen Bereichen hinzufügen

#[System.Enum]::GetNames("Microsoft.SharePoint.SPBasePermissions")
#EmptyMask
#ViewListItems
#AddListItems
#EditListItems
#DeleteListItems
#ApproveItems
#OpenItems
#ViewVersions
#DeleteVersions
#CancelCheckout
#ManagePersonalViews
#ManageLists
#ViewFormPages
#Open
#ViewPages
#AddAndCustomizePages
#ApplyThemeAndBorder
#ApplyStyleSheets
#ViewUsageData
#CreateSSCSite
#ManageSubwebs
#CreateGroups
#ManagePermissions
#BrowseDirectories
#BrowseUserInfo
#AddDelPrivateWebParts
#UpdatePersonalWebParts
#ManageWeb
#UseClientIntegration
#UseRemoteAPIs
#ManageAlerts
#CreateAlerts
#EditMyUserInfo
#EnumeratePermissions
#FullMask


.Main