function Select-Objects ($objectArray) {
	Add-Type -Assembly System.Windows.Forms
	## Create the main form
	$form = New-Object Windows.Forms.Form
	$form.Size = New-Object Drawing.Size @(600,600)
	## Create the listbox to hold the items from the pipeline
	$listbox = New-Object Windows.Forms.CheckedListBox
	$listbox.CheckOnClick = $true
	$listbox.Dock = "Fill"
	$form.Text = "Select the list of objects you wish to pass down the pipeline"
	$listBox.Items.AddRange($objectArray)
	## Create the button panel to hold the OK and Cancel buttons
	$buttonPanel = New-Object Windows.Forms.Panel
	$buttonPanel.Size = New-Object Drawing.Size @(600,30)
	$buttonPanel.Dock = "Bottom"
	## Create the Cancel button, which will anchor to the bottom right
	$cancelButton = New-Object Windows.Forms.Button
	$cancelButton.Text = "Cancel"
	$cancelButton.DialogResult = "Cancel"
	$cancelButton.Top = $buttonPanel.Height - $cancelButton.Height - 5
	$cancelButton.Left = $buttonPanel.Width - $cancelButton.Width - 10
	$cancelButton.Anchor = "Right"
	## Create the OK button, which will anchor to the left of Cancel
	$okButton = New-Object Windows.Forms.Button
	$okButton.Text = "Ok"
	$okButton.DialogResult = "Ok"
	$okButton.Top = $cancelButton.Top
	$okButton.Left = $cancelButton.Left - $okButton.Width - 5
	$okButton.Anchor = "Right"
	## Add the buttons to the button panel
	$buttonPanel.Controls.Add($okButton)
	$buttonPanel.Controls.Add($cancelButton)
	## Add the button panel and list box to the form, and also set
	## the actions for the buttons
	$form.Controls.Add($listBox)
	$form.Controls.Add($buttonPanel)
	$form.AcceptButton = $okButton
	$form.CancelButton = $cancelButton
	$form.Add_Shown( { $form.Activate() } )
	## Show the form, and wait for the response
	$result = $form.ShowDialog()
	## If they pressed OK (or Enter), go through all the
	## checked items and send the corresponding object down the pipeline
	if($result -eq "OK"){return $listBox.CheckedIndices}
	else { return $null }
}

function Set-SPFormViews ($spField, $newBool, $editBool, $dispBool) {
    $spField.ShowInNewForm = $newBool;
    $spField.ShowInEditForm = $editBool;
    $spField.ShowInDisplayForm = $dispBool;
    $spField.Update()
}

function Hide-SPField ($spField) {
    $spField.Hidden = $true
    $spField.Update()
}

