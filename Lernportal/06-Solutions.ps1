Add-SPSolution -LiteralPath C:\Users\serverless-me\Desktop\iLoveSharePoint.Fields.LookupFieldWithPicker.wsp
Add-PSSnapin Microsoft.SharePoint.PowerShell

Install-SPSolution –Identity iLoveSharePoint.Fields.LookupFieldWithPicker.wsp –WebApplication http://yourserver:24816 -GACDeployment 
#Enable-SPFeature -Identity b3b2d9c2-a220-44b7-b946-9ea5347c97b6  -Url http://yourserver:24816
