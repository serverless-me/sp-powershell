##############################################################################
##
## YASI - yet another sharepoint installation
##
##############################################################################

<#

.DESCRIPTION
Erstellt eine Sharepoint-Website anhand eines XML-Files innerhalb einer angegebenen WebApplication. 
Die Website-Struktur muss in einem XML-File modelliert werden:

- Site-Collection
- Webseiten (mit site-relativer URL)
  * Listen / Bibliotheken
  	+ Fields (Lookup, Choice, MultiChoice, Text, Note, Boolean)
	  .ShowInEditForm
	  .ShowInNewForm
	  .ShowInDisplayForm
	+ Views (NUR ANPASSUNG VORHANDENER VIEWS!)
	  .ViewFields
  * RoleAssignments (Dürfen nur vorhandene RoleDefinitions und SiteGroups verwenden)
- RoleDefinitionen
- SiteGroups (Für die erste SiteGroup muss als Owner "Besitzer von MySite" eingetragen werden)

Update-Funktionalität ist darauf beschränkt, dass Properties neu gesetzt werden und
neue Elemente (Websites, Listen, Felder) angelegt werden. Es findet kein löschen statt.

.PARAMETER path
Gibt den Dateipfad der XML-Datei an, die das Modell der Website enthält.

.EXAMPLE
PS > .\Create-Website.ps1 C:\ps\MyWebsite.xml

#>
param([string]$path = "Lernportal.xml")

function Update-Progress ($currentOperation)
{
	$global:i++
	if (! $calculating) {
		$counter = $global:i/$total*100
		Write-Progress $status $activity -PercentComplete $counter -CurrentOperation $currentOperation
		
	}
	else{
		Write-Progress $status $activity -PercentComplete 1 -CurrentOperation $currentOperation
	}
}

function Start-Installation ($rootElem) {
	    $activity = 'Starting Installation'
		Create-SiteCollection $rootElem.Url $rootElem.Title $rootElem.Owner $rootElem.ApplicationPool
		Create-SiteGroups ($rootElem.Group)
		Create-RoleDefinitions ($rootElem.RoleDefinition)
		Fill-Website ($rootElem.Website)
}

function Create-SiteCollection ($siteUrl, $siteName, $siteOwner, $appPool) {
	Update-Progress ('Site Collection anlegen: ' + $siteName)
	if (! $calculating){
		try{
			if (! (Get-SPSite $siteUrl)){
				# Falls die Site-Collection noch nicht vorhanden ist, wird eine neue erstellt
				# In jedem Fall muss eine Webapplication inkl. AppPool zuvor erstellt worden sein.
				new-spsite $siteUrl -ownerAlias $siteOwner -Name $siteName -Template "STS#1"
			}
		}
		catch [Exception] {
			('Fehler bei Site Collection anlegen: ' + $siteName) >> $errFile
			$errCategory = $Error[0].CategoryInfo.Category.ToString()
            $errText = $Error[0].Message.ToString()
            ($errCategory+': '+$errText) >> $errFile
		}
	}
}

function Create-SiteGroups ($xmlgroups){
	Update-Progress ('Besitzer von ' + $rootElem.Title + ' anlegen: ' + $rootElem.Owner)
	if (! $calculating) {
		$spWeb = Get-SPWeb $rootElem.Url
		if(! $spWeb.AssociatedOwnerGroup){
			try {
				# Der User der im XML-Root angegeben ist, wird als Besitzer der Website aufgenommen
				$spuser = Get-SPUser -identity $rootElem.Owner -web $rootElem.Url
				$ownerStr = "Besitzer von "+$rootElem.Title
				$spWeb.SiteGroups.Add($ownerStr,$spuser, $null, "Besitzergruppe")
				$spWeb.AssociatedOwnerGroup = $spWeb.SiteGroups[$ownerStr]
			}
			catch [Exception] {
				('Fehler bei Besitzer von ' + $rootElem.Title + ' anlegen: ' + $rootElem.Owner) >> $errFile
			    $errCategory = $Error[0].CategoryInfo.Category.ToString()
                $errText = $Error[0].Exception.ToString()
                ($errCategory+': '+$errText) >> $errFile
			}
		}
	}
	
	foreach ($xmlgroup in $xmlgroups){
		Update-Progress ('SiteGroup anlegen: '+$xmlgroup.Name)
		if (! $calculating) {
			try{
				if(! $spWeb.SiteGroups[$xmlgroup.Name]){
					# Die Sharepoint-Gruppen werden angelegt, denen später Berechtigungen gegeben werden
					$owner = $spWeb.SiteGroups[$xmlgroup.Owner]
					$spWeb.SiteGroups.Add($xmlgroup.Name,$owner, $null, $xmlgroup.Description)
				}
			}
			catch [Exception] {
				('Fehler bei SiteGroup anlegen: '+$xmlgroup.Name) >> $errFile
                $errCategory = $Error[0].CategoryInfo.Category.ToString()
                $errText = $Error[0].Exception.ToString()
                ($errCategory+': '+$errText) >> $errFile
			}
		}
	}
	if (! $calculating) {$spWeb.Update()}
}

