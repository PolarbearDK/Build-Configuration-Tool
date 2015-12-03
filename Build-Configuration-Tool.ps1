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
	[switch]$Delete,
	
	[parameter(Mandatory=$false)]
	[string]$Suffix
)

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

	$content = Get-Content $_.FullName | 
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
		}
	$content | Out-File -Encoding UTF8 -FilePath $_.FullName
}

function Rename-PropertyGroup($lines, $from, $to) {
	$search1 = "(?<=')" + [regex]::Escape("$from") + "(?=['|])"
	$search2 = "(?<=\\)" + [regex]::Escape("$from") + "(?=\\)"
	$lines -replace $search1,$to -replace $search2,$to
}

# handle .csproj
Get-ChildItem . -File -Include *.csproj,*.vbproj,*.scproj -Recurse | ForEach-Object {
	$file = $_
	echo $file.FullName
	$content = Get-Content $file.FullName
	$newContent = for($i=0; $i -lt $content.Length; $i++) {
		$line = $content[$i]
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
				$line.Replace(">$Configuration<",">$Replace<")
			} else {
				$line
			}
		} elseif($line -match ".*\<None Include\=`"(?<file>.*$Configuration.config)`".*") {
			$filename = $matches['file'];
			$filenameWithPath = Join-Path $file.Directory.FullName $filename
			if($line -like "*/>*") {
				$item = $line
			} else {
				$end = $i + 1
				while($content[$end] -inotlike "*</None>*") { $end++ }
				$item = $content[$i..$end]
				$i = $end
				}

			if($Copy -ne "") {
				$newFileName = $filename -replace ([regex]::Escape(".$Configuration.config")), ".$Copy.Config"
				$item -replace ([regex]::Escape($filename)), $newFilename
				Copy-Item $filenameWithPath -Destination (Join-Path $file.Directory.FullName $newFileName)
			}

			if($Rename -ne "") {
				$newFileName = $filename -replace ([regex]::Escape(".$Configuration.config")), ".$Rename.Config"
				$item -replace ([regex]::Escape($filename)), $newFilename
				Move-Item $filenameWithPath -Destination (Join-Path $file.Directory.FullName $newFileName)
			} else {
				if(-not $Delete){
					$item
				} else {
					Remove-Item $filenameWithPath
				}
			}
		} else {
			$line
		}
	}

	$newContent | Out-File -Encoding UTF8 -FilePath $_.FullName
}
