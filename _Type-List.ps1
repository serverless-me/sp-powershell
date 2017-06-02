function Get-MemberList ($obj){
	$type = $obj.GetType()
	
	$profileFolder = $PROFILE.Substring(0,($PROFILE.LastIndexOf("\")+1))
	$path = $profileFolder
	$path += $type.Name
	$path += ".csv"

	$z = $members.Count
	$memlist = string[] $z
	for ($i = 0; $i -lt $z; $i++){
		$memlist[$i] = $type.Namespace
		$memlist[$i] += "`t"+$type.Name
		$memlist[$i] += "`t"+$members[$i].Name
		$memlist[$i] += "`t"+$members[$i].MemberType
	}
	$memlist > $path
	Invoke-Item $path
}
$obj = Get-Item $PROFILE
Get-MemberList($obj)