function Create-RoleDefinitions ($xmlRoleDefinitions) {
		if (! $calculating) {$spWeb = Get-SPWeb $rootElem.Url}
		foreach ($xmlrole in $xmlRoleDefinitions){
			Update-Progress ('RoleDefinition anlegen: '+$xmlrole.Name)
			if (! $calculating) {
				try{
					# Die Berechtigungsstufen werden erstellt
					$roleDef = $spWeb.RoleDefinitions[$xmlrole.Name]
					if($roleDef -eq $null){
						$roleDef = New-Object Microsoft.SharePoint.SPRoleDefinition
						$roleDef.Name = $xmlrole.Name
						$roleDef.Description = $xmlrole.Description
			            $spWeb.RoleDefinitions.Add($roleDef)
					    $roleDef = $spWeb.RoleDefinitions[$xmlrole.Name]
					}
					$roleDef.BasePermissions = $xmlrole.BasePermissions
			        $roleDef.Update()
				}
				catch [Exception] {
					('Fehler bei RoleDefinition anlegen: '+$xmlrole.Name) >> $errFile
                    $errCategory = $Error[0].CategoryInfo.Category.ToString()
                    $errText = $Error[0].Exception.ToString()
                    ($errCategory+': '+$errText) >> $errFile
				}
			}
		}
}

function Fill-Website ($xmlWebsite) {
	$activity = 'Installation '+$xmlWebsite.Name
	Update-Progress ('Anlegen von Elementen')
    $url = $rootElem.Url + $xmlWebsite.RelUrl
	Create-WebRoleAssignments $xmlWebsite.RoleAssignment $url $xmlWebsite.BreakRoleInheritance
	Create-Lists $xmlWebsite.List $url
	Create-Fields $xmlWebsite.List $url
	Create-Views $xmlWebsite.List $url
	Create-Website $xmlWebsite.Website
}

function Create-WebRoleAssignments ($xmlassignments, $url, $breakRoleInheritance) {
	if ($xmlassignments){
		if($breakRoleInheritance){Update-Progress ('Vererbung der Berechtigungen aufheben: '+$url)}
		if (! $calculating) {
			$rootWeb = Get-SPWeb $rootElem.Url
			$spWeb = Get-SPWeb $url
			if($breakRoleInheritance){
				try {
					# Ggf. wird die Vererbung der Berechtigungen unterbrochen
					if($breakRoleInheritance -like "?true"){$spWeb.BreakRoleInheritance($true)}
					elseif($breakRoleInheritance -like "?false"){$spWeb.BreakRoleInheritance($false)}
				}
				catch [Exception] {
        			('Fehler bei Vererbung der Berechtigungen aufheben: '+$url) >> $errFile
                    $errCategory = $Error[0].CategoryInfo.Category.ToString()
                    $errText = $Error[0].Exception.ToString()
                    ($errCategory+': '+$errText) >> $errFile
				}
			}
		}
		foreach ($xmlassignment in $xmlassignments) {
            Update-Progress ('RoleAssignment anlegen: '+$xmlassignment.Group+' / '+$xmlassignment.RoleDefinition)
			if (! $calculating) {
				try {
					# Gruppen werden mit der entsprechenden Berechtigungsstufe auf eine Website berechtigt
					$spGroup = $rootWeb.SiteGroups[$xmlassignment.Group]
					$spRole = $rootWeb.RoleDefinitions[$xmlassignment.RoleDefinition]
					$spAssignment = New-Object Microsoft.SharePoint.SPRoleAssignment($spGroup)   
					$spAssignment.RoleDefinitionBindings.Add($spRole)
					$spWeb.RoleAssignments.Add($spAssignment)
				}
				catch [Exception] {
					('Fehler bei RoleAssignment anlegen: '+$xmlassignment.Group+' / '+$xmlassignment.RoleDefinition) >> $errFile
                    $errCategory = $Error[0].CategoryInfo.Category.ToString()
                    $errText = $Error[0].Exception.ToString()
                    ($errCategory+': '+$errText) >> $errFile
				}
			}	
		}
		if (! $calculating) {$spWeb.Update()}
	}
}

