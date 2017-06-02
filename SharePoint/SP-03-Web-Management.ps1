
# ====================== #
# SPSite
# ====================== #
New-SPSite
Set-SPSite
Get-SPSite
Backup-SPSite
Restore-SPSite
Move-SPSite
Remove-SPSite -GradualDelete

# ====================== #
# SPWeb
# ====================== #
Get-SPWeb
Set-SPWeb
Export-SPWeb -Path c:\file.bak -ItemUrl "lists/Calendar" -IncludeUserSecurity -IncludeVersions
Import-SPWeb # Matching Template required!!!
New-SPWeb -Url -Template -Name -AddToTopNav

# Website-Templates
$spWeb.GetAvailableWebTemplates($spWeb.CurrencyLocaleID)                 
# STS#0                                   Teamwebsite                            
# STS#1                                   Leere Website                          
# STS#2                                   Dokumentarbeitsbereich                 
# MPS#0                                   Standard-Besprechungsarbeitsbereich
# WIKI#0                                  Wiki-Website                           
# BLOG#0                                  Blog                                   
# SGS#0                                   Gruppenarbeitssite                      
# ACCSRV#0                                Access Services-Site                  
# ACCSRV#4                                Kontakte-Webdatenbank                  
# ACCSRV#6                                Probleme-Webdatenbank                  
# ACCSRV#5                                Projekte-Webdatenbank                  
# BDR#0                                   Dokumentcenter                         
# OFFILE#1                                Datenarchiv                            
# OSRV#0                                  Verwaltungssite der gemeinsamen Dienste
# PowerPivot#0                            PowerPivot-Site                        
# PowerPointBroadcast#0                   PowerPoint-Übertragungswebsite         
# PPSMASite#0                             PerformancePoint                       
# BICenterSite#0                          Business Intelligence Center           
# PWA#0                                   Project Web App-Site                   
# PWS#0                                   Microsoft Project-Website 
# SPSPERS#0                               SharePoint Portal Server - Persönlic...
# SPSMSITE#0                              Personalisierungswebsite                
# CMSPUBLISHING#0                         Veröffentlichungswebsite               
# BLANKINTERNET#0                         Veröffentlichungssite                   
# BLANKINTERNET#2                         Veröffentlichungssite mit Workflow     
# SPSNHOME#0                              Website 'Nachrichten'                  
# SPSSITES#0                              Websiteverzeichnis      
# SPSREPORTCENTER#0                       Berichtscenter                         
# SPSPORTAL#0                             Zusammenarbeitsportal                  
# SRCHCEN#0                               Unternehmenssuchcenter                 
# BLANKINTERNETCONTAINER#0                Veröffentlichungsportal                
# ENTERWIKI#0                             Unternehmenswiki                       
# SRCHCENTERLITE#0                        Basissuchcenter                        
# SRCHCENTERLITE#1                        Basissuchcenter                        
# SRCHCENTERFAST#0                        FAST Search-Center                     
# vispr#0                                 Visio-Prozessrepository                 


