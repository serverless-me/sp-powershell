Add-PSSnapin Microsoft.SharePoint.PowerShell
$root = Get-SPWeb -Identity http://yourserver:44444/
$url =  $root.Url + "/lernportal"
$spWeb = Get-SPWeb $url
$spList = $spWeb.Lists["Lerngruppen"]
$spList.OnQuickLaunch = $false
$spField = $spList.Fields["Title"]
$spField.ShowInEditForm = $false;
$spField.ShowInDisplayForm = $false;
$spField.ShowInNewForm = $true;
$spField.EnforceUniqueValues = $true
$spField.Update()
$spList.Update()