# TODO: Remove Roleassignements
function Create-ListRoleAssignments ($xmlList) {
	$xmlassignments = $xmlList.RoleAssignments
	if ($xmlassignments){
		if($breakRoleInheritance){Update-Progress ('Vererbung der Berechtigungen aufheben: '+$url)}
		if (! $calculating) {
			$rootWeb = Get-SPWeb $rootElem.Url
			$url = $rootElem.Url + $xmlList.ParentNode.RelUrl
			$spWeb = Get-SPWeb $url
			$spList = $spWeb.Lists[$xmlList.Name]
			if($xmlList.HasAttribute("BreakRoleInheritance")){
				try {
					# Ggf. wird die Vererbung der Berechtigungen unterbrochen
					if($xmlList.BreakRoleInheritance -like "?true"){$spList.BreakRoleInheritance($true)}
					elseif ($xmlList.BreakRoleInheritance -like "?false"){$spList.BreakRoleInheritance($false)}
				}
				catch [Exception] {
					('Fehler bei Vererbung der Berechtigungen aufheben: '+$url) >> $errFile
                    $errCategory = $Error[0].CategoryInfo.Category.ToString()
                    $errText = $Error[0].Exception.ToString()
                    ($errCategory+': '+$errText) >> $errFile
				}
			}
		}
		foreach ($xmlassignment in $xmlassignments) {
			Update-Progress ('RoleAssignment anlegen: '+$xmlassignment.Group+' / '+$xmlassignment.RoleDefinition)
			if (! $calculating) {
				try {
					# Gruppen werden mit der entsprechenden Berechtigungsstufe auf eine Website berechtigt
					$spGroup = $rootWeb.SiteGroups[$xmlassignment.Group]
					$spRole = $rootWeb.RoleDefinitions[$xmlassignment.RoleDefinition]
					$spAssignment = New-Object Microsoft.SharePoint.SPRoleAssignment($spGroup)   
					$spAssignment.RoleDefinitionBindings.Add($spRole)
					$spList.RoleAssignments.Add($spAssignment)
				}
				catch [Exception] {
					('Fehler bei RoleAssignment anlegen: '+$xmlassignment.Group+' / '+$xmlassignment.RoleDefinition) >> $errFile
                    $errCategory = $Error[0].CategoryInfo.Category.ToString()
                    $errText = $Error[0].Exception.ToString()
                    ($errCategory+': '+$errText) >> $errFile
				}
			}
		}
		if (! $calculating) {$spList.Update()}
	}
}

