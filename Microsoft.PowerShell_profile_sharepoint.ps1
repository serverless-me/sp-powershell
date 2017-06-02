$ver = $host | select version
if ($ver.Version.Major -gt 1)  {$Host.Runspace.ThreadOptions = "ReuseThread"}
$snapin = Get-PSSnapin | where-Object {$_.Name -eq "Microsoft.SharePoint.PowerShell"}
if($snapin -eq $null){Add-PsSnapin Microsoft.SharePoint.PowerShell}
Set-location $home
Start-Sleep 5

function Get-ObjectInfo ($object)
{
	$object | Get-Member | Format-Table Name, MemberType
}

function Get-MemberList ($obj){
	if($obj -ne $null){
	$type = $obj.GetType()

	$profileFolder = $PROFILE.Substring(0,($PROFILE.LastIndexOf("\")+1))
	$path = $profileFolder
	$path += $type.Name
	$path += ".csv"
	
	$members = $obj | Get-Member
	$z = $members.Count
	$memlist = New-Object string[] $z
	for ($i = 0; $i -lt $z; $i++){
		$memlist[$i] = $type.Namespace
		$memlist[$i] += "`t"+$type.Name
		$memlist[$i] += "`t"+$members[$i].Name
		$memlist[$i] += "`t"+$members[$i].MemberType
	}
	$memlist > $path
	}
}

function Start-TranscriptPP {
	# Create Format For Transcript Filename
	$transPath = $PROFILE.Substring(0,$PROFILE.LastIndexOf("\"))+"\Transscripts\"
	$stampDate = Get-Date -UFormat '%Y%m%d_%H%M%S'
	$stampStr = $transPath
	$stampStr += "PSHistory_"
	$stampStr += $stampDate.ToString()
	$stampStr += ".txt"

	$transcript = $transPath+$stampStr
	Start-Transcript -path $stampStr
	# Limit Count of Transcripts to 10
	[System.Array] $items = Get-ChildItem $transPath
	if($items.Count -gt 10){
		get-childitem $transPath | Sort-Object -Property LastWriteTime -Descending | select -Last ($items.Length-10) | del
	}
}
Set-StrictMode -Version Latest
Import-Module SP-Functions
Start-TranscriptPP


