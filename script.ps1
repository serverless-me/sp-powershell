

Get-Process -Name onenote

Get-Process -Name onenote | Get-Member


Get-Process -Name onenote | Format-List


Get-Process -Name onenote | Format-List -Property

Get-Process -Name onenote | Get-Member


Get-Process -Name onenote | Format-List -Property Id, Threads, CPU, Path


Get-Process -Name onenote | Format-List -Property Id, Threads, CPU, Path, Product, PRoductVersion





notepad






$process = Get-Process -Name notepad







$process.Kill()










100GB/10GB










100GB/100MB











[DateTime]::IsLeapYear(2012)
















# Pipeline
$path1 = c:\aircrack\*
$path2 = c:\aircrack2
Get-Item $path1 | Move-Item -Destination $path2
















# Pipeline
$path1 = "c:\aircrack\*"
$path2 = "c:\aircrack2"
Get-Item $path1 | Move-Item -Destination $path2





















Get-History | Foreach-Object { $_.CommandLine } > c:\temp\script.ps1
notepad c:\temp\script.ps1