function Create-Lists ($xmllists, $url) {
	if ($xmllists){
		if (! $calculating) {$spWeb = Get-SPWeb $url}
		foreach ($xmllist in $xmllists) {
			Update-Progress ('List anlegen: '+$xmllist.Name)
			if (! $calculating) {
				try {
					# Listen werden erstellt und Eigenschaften konfiguriert
					$listTemplate = $spWeb.ListTemplates | Where-Object{$_.Type -eq $xmllist.ListTemplate}
					if(! $spWeb.Lists[$xmllist.Name]){$spWeb.Lists.Add($xmllist.Name, $xmllist.Description,$listTemplate)}
					$spList = $spWeb.Lists[$xmllist.Name]
					if($xmllist.HasAttribute("OnQuickLaunch")){
						$spList.OnQuickLaunch = $xmllist.OnQuickLaunch
					}
					if($xmllist.HasAttribute("EnableFolderCreation")){
						$spList.EnableFolderCreation = $xmllist.EnableFolderCreation
					}
					if($xmllist.HasAttribute("ContentTypesEnabled")){
						$spList.ContentTypesEnabled = $xmllist.ContentTypesEnabled
					}
					if($xmllist.HasAttribute("EnableVersioning")){
						$spList.EnableVersioning = $xmllist.EnableVersioning
					}
					if($xmllist.HasAttribute("EnableMinorVersions")){
						$spList.EnableMinorVersions = $xmllist.EnableMinorVersions
					}
					$spList.Update()
					Create-ListRoleAssignments ($xmllist)
				}
				catch [Exception]{
					('Fehler bei List anlegen: '+$xmllist.Name) >> $errFile
                    $errCategory = $Error[0].CategoryInfo.Category.ToString()
                    $errText = $Error[0].Exception.ToString()
                    ($errCategory+': '+$errText) >> $errFile
				}
			}
		}
		if (! $calculating) {$spWeb.Update()}
	}
}

function Create-Fields ($xmllists, $url) {
	if ($xmllists){
		if (! $calculating) {$spWeb = Get-SPWeb $url}
		foreach ($xmllist in $xmllists) {
			if (! $calculating) {$spList = $spWeb.Lists[$xmllist.Name]}
			foreach ($xmlfield in $xmllist.Field){
				if($xmlfield){
					Update-Progress ('Field anlegen: '+$xmlfield.Name+' / Liste: '+$xmllist.Name)
					if (! $calculating) {
						try{
							$spField = $spList.Fields[$xmlfield.Name]
							if (! $spField) {
								# Felder unterschiedlichen Typs werden erstellt und die Eigenschaften gesetzt
								if($xmlfield.HasAttribute("SPFieldType")){
									switch ($xmlfield.SPFieldType){
										"Url" {$spType = [Microsoft.SharePoint.SPFieldType]::URL;break}
										"Choice" {$spType = [Microsoft.SharePoint.SPFieldType]::Choice;break}
										"Note" {$spType = [Microsoft.SharePoint.SPFieldType]::Note;break}
										"Lookup" {$spType = [Microsoft.SharePoint.SPFieldType]::Lookup;break}
										"Boolean" {$spType = [Microsoft.SharePoint.SPFieldType]::Boolean;break}
										"User" {$spType = [Microsoft.SharePoint.SPFieldType]::User;break}
										"Integer" {$spType = [Microsoft.SharePoint.SPFieldType]::Integer;break}
										"DateTime" {$spType = [Microsoft.SharePoint.SPFieldType]::DateTime;break}
										"Text" {$spType = [Microsoft.SharePoint.SPFieldType]::Text;break}
										"Counter" {$spType = [Microsoft.SharePoint.SPFieldType]::Counter;break}
										"Number" {$spType = [Microsoft.SharePoint.SPFieldType]::Number;break}
										"Currency" {$spType = [Microsoft.SharePoint.SPFieldType]::Currency;break}
										"MultiChoice" {$spType = [Microsoft.SharePoint.SPFieldType]::MultiChoice;break}
									}
								}
								if ($xmlfield.SPFieldType -eq "Choice" -or $xmlfield.SPFieldType -eq "MultiChoice"){
									$spChoices = New-Object System.Collections.Specialized.StringCollection
									$choices = $xmlfield.Choices -split ";"
									foreach($choice in $choices){$spChoices.Add($choice)}
									$spList.Fields.Add($xmlfield.Name,$spType, $xmlfield.Required, $false, $spChoices)
									
								}
								elseif($xmlfield.SPFieldType -eq "Lookup"){
									$spLookupList = $spWeb.Lists[$xmlfield.Name]
									$spList.Fields.AddLookUp($xmlfield.Name, $spLookupList.ID, $xmlfield.Required)
								}
								else{
									$spList.Fields.Add($xmlfield.Name,$spType, $xmlfield.Required)
								}
								$spField = $spList.Fields[$xmlfield.Name]
								$spField.Description = $xmlfield.Description
								if($xmlfield.HasAttribute("ShowInEditForm")){
									$spField.ShowInEditForm = $xmlfield.ShowInEditForm
								}
								if($xmlfield.HasAttribute("ShowInDisplayForm")){
									$spField.ShowInDisplayForm = $xmlfield.ShowInDisplayForm
								}
								if($xmlfield.HasAttribute("ShowInNewForm")){
									$spField.ShowInNewForm = $xmlfield.ShowInNewForm
								}
								if($xmlfield.HasAttribute("EnforceUniqueValues")){
									$spField.EnforceUniqueValues = $xmlfield.EnforceUniqueValues
								}
								if($xmlfield.HasAttribute("EditFormat")){
									$spField.EditFormat = $xmlfield.EditFormat
								}
								if($xmlfield.HasAttribute("AllowMultipleValues")){
									$spField.AllowMultipleValues = $xmlfield.AllowMultipleValues
								}
								if($xmlfield.HasAttribute("SelectionMode")){
									switch ($xmlfield.SelectionMode){
										"PeopleOnly"{$spField.SelectionMode = [Microsoft.SharePoint.SPFieldUserSelectionMode]::PeopleOnly;break}
										"PeopleAndGroups"{$spField.SelectionMode = [Microsoft.SharePoint.SPFieldUserSelectionMode]::PeopleAndGroups;break}
									}
								}
								$spField.Update()
							}
						}
						catch [Exception] {
							('Fehler bei Field anlegen: '+$xmlfield.Name+' / Liste: '+$xmllist.Name) >> $errFile
                            $errCategory = $Error[0].CategoryInfo.Category.ToString()
                            $errText = $Error[0].Exception.ToString()
                            ($errCategory+': '+$errText) >> $errFile
						}
					}
				}
			}
			if(! $calculating) {$spList.Update()}
		}
		if(! $calculating) {$spWeb.Update()}
	}
}

