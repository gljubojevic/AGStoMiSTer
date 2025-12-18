function FileRequired {
	param (
		[string]$path
	)
	if (-not (Test-path $path)){
		throw "Required file $($path) does not exist."
	} 
}
