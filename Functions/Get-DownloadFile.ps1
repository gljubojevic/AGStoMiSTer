function Get-DownloadFile {
	param (
		[string]$DownloadURL,
		[string]$OutputLocation, #Needs to include filename!
		[int]$NumberOfAttempts
	)
	$client = [System.Net.Http.HttpClient]::new()
	$client.DefaultRequestHeaders.UserAgent.ParseAdd("PowerShellHttpClient")
    
	$attempt = 1
	$success = $false
    
	while (-not $success -and $attempt -le $NumberOfAttempts) {
		if ($attempt -gt 1){
			$TimeForRetry = (5 * ($attempt-1))
			Write-Host "Waiting $TimeForRetry seconds before trying again"
			Start-Sleep -Seconds $TimeForRetry
			Write-Host ('Trying Download again. Retry Attempt # '+($attempt-1))                            
		}
		$response = $client.GetAsync($DownloadURL , [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
		if (-not $response.IsSuccessStatusCode) {
			Write-Host "HTTP request failed. Status Code: $($response.StatusCode) Reason Phrase: $($response.ReasonPhrase)"
		}
		else {
			$FileLength = $response.Content.Headers.ContentLength
			$stream = $response.Content.ReadAsStreamAsync().Result
			$fileStream = [System.IO.File]::OpenWrite($OutputLocation)
			$buffer = New-Object byte[] 65536  # 64 KB
			$read = 0
			$totalRead = 0
			$percentComplete = 0
			while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
				$fileStream.Write($buffer, 0, $read)
				$totalRead += $read
				$newPercent = [math]::Floor(($totalRead/$FileLength)*100)
				if ($newPercent -ne $percentComplete) {
					$percentComplete = $newPercent
					Write-Progress -Activity "Downloading" -Status "$percentComplete% Complete" -PercentComplete $percentComplete
				}
			}
			Write-Progress -Activity "Downloading" -Completed -Status "Done"
			$success = $true                            
		}
		$attempt++
	}
	if ($stream){
		$stream.Dispose() 
		$stream = $null 
	}
	if ($fileStream) {
		$fileStream.Dispose()
		$fileStream = $null
	}  
	return $success      
}
