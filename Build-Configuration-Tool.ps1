#requires -version 4.0
<#
	.SYNOPSIS 
	  Rename, Copy & Delete Visual Studio Build Configurations
	.DESCRIPTION
	  Searches current folder + subfolder for *.sln and *.csproj files. Each file is modified according to arguments. 
	.PARAMETER Configuration
	  The source build configuration. Required.
	.PARAMETER Copy
	  Copy build configuration to specified name.
	.PARAMETER Rename
	  Rename build configuration to specified name.
	.PARAMETER Delete
	  Remove build configuration.
	.EXAMPLE
	  Build-Configuration-Tool Debug -Rename Test
	  This command replaces the "Debug" build configuration with one called "Test".
	.EXAMPLE
	  Build-Configuration-Tool Release -Copy Prod
	  This command copies the "Release" build configuration to "Prod".
	.EXAMPLE
	  Build-Configuration-Tool Release -Rename Production -Copy QA
	  This command finds the "Release" build configuration, renames it to "Production" and copies it to "QA".
	.NOTES  
	  Author     : Philip Hoppe
	  Requires   : PowerShell V4
	.LINK
	  https://github.com/PolarbearDK/Build-Configuration-Tool
#>
param (
	[parameter(Mandatory=$true)]
	[string]$Configuration,
	
	[parameter(Mandatory=$false)]
	[string]$Copy,
	
	[parameter(Mandatory=$false)]
	[string]$Rename,

	[parameter(Mandatory=$false)]
	[switch]$Delete
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version latest

function Load-File ([string]$FilePath){
	Write-Verbose "Reading content of $FilePath"
	[string]$text = [System.IO.File]::ReadAllText($filepath)
	$text -split "`r`n"
	Write-Verbose "Done Reading content of $FilePath"
}

function Save-File ([string]$FilePath, [string[]]$Content){
	Write-Verbose "Writing content to $FilePath"
	[string]$text = $Content -join "`r`n"
	[System.IO.File]::WriteAllText($filepath, $text, [System.Text.Encoding]::UTF8)
	Write-Verbose "Done Writing content to $FilePath"
}

if($Delete) {
	if($Copy -ne "" -and $Rename -eq "") {
		# Copy+Delete=Rename
		$Rename = $Copy
		$Copy = ""
		$Delete=$false
	}
}

# handle .SLN
Get-ChildItem *.sln -Recurse | ForEach-Object {
	echo $_.FullName

	$content = Load-File $_.FullName | 
		ForEach-Object {
			$match = $_ | Select-String "^.*$Configuration\|.*$"
			if($match) {
				if($Rename -ne "") {
					$_.Replace("$Configuration|","$Rename|")
				} else {
					if(-not $Delete) {$_}
				}
				if($Copy -ne "") {
					$_.Replace("$Configuration|","$Copy|")
				}
			} else {
				$_
			}
		} |
		ForEach-Object {
			$match = $_ | Select-String "^.*$Configuration\.AspNetCompiler\..*$"
			if($match) {
				if($Rename -ne "") {
					$_.Replace("$Configuration.","$Rename.")
				} else {
					if(-not $Delete) {$_}
				}
				if($Copy -ne "") {
					$_.Replace("$Configuration.","$Copy.")
				}
			} else {
				$_
			}
		}
		
	Save-File -FilePath $_.FullName -Content $content
}

function Rename-PropertyGroup($lines, $from, $to) {
	$search1 = "(?<=')" + [regex]::Escape("$from") + "(?=['|])"
	$search2 = "(?<=\\)" + [regex]::Escape("$from") + "(?=\\)"
	$lines -replace $search1,$to -replace $search2,$to
}

# handle .csproj
Get-ChildItem . -File -Include *.csproj,*.vbproj,*.scproj,TdsGlobal.config -Recurse | ForEach-Object {
	$file = $_
	Write-Output $file.FullName
	$content = Load-File $file.FullName
	
	# stream lines through filter
	$newContent = for($i=0; $i -lt $content.Length; $i++) {
		$line = $content[$i]
		Write-Verbose "Processing line [$i]$line"
		if($line -match ".*\<PropertyGroup.*'$Configuration['|].*") {
			$end = $i + 1
			while($content[$end] -inotlike "*</PropertyGroup>*") { $end++ }
			$propertyGroup = $content[$i..$end]
			$i = $end

			if($Rename -ne "") {
				Rename-PropertyGroup $propertyGroup $Configuration $Rename
			} else {
				if(-not $Delete) {$propertyGroup}
			}

			if($Copy -ne "") {
				Rename-PropertyGroup $propertyGroup $Configuration $Copy
			}
		} elseif($line -like "*<Configuration Condition=`" '`$(Configuration)' == '' `">$Configuration</Configuration>" ) {
			if($Rename -ne "") {
				$line.Replace(">$Configuration<",">$Rename<")
			} else {
				$line
			}
		} elseif($line -match ".*\<(Content|None) Include\=`"(?<file>.*$Configuration.config)`".*") {
			$filename = $matches['file'];
			$filenameWithPath = Join-Path $file.Directory.FullName $filename
			if($line -like "*/>*") {
				$item = $line
			} else {
				$end = $i + 1
				while($content[$end] -inotmatch ".*\<\/(Content|None)\>.*") { 
					$end++ 
					#sanity check
					if($end -gt $content.Length) { throw "Unable to detect end tag at line $i (zero based)" }
				}
				$item = $content[$i..$end]
				$i = $end
				}

			if($Copy -ne "") {
				$newFileName = $filename -replace ([regex]::Escape(".$Configuration.config")), ".$Copy.Config"
				$newItem = $item -replace ([regex]::Escape($filename)), $newFilename
				
				# Are there a reference to the file already?
				if($content -contains ($newItem | Select-Object -First 1)) {
					Write-Verbose "There is already a reference to $newFileName. Reference wil not be added"
				} else {
					Write-Verbose "Adding reference to file: $newFileName."
					# Add lines for new file reference to output stream
					$newItem
				}
				
				$newFilePath =  Join-Path $file.Directory.FullName $newFileName
				if(Test-Path $newFilePath) {
					$fileCounter = 0
					Do { 
						$resolvePath = "$newFilePath.Orig" 
						if($fileCounter -ne 0) {$resolvePath = "$resolvePath$fileCounter"}
						$fileCounter++ 
					} while(Test-Path $resolvePath) 
					Move-Item $newFilePath -Destination $resolvePath
					Write-Warning "Existing file: $newFilePath has been renamed to: $resolvePath"
				}
				
				Copy-Item $filenameWithPath -Destination $newFilePath
			}

			if($Rename -ne "") {
				$newFileName = $filename -replace ([regex]::Escape(".$Configuration.config")), ".$Rename.Config"
				$newItem = $item -replace ([regex]::Escape($filename)), $newFilename
				
				# Are there a reference to the file already?
				if($content -contains ($newItem | Select-Object -First 1)) {
					Write-Verbose "There is already a reference to $newFileName. Reference wil not be added"
				} else {
					Write-Verbose "Adding reference to file: $newFileName."
					# Add lines for new file reference to output stream
					$newItem
				}
				
				$newFilePath =  Join-Path $file.Directory.FullName $newFileName
				if(Test-Path $newFilePath) {
					$fileCounter = 0
					Do { 
						$resolvePath = "$newFilePath.Orig" 
						if($fileCounter -ne 0) {$resolvePath = "$resolvePath$fileCounter"}
						$fileCounter++ 
					} while(Test-Path $resolvePath) 
					Move-Item $newFilePath -Destination $resolvePath
					Write-Warning "Existing file: $newFilePath has been renamed to: $resolvePath"
				}
				
				Move-Item $filenameWithPath -Destination $newFilePath
			} else {
				if($Delete){
					# Do not output item to stream, thereby removing reference from file
					# Remove file
					if(Test-Path $filenameWithPath) { 
						Remove-Item $filenameWithPath
					}
				} else {
					#output item to stream
					$item
				}
			}
		} else {
			#output line to stream without changes
			$line
		}
	}

	Save-File -FilePath $_.FullName -Content $newContent
}
