# Build-Configuration-Tool
Script that Renames, Copies &amp; Deletes Visual Studio Build Configurations

Supported files | Changes
--- | ---
Solution files (.sln) | Modifies solution build configuration
msbuild files (.csproj .vbproj .scproj ect.) | Modifies project build configuration. References Config transformations are handled too.

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
Build-Configuration-Tool Release -Rename Production -Copy QA 
```
This command finds the "Release" build configuration, renames it to "Production" and copies it to "QA".