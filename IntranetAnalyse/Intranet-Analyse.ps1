<# 
.DESCRIPTION
Skript zur Analyse des Intranet vor der Migration. 

.PARAMETER RootUrl
URL der Root-Website der zu analysierenden Site Collection.

.PARAMETER OutFile
Pfad zur CSV-Datei, in die die Werte der Analyse geschrieben werden.

.OUTPUT
Output wird in eine csv-Datei geschrieben.

.EXAMPLE
Intranet-Analyse -RootUrl http://localhost/  -OutFile c:\Intranet-Analyse.csv
#>

param(
[string]$RootUrl,
[string]$OutFile
)

# PSSnapin hinzufügen
$snapin = Get-PSSnapin | where-Object {$_.Name -eq "Microsoft.SharePoint.PowerShell"}
if($snapin -eq $null){Add-PsSnapin Microsoft.SharePoint.PowerShell}

# Sicherstellen dass Adminrechte auf DB vorhanden sind

# =====================================
# = Analyse ohne Daten zu schreiben: 
# = - Tiefe der Website
# = - Anzahl der Items
# =====================================
function Analyse-WebsiteDepth ($url)
{
    $global:depth += 1
    $global:websitedepths.Add($global:depth)
	$web = Get-SPWeb -Identity $url
	$subURLs = Get-SubWebs $web
	$web.Dispose()
    if ($subURLs)
    {
    	foreach ($subURL in $subURLs){
    		Analyse-WebsiteDepth $subURL
            $global:depth -= 1
    	}
    }
}


# =====================================
# = Pro Website / Pro ListItem: 
# = 1 Zeile in CSV-Datei
# =====================================

function Analyse-Web ($url)
{
    try 
    {
    	$web = Get-SPWeb -Identity $url
        Write-Progress "Analysing Websites" "Running" -PercentComplete (++$counter*100/$maxCount) -CurrentOperation ("Analysing Web: "+$web.Title)
        
        $global:actualdepth += 1
    	Analyse-Lists $web
    	$subURLs = Get-SubWebs $web
    	$web.Dispose()
        if ($subURLs)
        {
        	foreach ($subURL in $subURLs){
        		Analyse-Web $subURL
                $global:actualdepth -= 1
        	}
        }
    }
    catch [Exception]
    {
        $errtxt = ""
        if ($url) { $errtxt = "Url: " + $url }
        Write-Error("Error in Analyse-Web "+$errtxt)
    }
}
function Analyse-Lists ($web) 
{
    try 
    {
    	Write-Host ("Analysiere Web: "+$web.Title)
        foreach ($list in $web.Lists){
           if($list) { Analyse-Items $list }
        }
    }
    catch [Exception]
    {
        $errtxt = ""
        if ($web.Title) { $errtxt = "Web: " + $web.Title }
        Write-Error("Error in Analyse-Lists "+$errtxt)
    }
}

function Analyse-Items ($list) 
{
    try 
    {
        Write-Host ("Analysiere Liste: "+$list.Title)
        foreach ($item in $list.Items)
        {
            Get-ItemInformation $item
        }
    }
    catch [Exception]
    {
        $errtxt = ""
        if ($list.ParentWeb.Title) { $errtxt = "Web: " + $list.ParentWeb.Title }
        if ($list.Title) { $errtxt = "List: " + $list.Title }
        Write-Error("Error in Analyse-Items "+$errtxt)
    }
}

function Get-SubWebs ($web) 
{
    try
    {
    	$subwebs = New-Object System.Collections.ArrayList
    	$websinfo = $web.Webs.get_WebsInfo()
        if ($websinfo)
        {
        	$websinfoenum = $websinfo.GetEnumerator();
        	while($websinfoenum.MoveNext())
        	{
        		$counter = $subwebs.Add($web.Site.Url + $websinfoenum.Current.ServerRelativeUrl)
        	}
        	return $subwebs
        }
        else 
        {
            return $null
        }
    }
    catch [Exception]
    {
        $errtxt = ""
        if ($web.Title) { $errtxt += "Web: "+$web.Title }
        Write-Error("Error in Get-SubWebs "+$errtxt)
    }
}

