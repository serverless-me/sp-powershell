$dir = "C:\Downloads\web\"
$suburl = "c:\Downloads\web\example2.htm"
$urlRegex = '(?<=href=")\s*\"*[^\">]*'
$listOfWebsites = New-Object System.Collections.ArrayList
$filteredWebsites = New-Object System.Collections.ArrayList

$subcontent = Get-Content $suburl
$fileurls = ([regex]::matches($subcontent, $urlRegex) | %{$_.value})
[System.Collections.ArrayList]$filetypes = "jpg", "jpeg", "mpg", "mp4", "avi", "wmv"
$listOfFiles = New-Object System.Collections.ArrayList

$suburl = $suburl.Substring(0,$suburl.LastIndexOf("\")+1)
foreach($fileurl in $fileurls){
	if($url.Contains(".")){
		$filetype = $url.Substring($fileurl.LastIndexOf(".")+1).ToLower()
		if($filetypes.Contains($filetype)){
			if($fileurl -notcontains "http://"){
				$fileurl = $source + $fileurl
			}
			$listOfFiles.add($fileurl)
		}
	}
}

$urls