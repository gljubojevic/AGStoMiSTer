function ReplaceInFiles {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$false, Position=0)]
		[string]$Path = '.',
		[string]$Filter = '*.*',
		[Parameter(Mandatory=$true)]
		[string]$Pattern,
		[Parameter(Mandatory=$true)]
		[string]$Replacement,
		[switch]$Regex,
		[switch]$CaseSensitive,
		[switch]$Recurse,
		[switch]$Backup,
		[switch]$DryRun,
		[ValidateSet('utf8','utf7','utf32','unicode','bigendianunicode','ascii','default')]
		[string]$Encoding = 'utf8'
	)

	if (Test-Path -LiteralPath $Path -PathType Leaf) {
		$files = @(Get-Item -LiteralPath $Path)
	} else {
		if ($Recurse) { $files = Get-ChildItem -Path $Path -Filter $Filter -File -Recurse }
		else { $files = Get-ChildItem -Path $Path -Filter $Filter -File }
	}

	$patternForCount = if ($Regex) {
		$Pattern
	} else {
		[regex]::Escape($Pattern)
	}

	$regexOptions = if ($CaseSensitive) {
		[System.Text.RegularExpressions.RegexOptions]::None
	} else {
		[System.Text.RegularExpressions.RegexOptions]::IgnoreCase
	}

	$results = @()

	foreach ($f in $files) {
		$fPath = $f.FullName

		try {
			$text = Get-Content -Raw -LiteralPath $fPath -ErrorAction Stop
		} catch {
			$errMsg = "Skipping $($fPath) - cannot read file: $($_.Exception.Message)"
			Write-Warning $errMsg
			continue
		}

		$matchCount = 0
		try {
			$matchCount = [regex]::Matches($text, $patternForCount, $regexOptions).Count
		} catch {
			$errMsg = "Pattern error for $($fPath): $($_.Exception.Message)"
			Write-Warning $errMsg
			continue
		}

		if ($matchCount -le 0) {
			Write-Host "No matches in $fPath"
			continue
		}

		if ($DryRun) {
			$results += [pscustomobject]@{ File = $fPath; Matches = $matchCount }
			Write-Host "[DryRun] $($matchCount) matches in $($fPath)"
			continue
		}

		if ($Backup) {
			try {
				Copy-Item -LiteralPath $fPath -Destination "$($fPath).bak" -Force -ErrorAction Stop
			} catch {
				$errMsg = "Could not create backup for $($fPath): $($_.Exception.Message)"
				Write-Warning $errMsg
			}
		}

		if ($Regex) {
			if ($CaseSensitive) { $new = $text -creplace $Pattern, $Replacement }
			else { $new = $text -replace $Pattern, $Replacement }
		} else {
			$new = [regex]::Replace($text, [regex]::Escape($Pattern), $Replacement, $regexOptions)
		}

		if ($new -ne $text) {
			try {
				Set-Content -LiteralPath $fPath -Value $new -Encoding $Encoding -Force
				$results += [pscustomobject]@{ File = $fPath; Matches = $matchCount }
				Write-Host "Updated: $($fPath) ($($matchCount) matches)"
			} catch {
				$errMsg = "Failed to write $($fPath): $($_.Exception.Message)"
				Write-Warning $errMsg
			}
		}
	}

	return $results
}
