function Confirm-FileExists {
	param (
		[string]$PathToCheck
		#,$HashToCheck
	)
	if (-not (Test-path $PathToCheck)){
		Write-Host "Required file $($PathToCheck) does not exist. Downloading"
		return $false
	} 
	#if ((Get-FileHash -Path $PathToCheck -Algorithm MD5).hash -ne $HashToCheck){
	#	Write-Host "File hashes do not match. Removing existing file and re-downloading"
	#	$null = Remove-Item -Path $PathToCheck
	#	return $false 
	#}
	Write-Host "File $PathToCheck exists. No download required."
	return $true
}