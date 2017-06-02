Add-PSSnapin Microsoft.SharePoint.PowerShell
Get-PSSnapin -Registered

get-spshelladmin (Get-SPContentDatabase -Identity WSS_Content_bae7bf820dc94634acfd259388c3618f)
add-spshelladmin -UserName de\serverless-me -database (Get-SPContentDatabase -Identity WSS_Content_bae7bf820dc94634acfd259388c3618f)

