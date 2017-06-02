$html = get-content "c:\Downloads\web\example3.htm"
$hrefRegex = '<a\s.{0,}?href=".+?".{0,}?>.+?</a>'
$urlRegex = '(?<=href=")\s*\"*[^\">]*'
$textRegex = '(?<=<a .*?>)[^<>]+(?=</a>)'
$hrefs = ([regex]::matches($html, $hrefRegex) | %{$_.value})
$hrefs
$urls = ([regex]::matches($html, $urlRegex) | %{$_.value})
$urls
$texts = ([regex]::matches($html, $textRegex) | %{$_.value})
$texts