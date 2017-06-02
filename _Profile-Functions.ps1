# Selection of SPWebs after startup
$spWeb = Get-SPWeb -Identity http://yourserver:44444/lernportal
function Get-SPItems ($listName)
{
	$spList = $spWeb.Lists[$listName]
	return $spList.Items
}
function Get-SPFieldEnum ($listName)
{
	$spList = $spWeb.Lists[$listName]
	# Make Hashtabel for Intellisense by . with Title => Internalname (vs. Dictionary?)
	return $spFieldEnum
}
function Get-SPQuickLaunch
{
	$spWeb.Navigation.QuickLaunch
}
function Set-SPQuickLaunchAudience ($nodeStr, $audience)
{
	# $spWeb.SiteGroups: Auswahl anstatt Parameter $audience
	$spNavNode = Get-SPQuickLaunch | Where-Object {$_.Title -eq $nodeStr}
	$spNavNode.Properties["Audience"] = $audience
}
function Get-SPWebApplicationOverview
{
	Get-SPWebApplication | ForEach-Object {"WebApp: "+$_.DisplayName; "Url: "+$_.Url; "Pool: "+$_.ApplicationPool.Name+"("+$_.ApplicationPool.Status+")";""}
}
function Get-ObjectInfo ($object)
{
	$object | Get-Member | Format-Table Name, MemberType
}