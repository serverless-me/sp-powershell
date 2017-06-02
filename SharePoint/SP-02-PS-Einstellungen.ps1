Add-PSSnapin Microsoft.SharePoint.PowerShell

# Good Practice
$Host.Runspace.ThreadOptions = "ReuseThread"

# SPShellAdmin
Add-SPShellAdmin -username htc\mei -database WSS_Content
Get-SPShellAdmin
Remove-SPShellAdmin

$MaximumHistoryCount

# Powershell Einstellungen
$ConfirmPreference
$DebugPreference
$ErrorActionPreference
$ErrorView
$FormatEnumerationLimit
$LogCommandHealthEvent
$LogEngineHealthEvent
$MaximumErrorCount
$MaximumFunctionCount
$MaximumHistoryCount
$MaximumVariableCount
$PSEmailServer