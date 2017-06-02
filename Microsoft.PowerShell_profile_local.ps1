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
# Set Aliases
Set-Alias new New-Object
Set-Alias ie 'C:\Program Files\Internet Explorer\iexplore.exe'

# Create Format For Transcript Filename
$transPath = $PROFILE.Substring(0,$PROFILE.LastIndexOf("\"))+"\Transscripts\"
$stampDate = Get-Date -UFormat '%Y%m%d_%H%M%S'
$stampStr = $transPath
$stampStr += "PSHistory_"
$stampStr += $stampDate.ToString()
$stampStr += ".txt"
Start-Transcript -path $stampStr

# Limit Count of Transcripts to 10
[System.Array] $items = Get-ChildItem $transPath
if($items.Count -gt 10){
	get-childitem $transPath | Sort-Object -Property LastWriteTime -Descending | select -Last 1 | Remove-Item
}