# TODO: Neue Views anlegen
function Create-Views ($xmllists, $url) {
	if ($xmllists){
		if (! $calculating) {$spWeb = Get-SPWeb $url}
			foreach ($xmllist in $xmllists) {
				if (! $calculating) {$spList = $spWeb.Lists[$xmllist.Name]}
				foreach ($xmlview in $xmllist.View){
					if($xmlview){
						Update-Progress ('View anlegen: '+$xmlview.Title+' / Liste: '+$xmllist.Name)
						if (! $calculating) {
							try{
								# Vorhandene Views werden angepasst
								$spView = $spList.Views[$xmlview.Title]
								$spViewFields = $spView.ViewFields
								$spViewFields.DeleteAll()
								$spFields = $spList.Fields
								foreach ($xmlviewfield in $xmlview.ViewField){
									if($xmlviewfield){
										$spViewFields.Add($spFields.GetFieldByInternalName($xmlviewfield.InternalName)) 
									}
								}
								$spView.Update()
							}
							catch [Exception] {
								('Fehler bei View anlegen: '+$xmlview.Title+' / Liste: '+$xmllist.Name) >> $errFile
			                    $errCategory = $Error[0].CategoryInfo.Category.ToString()
                                $errText = $Error[0].Exception.ToString()
                                ('>>>'+$errCategory+': '+$errText) >> $errFile
							}
						}
					}
				}
				if(! $calculating) {$spList.Update()}
			}
			if(! $calculating) {$spWeb.Update()}
	}
}