# String-Array erzeugen mit 
# - Url
# - List
# - Item
# - Size
# - Created
# - Modified
# - Author
# - Editor
function Get-ItemInformation ($item) {
    try 
    {
        $infoArray = New-Object String[] ($global:depth+8) 
        $regex = "(?<=.*#).*"
        
        $itemUrl = $item.ParentList.ParentWebUrl
        $hierarchy = $itemUrl -split "/"
        $infoArray[0] = $item.Web.Site.Url
        if($itemUrl -ne "/"){
            for ($i = 1; $i -le $hierarchy.Count; $i++) {
                $infoArray[$i] = $hierarchy[$i]
            }
        }
        
        $infoArray[($global:depth+1)] = $item.ParentList.Title
        if ($item["FileLeafRef"]) { $infoArray[($global:depth+2)] = $item["FileLeafRef"].ToString() }
        elseif ($item["Title"]) { $infoArray[($global:depth+2)] = $item["Title"].ToString() }
        elseif ($item["ID"]) { $infoArray[($global:depth+2)] = $item["ID"].ToString() }
        
        $author = ""
        if ($item["Author"]) { $author = $item["Author"].ToString() }
        elseif ($item["Created_x0020_By"]) { $author = $item["Created_x0020_By"].ToString() }
        $infoArray[$global:depth+3] = [regex]::matches($author, $regex) | %{$_.value}
        
        if ($item["Created_x0020_Date"]) { $infoArray[$global:depth+4] = $item["Created_x0020_Date"].ToString() }
        elseif ($item["Created"]) { $infoArray[$global:depth+4] = $item["Created"].ToString() }
        
        $editor = ""
        if ($item["Editor"]) { $editor = $item["Editor"].ToString() }
        elseif ($item["Modified_x0020_By"]) { $editor = $item["Modified_x0020_By"].ToString() }
        $infoArray[$global:depth+5] = [regex]::matches($editor, $regex) | %{$_.value}
        
        if ($item["Modified_x0020_Date"]) { $infoArray[$global:depth+6] = $item["Modified_x0020_Date"].ToString() } 
        elseif ($item["Last_x0020_Modified"]) { $infoArray[$global:depth+6] = $item["Last_x0020_Modified"].ToString()}
        elseif ($item["Modified"]) { $infoArray[$global:depth+6] = $item["Last_x0020_Modified"].ToString() }
        
        if ($item["File_x0020_Size"]) { $infoArray[$global:depth+7] = $item["File_x0020_Size"].ToString() }
    	# Store ItemInformation in Array
    	
    	Write-ItemInformation $infoArray
    }
    catch [Exception]
    {
        $errtxt = ""
        if ($item.web.Title) { $errtxt += "Web: "+$item.web.Title }
        if ($item.id) { $errtxt += "Item: "+$item.id }
        Write-Error("Error in Get-ItemInformation "+$errtxt)
    }
}


# Array Zeilenweise kommagetrennt in Datei schreiben
function Write-ItemInformation ($infoArray) 
{
    try {
        $outString = ""
        foreach ($str in $infoArray){
             $outString += $str+"|"
        }
    	$outString >> $OutFile
    }
    catch [Exception]
    {
        Write-Error("Error in Write-ItemInformation")
    }
}

try 
{
    $test = $true
    $delimiter = ","
    $global:websitedepths = New-Object System.Collections.ArrayList
    $global:depth = -1
    $global:actualdepth = -1
    if($test)
    { 
        $RootUrl = "http://yoururl" 
        $OutFile = "C:\Users\username\Documents\test.csv"    
    }
    Analyse-WebsiteDepth $RootUrl
    $websitedepths.Sort()
    $maxCount = $websitedepths.Count
    $counter = 0
    $global:depth = $websitedepths.Item($websitedepths.Count-1)
    Analyse-Web $RootUrl
}
catch [Exception]
{
    Write-Error("General Exception")
}