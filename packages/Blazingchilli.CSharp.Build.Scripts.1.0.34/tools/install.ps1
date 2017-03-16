param($installPath, $tools_path, $package, $project)

Copy-item $tools_path\default.ps1 $tools_path\..\..\..\..\
Copy-item $tools_path\build.bat $tools_path\..\..\..\..\
Copy-item $tools_path\ci.bat $tools_path\..\..\..\..\
Copy-item $tools_path\package.bat $tools_path\..\..\..\..\
Copy-item $tools_path\nugetPackage.bat $tools_path\..\..\..\..\

write-host ""
write-host "========================"
write-host "Setting up build scripts"
write-host "========================"
write-host ""
write-host "Please provide the following values, defaults are shown in brackets."

#TODO: Use $project from https://msdn.microsoft.com/en-us/library/51h9a6ew(v=VS.80) to get the csproj name & location.
#      Then edit http://gitlab-cpt-01.chilli.local/Automation/CSharp.Build.Scripts/blob/master/tools/default.ps1#L23
#      to use the input value for the $fileName and $package_preset_parameters there. Also need to update the build.bat,
#      ci.bat and finally the package.bat to include this value as a parameter.

#region Project and Parameter filenames

Write-Host `n`n"Project and Parameter filenames:"

# $tools_path as string
$root_path               = (Get-Item $tools_path).Parent.Parent.Parent.Parent.FullName

# The +1/-1 is used to adjust for removing the '\' at the beginning of the path.
$project_filename         = ($project.FullName).Substring($root_path.Length + 1, ($project.Fullname).Length - $root_path.Length - 1)

# The +7 represents the length of the '.csproj' extension.
$package_preset_parameters = $project_filename.Substring(0, $project_filename.Length - (($project.Name).Length + 7)) + "parameters.xml"

$solution_files = @(Get-ChildItem $root_path -include *.sln -Recurse)

if ($solution_files.Count -gt 1) {
    write-host "Error: There is more than 1 solution file present in the repository!"
    exit 1
} elseif ($solution_files.Count -eq 0) {
    write-host "Error: There is no solution file present in the repository!"
    exit 1
}

$current_directory = ((Resolve-Path .\).Path + "\") -replace "\\", "\\"
$solution_filename = ($solution_files[0].FullName) -replace $current_directory, ""

Write-Host `t$project_filename
Write-Host `t$package_preset_parameters
Write-Host `t$solution_filename`n

#endregion

$project_owner            = Read-Host " - Who is the owner of the project(Blazingchilli, Zing, OldMutual)? [Blazingchilli]"
if ([string]::IsNullOrEmpty($project_owner)) {
  $project_owner           = "Blazingchilli"
}

$project_name             = Read-Host " - What is the deployable project's name? [$($project.Name)]"
if ([string]::IsNullOrEmpty($project_name)) {
  $project_name           = "$($project.Name)"
}

$project_short_name       = Read-Host " - What is the project's short name? [$project_name]"
if ([string]::IsNullOrEmpty($project_short_name)) {
  $project_short_name     = "$project_name"
}

$integration_test_config_file = ""
$database_server = "data-cpt-01.chilli.local"

Get-ChildItem $tools_path\..\..\..\..\ -Recurse |
  Where-Object { !$PsIsContainer -and [System.IO.Path]::GetFileName($_.Name) -eq "app.config" } |
  Where-Object { $_.fullname -like '*IntegrationTests*' } |
  ForEach-Object { $integration_test_config_file = $_.fullname.Substring($root_path.Length + 1, ($_.fullname.Length - $root_path.Length - 1)) }

$integration_test_config_file

write-host ""
write-host "$project_name -- $project_short_name"

$build_parameters   = "'solution_filename'='$solution_filename'; 'project_name'='$project_name'; 'short_project_name'='$project_short_name'; 'project_filename'='$project_filename'; 'package_preset_parameters'='$package_preset_parameters'; 'integration_test_config_file'='$integration_test_config_file'"
$build_properties   = "'version_tag_must_match_revision'='$false';"

$ci_parameters      = "'solution_filename'='$solution_filename'; 'project_name'='$project_name'; 'short_project_name'='$project_short_name'; 'project_filename'='$project_filename'; 'package_preset_parameters'='$package_preset_parameters'; 'integration_test_config_file'='$integration_test_config_file'"
$ci_properties      = "'version_tag_must_match_revision'='$false'"

$package_parameters = "'solution_filename'='$solution_filename'; 'project_name'='$project_name'; 'short_project_name'='$project_short_name'; 'project_filename'='$project_filename'; 'package_preset_parameters'='$package_preset_parameters'; 'project_owner'='$project_owner'; 'integration_test_config_file'='$integration_test_config_file'; 'database_server'='$database_server'"
$package_properties = ""

$nuget_parameters   = "'solution_filename'='$solution_filename'; 'project_name'='$project_name'; 'short_project_name'='$project_short_name'; 'project_filename'='$project_filename'; 'integration_test_config_file'='$integration_test_config_file'; 'database_server'='$database_server'"
$nuget_properties   = ""

Get-ChildItem $tools_path\..\..\..\..\*.* -include build.bat,ci.bat,package.bat,nugetPackage.bat  |
 foreach-object { $a = $_.fullname; write-host $a; ( get-content $a ) |
   foreach-object { $_ -replace "build_parameters", "$build_parameters" `
    -replace "build_properties", "$build_properties" `
    -replace "ci_parameters", "$ci_parameters" `
    -replace "ci_properties", "$ci_properties" `
    -replace "package_parameters", "$package_parameters" `
    -replace "package_properties", "$package_properties" `
    -replace "nuget_parameters", "$nuget_parameters" `
    -replace "nuget_properties", "$nuget_properties" } |
    set-content $a }

Get-ChildItem $tools_path\..\..\..\..\src\packages\NUnit.Runners.2.6.4\tools\*.* -include nunit-console.exe.config  |
 foreach-object { $a = $_.fullname; write-host $a; ( get-content $a ) |
   foreach-object { $_ -replace '!-- Comment out the next line to force use of .NET 4.0 --', 'supportedRuntime version="v4.0"/' } |
    set-content $a }
