Add-SPSolution -LiteralPath C:\Users\serverless-me\Desktop\iLoveSharePoint.Fields.LookupFieldWithPicker.wsp
Install-SPSolution –Identity iLoveSharePoint.Fields.LookupFieldWithPicker.wsp –WebApplication http://yourserver:24816 -GACDeployment 
#Enable-SPFeature -Identity b3b2d9c2-a220-44b7-b946-9ea5347c97b6  -Url http://yourserver:24816

Uninstall-SPSolution –Identity lpribbonctrl.wsp -AllWebApplications
Remove-SPSolution -Identity lpribbonctrl.wsp -Force

Install-SPSolution –Identity iLoveSharePoint.Fields.LookupFieldWithPicker.wsp –WebApplication http://yourserver:24816 -GACDeployment 


Install-SPSolution –Identity ribbondemo.wsp -AllWebApplications -GACDeployment -Force
Install-SPFeature -Path RibbonDemo_Feature1 -Force
Enable-SPFeature -Identity ff5a10d7-1d41-41ed-85f5-e8bf192638c3 -Url http://ariadne/ -Force

Install-SPSolution –Identity lpribbonctrl.wsp -GACDeployment -Force -AllWebApplications
Install-SPFeature -Path LPRibbonCtrl_Feature1 -Force
Install-SPFeature -Path LPRibbonCtrl_Feature2 -Force
Enable-SPFeature -Identity 7ff31a09-4f17-4dc5-bcad-55fd0d6734d1 -Url http://yourserver:24816/ -Force
Enable-SPFeature -Identity dfec7f87-1c51-4279-b9e1-550d79edcd39 -Url http://yourserver:24816/ -Force

Get-SPFeature | Where-Object{ $_.DisplayName -like '*ribbon*'}
Get-SPSolution | Where-Object{ $_.DisplayName -like '*ribbon*'}

Disable-SPFeature -Identity 7ff31a09-4f17-4dc5-bcad-55fd0d6734d1 -Url http://yourserver:24816/ -Force
uninstall-SPFeature -Identity 7ff31a09-4f17-4dc5-bcad-55fd0d6734d1 -Force

Get-SPSolution
Get-Command *feature*

ListOfSubwebsites_Feature1     77ce121c-765d-4ba4-9fc2-9b3adcb2229e     Site