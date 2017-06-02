##############################################################################
##
## Add User As ShellAdmin / Choose Content-Database
##
##############################################################################

<#

.DESCRIPTION
Add User As ShellAdmin / Choose Content-Database from Prompt

.PARAMETER user
Specifiy "domain\username" for the ShellAdmin to be added.

.EXAMPLE
PS > .\Set-SPShellAdmin.ps1 de\serverless-me

#>

param([string]$user)

$snapin = Get-PSSnapin | where-Object {$_.Name -eq "Microsoft.SharePoint.PowerShell"}
if($snapin -eq $null){Add-PsSnapin Microsoft.SharePoint.PowerShell}

# Prompts for Username and assosiated Content-Database
$title = "Choose Content-Database"
$message = "Für welche Datenbank soll der Benutzer als Shelladmin hinzugefügt werden?"
$dbs = Get-SPContentDatabase 
$col = New-Object System.Collections.ArrayList
for ($i = 0;$i -lt $dbs.Count;$i++) {
	$str = "&"+$i+": "+$dbs[$i].Name+" / "+$dbs[$i].WebApplication+" / "+$dbs[$i].Server
	$col.Add($str)
}
$options = [System.Management.Automation.Host.ChoiceDescription[]]$col
$result = $host.ui.PromptForChoice($title, $message, $options, 0) 

add-spshelladmin -UserName $user -database $dbs[$result]