# ====================== #
# SPFarm
# ====================== #
Get-SPFarm
Restore-SPFarm
Backup-SPFarm

Get-SPFarmConfig
Set-SPFarmConfig

Backup-SPConfigurationDatabase

# ====================== #
# SPWebApplication
# ====================== #
Get-SPWebApplication
Set-SPWebApplication
New-SPWebApplication -Name -Port -ApplicationPool -ApplicationPoolAccount
Remove-SPWebApplication -Identity -DeleteIISSite -RemoveContentDatabase

# ====================== #
# SPContentDatabase
# ====================== #
New-SPContentDatabase -Site -Identity -WebApplication
Mount-SPContentDatabase
Dismount-SPContentDatabase
Remove-SPContentDatabase
Get-SPContentDatabase
Test-SPContentDatabase



# ====================== #
# SPSolution
# ====================== #
Add-SPSolution
Install-SPSolution
Get-SPSolution
Update-SPSolution
Uninstall-SPSolution
Remove-SPSolution

# ====================== #
# SPFeature
# ====================== #
Install-SPFeature
Enable-SPFeature
Get-SPFeature
Disable-SPFeature
Uninstall-SPFeature