function Add-SPField ($spList, $name, $type, $required, $unique) {
    switch ($type){
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
	if (! $spType){throw "Unknown Fieldtype"}
	else {
		if ($type -eq "Choice" -or $type -eq "MultiChoice"){
			# Prompt for Choices
			$input = Read-Host 'Geben Sie die Auswahlliste mit Semicolon ";" getrennt an:'
			$spChoices = New-Object System.Collections.Specialized.StringCollection
			$choices = $input -split ";"
			foreach($choice in $choices){$spChoices.Add($choice)}
			$spList.Fields.Add($name, $spType, $required, $false, $spChoices)
			$spField = $spList.Fields[$name]
			
			$title = "Choose EditFormat"
			$message = "Wie sollen Elemente ausgewählt werden können?"
			$col = New-Object System.Collections.ArrayList
			$col.Add("Dropdown")
			$col.Add("RadioButtons")
			$options = [System.Management.Automation.Host.ChoiceDescription[]]$col
			$result = $host.ui.PromptForChoice($title, $message, $options, 0) 
			
			switch ($result){
				0 {$spField.Editformat = "Dropdown";break}
				1 {$spField.Editformat = "RadioButtons";break}
			}
		}
		elseif($type -eq "Lookup"){
			$spLookupList = $spWeb.Lists[$name]
			$spList.Fields.AddLookUp($name, $spLookupList.ID, $required)
		}
		else{
			$spList.Fields.Add($xmlfield.Name,$spType, $required)
		}
	    $spField = $spList.Fields[$name]
		
		if ($type -eq "User") {
			$title = "Choose Selectionmode"
			$message = "Welche Elemente sollen ausgewählt werden können?"
			$col = New-Object System.Collections.ArrayList
			$col.Add("PeopleOnly")
			$col.Add("PeopleAndGroups")
			$options = [System.Management.Automation.Host.ChoiceDescription[]]$col
			$result = $host.ui.PromptForChoice($title, $message, $options, 0) 
			
			switch ($result){
				0 {$spField.SelectionMode = [Microsoft.SharePoint.SPFieldUserSelectionMode]::PeopleOnly;break}
				1 {$spField.SelectionMode = [Microsoft.SharePoint.SPFieldUserSelectionMode]::PeopleAndGroups;break}
			}
		}
		if ($type -eq "Lookup" -or $type -eq "User") {
			$title = "AllowMultipleValues"
			$message = "Soll eine Mehrfachauswahl möglich sein?"
			$col = New-Object System.Collections.ArrayList
			$col.Add("Ja")
			$col.Add("Nein")
			$options = [System.Management.Automation.Host.ChoiceDescription[]]$col
			$result = $host.ui.PromptForChoice($title, $message, $options, 0) 
			
			switch ($result){
				0 {$spField.AllowMultipleValues = $true;break}
				1 {$spField.AllowMultipleValues = $false;break}
			}
		}
		$spField.EnforceUniqueValues = $unique
		$spField.Description = Read-Host "Geben Sie eine Beschreibung ein"
		
		$spField.Update()
	    return $spField
	}
}

function New-SPRoleDefinition ($name, $description) {
	$permissions = "ViewListItems","AddListItems","EditListItems",
		"DeleteListItems","ApproveItems","OpenItems","ViewVersions",
		"DeleteVersions","CancelCheckout","ManagePersonalViews",
		"ManageLists","ViewFormPages","Open","ViewPages",
		"AddAndCustomizePages","ApplyThemeAndBorder","ApplyStyleSheets",
		"ViewUsageData","CreateSSCSite","ManageSubwebs","CreateGroups",
		"ManagePermissions","BrowseDirectories","BrowseUserInfo",
		"AddDelPrivateWebParts","UpdatePersonalWebParts","ManageWeb",
		"UseClientIntegration","UseRemoteAPIs","ManageAlerts","CreateAlerts",
		"EditMyUserInfo","EnumeratePermissions"

	$selection = Select-Objects ($permissions)
	[string]$basepermission = ""
	for ($i=0;$i -lt $selection.Length;$i++) {
		$perm = $selection[$i]
		$basepermission += $permissions[$perm]
		if ($i -ne ($selection.Length-1)) {$basepermission += ", "}
	}
	$roleDef = New-Object Microsoft.SharePoint.SPRoleDefinition
	$roleDef.Name = $name
	$roleDef.Description = $description
	$roleDef.BasePermissions = $basepermission
	return $roleDef
}

function New-SPRoleAssignment ($spWeb, $groupname, $rolename) {
	New-SPRoleAssignment ($spWeb, $null, $groupname, $rolename)
}

function New-SPRoleAssignment ($spWeb, $listname, $groupname, $rolename) {
	$parentWeb = $spWeb
	while ($parentWeb.ParentWeb) {
		$parentWeb = $parentWeb.ParentWeb
	}
	$spGroup = $parentWeb.SiteGroups[$groupname]
	$spRole = $parentWeb.RoleDefinitions[$rolename]
	$spAssignment = New-Object Microsoft.SharePoint.SPRoleAssignment($spGroup)   
	$spAssignment.RoleDefinitionBindings.Add($spRole)
	if(! $spList){
		$spWeb.RoleAssignments.Add($spAssignment)
		$spWeb.Update()
	}
	else{
		$spList = $spWeb.Lists[$listname]
		$spList.RoleAssignments.Add($spAssignment)
		$spList.Update()
	}	
}

function New-SPList ($spWeb, $listname, $description) {
	$title = "Choose ListTemplates"
	$message = "Wählen Sie das Template für die neue Liste aus"
	$col = New-Object System.Collections.ArrayList
	for ($j = 0;$j -lt $spWeb.ListTemplates.Count; $j++){
		$col.Add("&"+$j+": "+$spWeb.ListTemplates[$j])
	}
	$options = [System.Management.Automation.Host.ChoiceDescription[]]$col
	$result = $host.ui.PromptForChoice($title, $message, $options, 0) 
	$listTemplate = $spWeb.ListTemplates[$result]
	$spWeb.Lists.Add($listname, $description, $listTemplate)
	$spList = $spWeb.Lists[$listname]
	$properties = "OnQuickLaunch", "EnableFolderCreation", "ContentTypesEnabled", "EnableVersioning", "EnableMinorVersions"
	$selection = Select-Objects ($properties)
	for ($k=0;$k -lt $properties.Length;$k++) {
		$properties[$k]
		$bool = $false
		for ($i=0;$i -lt $selection.Length -and $bool -eq $false;$i++) {
			$perm = $selection[$i]
			if ($properties[$perm] -eq $properties[$k]){$bool = $true}
		}
		switch ($properties[$k]){
			"OnQuickLaunch" {$spList.OnQuickLaunch = $bool;break}
			"EnableFolderCreation"{$spList.EnableFolderCreation = $bool;break}
			"ContentTypesEnabled"{$spList.ContentTypesEnabled = $bool;break}
			"EnableVersioning"{$spList.EnableVersioning = $bool;break}
			"EnableMinorVersions"{$spList.EnableMinorVersions = $bool;break}
		}
	}
	$spList.Update()
}

function Set-SPView ($spList) {
	# Prompt for View
	$title = "Choose View"
	$message = "Wählen Sie die Ansicht zum Anpassen aus"
	$col = New-Object System.Collections.ArrayList
	for ($l = 0;$l -lt $spList.Views.Count; $l++){
		$col.Add("&"+$l+": "+$spList.Views[$l])
	}
	$options = [System.Management.Automation.Host.ChoiceDescription[]]$col
	$result = $host.ui.PromptForChoice($title, $message, $options, 0)
	$spView = $spList.Views[$result]
	$spViewFields = $spView.ViewFields
	$spViewFields.DeleteAll()
	
	# Prompt for FieldSelection
	$spFields = $spList.Fields
	$fieldCol = New-Object System.Collections.ArrayList
	foreach ($field in $spFields){
		$fieldCol.Add($field.InternalName)
	}
	$selection = Select-Objects ($fieldCol)
	foreach ($indx in $selection){
		$spViewFields.Add($spFields.GetFieldByInternalName($fieldCol[$indx]))
	}
	$spView.Update()
}

function New-SPSubWeb ($spWeb, $name, $description) {
	# Prompt for Template
	$spTemplates = $spWeb.GetAvailableWebTemplates($spWeb.CurrencyLocaleID)
	$title = "Choose SPWebTemplate"
	$message = "Wählen Sie ein Template für die website aus"
	$col = New-Object System.Collections.ArrayList
	for ($m = 0;$m -lt $spTemplates.Count; $m++){
		$col.Add("&"+$m+": "+$spTemplates[$m].Title)
	}
	$options = [System.Management.Automation.Host.ChoiceDescription[]]$col
	$result = $host.ui.PromptForChoice($title, $message, $options, 0)
	$tempName = $spTemplates[$result].Name
	
	# Prompt for Options
	$options = "UseParentTopNav", "AddToTopNav", "AddToQuickLaunch"
	[string]$concat = ""
	$selection = Select-Objects ($options)
	foreach ($elem in $selection){
		$concat += $elem 
	}
	switch($concat){
		""{New-SPWeb -Url $url -Name $name -Template $tempName -Description $description;break}
		"0"{New-SPWeb -Url $url -Name $name -Template $tempName -Description $description -UseParentTopNav;break}
		"1"{New-SPWeb -Url $url -Name $name -Template $tempName -Description $description -AddToTopNav;break}
		"2"{New-SPWeb -Url $url -Name $name -Template $tempName -Description $description -AddToQuickLaunch;break}
		"01"{New-SPWeb -Url $url -Name $name -Template $tempName -Description $description -UseParentTopNav -AddToTopNav;break}
		"02"{New-SPWeb -Url $url -Name $name -Template $tempName -Description $description -UseParentTopNav -AddToQuickLaunch;break}
		"012"{New-SPWeb -Url $url -Name $name -Template $tempName -Description $description -UseParentTopNav -AddToTopNav -AddToQuickLaunch;break}
		"12"{New-SPWeb -Url $url -Name $name -Template $tempName -Description $description -AddToTopNav -AddToQuickLaunch;break}
	}
	  
}

function New-SPSiteGroup ($spWeb, $name, $description) {
	# Prompt for Owner
	$title = "Choose OwnerGroup"
	$message = "Wählen Sie eine Gruppe als Besitzer für die neue SiteGroup aus"
	$col = New-Object System.Collections.ArrayList
	for ($n = 0;$n -lt $spWeb.SiteGroups.Count; $n++){
		$col.Add("&"+$n+": "+$spWeb.SiteGroups[$n].Name)
	}
	$options = [System.Management.Automation.Host.ChoiceDescription[]]$col
	$result = $host.ui.PromptForChoice($title, $message, $options, 0)
	$spWeb.SiteGroups.Add($name,$spWeb.SiteGroups[$result], $null, $description)
}