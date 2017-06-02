# Define Variables
Get-Variable
Set-Variable
New-Variable
Clear-Variable
Remove-Variable

# DataTypes
[string][int][bool][array][hashtable][xml][wmi][float][byte][char][long]

# Beispiel:
[string]$var = "Hallo Welt!"
$var.GetType().FullName
$var | Get-Member 
Write-Host $var 

ForEach-Object

Get-Command

# Properties of Single Object
Format-List

# Multiple Objects
Format-Table

# Ergebnisse in Tabelle Schreiben
Export-Csv c:\Site-Info.csv

# Systemvariablen
$_
$args
$Error
$foreach
$Host
$null
$true
$false
$PSBoundParameters
$PSHOME

# Output
> c:\output.txt # Send Output to File
>> c:\output.txt # Append Output to File
2> c:\error.txt # Send Error to File
2>> c:\error.txt # Append Error to File

# Object Disposal 1
$spWeb.Dispose()

# Object Disposal 2
Start-Assignment -global
Stop-Assignment -global

# Object Disposal 3
$spAssi = Start-Assignment
Get-SPWeb -AssignmentCollection $spAssi
Stop-Assignment $spAssi

# Using Parameters
param([string]$name,[int]$age)

# Documentation
.DESCRIPTION
Bla

.PARAMETER abc
Bla

.OUTPUT
Bla

.EXAMPLE
Bla