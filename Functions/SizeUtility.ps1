function KBtoBytes {
	param (
		[int]$sz
	)
	return $sz * 1024
}

function MBtoBytes {
	param (
		[int]$sz
	)
	return $sz * 1024 * 1024
}

function GBtoBytes {
	param (
		[int]$sz
	)
	return $sz * 1024 * 1024 * 1024
}
