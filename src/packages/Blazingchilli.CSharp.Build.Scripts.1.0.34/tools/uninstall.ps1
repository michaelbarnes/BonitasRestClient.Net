param($installPath, $tools_path, $package, $project)

If (Test-Path $tools_path\..\..\..\..\default.ps1){
	Remove-Item $tools_path\..\..\..\..\default.ps1
}

If (Test-Path $tools_path\..\..\..\..\build.bat){
	Remove-Item $tools_path\..\..\..\..\build.bat
}

If (Test-Path $tools_path\..\..\..\..\ci.bat){
	Remove-Item $tools_path\..\..\..\..\ci.bat
}

If (Test-Path $tools_path\..\..\..\..\package.bat){
	Remove-Item $tools_path\..\..\..\..\package.bat
}

If (Test-Path $tools_path\..\..\..\..\nugetPackage.bat){
	Remove-Item $tools_path\..\..\..\..\nugetPackage.bat
}
