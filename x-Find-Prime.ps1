param(
[ValidateRange(1,10000)][int]$ceil
)
function Find-Prime
{
	if($ceil -ne $null -and $ceil -gt 0)
	{
		clear
		$count = 1
		for ($i = 1;$i -le $ceil;$i++){
			if(-not (getit($i))) {
				$i
				$count++
			}
		}
		"==="
		$count
		"==="
		($count/$ceil*100).toString()+" %"
	}
}

function getit($i)
{
		for($t = 2;$t -lt $i;$t++){
		$e = $i % $t
		if($e -eq 0) {
			return $true
		}
	}
	return $false
}

. Find-Prime