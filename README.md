# Build-Configuration-Tool
Script that Renames, Copies &amp; Deletes Visual Studio Build Configurations

Supported files : 
- .sln
- .csproj
- .vbproj
- .scproj

Config transformation files are also supported

### Rename Build Configuration
```powershell
Build-Configuration-Tool Debug -Rename Test
```
This command replaces the "Debug" build configuration with one called "Test".

### Copy Build Configuration
```powershell
Build-Configuration-Tool Release -Copy Prod
```
This command copies the "Release" build configuration to "Prod".

### Delete Build Configuration
```powershell
Build-Configuration-Tool Release -Delete
```
This command deletes the "Release" build configuration.

### Copy and Rename Build Configuration in one operation 
```powershell
Build-Configuration-Tool Release -Rename Production -Copy QA -Suffix .try
```
This command finds the "Release" build configuration, renames it to "Production" and copies it to "QA".