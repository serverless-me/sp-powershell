$spWeb = Get-SPWeb -Identity http://yourserver:44444/lernportal
$lists = "Übungen", "Skripte", "Links", "Contents", "CAD-Zeichnungen", "Bildungspakete"

foreach ($list in $lists){
    $spList = $spWeb.Lists[$list]
    $spField = $spList.Fields["Lerngruppen"]
    if($spField -ne $null){
	    $spList.Title
        Write-Host "NewForm" $spField.ShowInNewForm
        Write-Host "EditForm" $spField.ShowInEditForm
        Write-Host "DisplayForm" $spField.ShowInDisplayForm
        $spField.ShowInNewForm = $false
        $spField.ShowInEditForm = $false
        $spField.ShowInDisplayForm = $true
        $spField.Update()
    }
	[Console]::Beep(1000,500)
}