function Create-Website ($xmlwebsites) {
	if ($xmlwebsites){
		foreach ($xmlwebsite in $xmlwebsites) {
			Update-Progress ('Website anlegen: '+$xmlwebsite.Name)
			if (! $calculating) {
				try {
					$url = $rootElem.Url+$xmlwebsite.RelUrl
					if (! (Get-SPWeb $url)){
						# Eine neue Website wird erstellt, abhängig davon, welche Switch-Parameter angegeben sind
						if ($xmlwebsite.UseParentTopNav -like "?true" -and $xmlwebsite.AddToTopNav -like "?true" -and $xmlwebsite.AddToQuickLaunch -like "?true"){
							New-SPWeb -Url $url -Name $xmlwebsite.Name -Template $xmlwebsite.Template -Description $xmlwebsite.Description -UseParentTopNav -AddToTopNav -AddToQuickLaunch
						}
						elseif ($xmlwebsite.UseParentTopNav -like "?true" -and $xmlwebsite.AddToTopNav -like "?true" -and $xmlwebsite.AddToQuickLaunch -like "?false"){
							New-SPWeb -Url $url -Name $xmlwebsite.Name -Template $xmlwebsite.Template -Description $xmlwebsite.Description -UseParentTopNav -AddToTopNav
						}
						elseif ($xmlwebsite.UseParentTopNav -like "?true" -and $xmlwebsite.AddToTopNav -like "?false" -and $xmlwebsite.AddToQuickLaunch -like "?true"){
							New-SPWeb -Url $url -Name $xmlwebsite.Name -Template $xmlwebsite.Template -Description $xmlwebsite.Description -UseParentTopNav -AddToQuickLaunch
						}
						elseif ($xmlwebsite.UseParentTopNav -like "?true" -and $xmlwebsite.AddToTopNav -like "?false" -and $xmlwebsite.AddToQuickLaunch -like "?false"){
							New-SPWeb -Url $url -Name $xmlwebsite.Name -Template $xmlwebsite.Template -Description $xmlwebsite.Description -UseParentTopNav
						}
						elseif ($xmlwebsite.UseParentTopNav -like "?false" -and $xmlwebsite.AddToTopNav -like "?true" -and $xmlwebsite.AddToQuickLaunch -like "?true"){
							New-SPWeb -Url $url -Name $xmlwebsite.Name -Template $xmlwebsite.Template -Description $xmlwebsite.Description -AddToTopNav -AddToQuickLaunch
						}
						elseif ($xmlwebsite.UseParentTopNav -like "?false" -and $xmlwebsite.AddToTopNav -like "?true" -and $xmlwebsite.AddToQuickLaunch -like "?false"){
							New-SPWeb -Url $url -Name $xmlwebsite.Name -Template $xmlwebsite.Template -Description $xmlwebsite.Description -AddToTopNav
						}
						elseif ($xmlwebsite.UseParentTopNav -like "?false" -and $xmlwebsite.AddToTopNav -like "?false" -and $xmlwebsite.AddToQuickLaunch -like "?true"){
							New-SPWeb -Url $url -Name $xmlwebsite.Name -Template $xmlwebsite.Template -Description $xmlwebsite.Description -AddToQuickLaunch
						}
						elseif ($xmlwebsite.UseParentTopNav -like "?false" -and $xmlwebsite.AddToTopNav -like "?false" -and $xmlwebsite.AddToQuickLaunch -like "?false"){
							New-SPWeb -Url $url -Name $xmlwebsite.Name -Template $xmlwebsite.Template -Description $xmlwebsite.Description
						}
					}
				}
				catch [Exception] {
					('Fehler bei Website anlegen: '+$xmlwebsite.Name) >> $errFile
                    $errCategory = $Error[0].CategoryInfo.Category.ToString()
                    $errText = $Error[0].Exception.ToString()
                    ($errCategory+': '+$errText) >> $errFile
				}
			}
			Fill-Website $xmlwebsite
		}
	}
}

# Initialisierung
$errFile = Join-Path (Split-Path $Profile) "LP-Installation-ERROR.txt"
"Starte Installation: " + (Get-Date -UFormat '%d.%m.%Y %H:%M:%S') >> $errFile
$snapin = Get-PSSnapin | where-Object {$_.Name -eq "Microsoft.SharePoint.PowerShell"}
if($snapin -eq $null){Add-PsSnapin Microsoft.SharePoint.PowerShell}

$xml = [xml] (Get-Content $path)
$rootElem = $xml.Root

# Zuerst wird die XML-Datei durchlaufen, um die Anzahl der Schritte zu ermitteln
$i = 0
$total = 0
$calculating = $true
$status = "Analyzing Data"
$activity = "Analyse starten"
Update-Progress ("Reading XML")
Start-Installation $rootElem
$calculating = $false
$total = $i+1
$global:i = 1
$status = "Installation"
Update-Progress ("Starting")
# Hier beginnt die Installation
Start-Installation $rootElem
$Error.Clear()
Invoke-Item $errFile