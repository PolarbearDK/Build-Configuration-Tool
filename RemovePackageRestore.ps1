param(
	[Parameter(Mandatory=$true)]
	[string]$solutionDirectory
	) 

Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"

function Load-File ([string]$FilePath){
	Write-Verbose "Reading content of $FilePath"
	[string]$text = [System.IO.File]::ReadAllText($filepath)
	$text
	Write-Verbose "Done Reading content of $FilePath"
}

function Save-File ([string]$FilePath, [string]$Content){
	Write-Verbose "Writing content to $FilePath"
	[System.IO.File]::WriteAllText($filepath, $content, [System.Text.Encoding]::UTF8)
	Write-Verbose "Done Writing content to $FilePath"
}

$importNugetTargets= ('[ \t]*' + [regex]::escape(@'
<Import Project="$(SolutionDir)\.nuget\NuGet.targets" Condition="Exists('$(SolutionDir)\.nuget\NuGet.targets')" />
'@) + '[\r]?[\n]')
$restorePackages = '[ \t]*<RestorePackages>.*?</RestorePackages>[\r]?[\n]'
$nuGetPackageImportStamp = '[ \t]*<NuGetPackageImportStamp>.*?</NuGetPackageImportStamp>[\r]?[\n]'
$ensureNuGetPackageBuildImports = '[ \t]*(?smi)<Target Name="EnsureNuGetPackageBuildImports".*?</Target>[\r]?[\n]'

foreach ($projFile in  Get-ChildItem .\*,.\*\*,.\*\*\* -Path $solutionDirectory -Include *.csproj | sort-object)
{
    $content =  Load-File $projFile.FullName
    $content = $content `
        -replace $importNugetTargets, "" `
        -replace $nuGetPackageImportStamp, "" `
        -replace $restorePackages, "" `
        -replace $ensureNuGetPackageBuildImports, "" 
	Save-File -FilePath $projFile.FullName -Content $content
}
