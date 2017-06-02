$list = New-Object Collections.Generic.List[object]
$itemInformation1 = New-Object string[] 8
1..8 | foreach{
		$itemInformation1[$_ - 1] = "abc"
	}
$list.Add($itemInformation1)
$itemInformation2 = New-Object string[] 8
1..8 | foreach{
		$itemInformation2[$_ - 1] = "cde"
	}
$list.Add($itemInformation2)
foreach ($itemInformation in $list){
	$itemInformation[0]+','+$itemInformation[0]
	Export-Csv -InputObject $itemInformation.ToString() -Path "myTest.csv" -Delimiter ";"
}