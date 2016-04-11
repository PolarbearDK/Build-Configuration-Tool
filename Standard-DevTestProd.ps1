$ErrorActionPreference = "Stop"
Set-StrictMode -Version latest

$scriptPath = Split-Path $script:MyInvocation.MyCommand.Path
& $scriptPath\Build-Configuration-Tool.ps1 Debug -Copy Dev -Rename Test
if(!$?){throw "Script returned exit code $LASTEXITCODE"}
& $scriptPath\Build-Configuration-Tool.ps1 Release -Rename Prod
if(!$?){throw "Script returned exit code $LASTEXITCODE"}
