Function Invoke-WebRequest
{
    param
    (
        [Parameter(Mandatory=$false)]
        [RestMethod]
        $method,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $uri,
        [Parameter(Mandatory=$false)]
        [object]
        $body,
        [Parameter(Mandatory=$false)]
        [System.string]
        $userAgent,
        [Parameter(Mandatory=$false)]
        [switch]
        $asJson,
        [System.String]
        $ContentType = 'application/json',
        [Parameter(Mandatory=$false)]
        [object]
        $Headers
    )
    if($script:cookiejar -eq $Null){
        $script:cookiejar = New-Object System.Net.CookieContainer     
    }
    $maxAttempts = 3
    $attempts=0
    while($true){
        $attempts++
        try{
            $retVal = @{}
            $request = [System.Net.WebRequest]::Create($uri)
            $request.TimeOut = 5000
			if($method -eq $null){
				$request.Method = 'GET'
			} else {
				$request.Method = $method
			}
            if($trySSO -eq 1){
                $request.UseDefaultCredentials = $True
            }
            if($customHeaders){
                $customHeaders.Keys | % { 
                    $request.Headers[$_] = $customHeaders.Item($_)
                }
            }
			if($userAgent -eq $null) {
				$request.UserAgent = "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 10.0; WOW64; Trident/7.0; .NET4.0C; .NET4.0E)"
			}
            $request.ContentType = "application/x-www-form-urlencoded"
            $request.CookieContainer = $script:cookiejar
            if($method -eq "POST"){
                $body = [byte[]][char[]]$body
                $upStream = $request.GetRequestStream()
                $upStream.Write($body, 0, $body.Length)
                $upStream.Flush()
                $upStream.Close()
            }
            $response = $request.GetResponse()
            $retVal.StatusCode = $response.StatusCode
            $retVal.StatusDescription = $response.StatusDescription
            $retVal.Headers = $response.Headers
            $stream = $response.GetResponseStream()
            $streamReader = [System.IO.StreamReader]($stream)
            $retVal.Content = $streamReader.ReadToEnd()
            $streamReader.Close()
            $response.Close()
            return $retVal
        }catch{
            if($attempts -ge $maxAttempts){Throw}else{sleep -s 2}
        }
    }
}
