# Generate build label
if($env:BUILD_NUMBER -ne $null) {
    $env:buildlabel = "$env:BUILD_TAG on $(Get-Date -Format g)"
    $env:buildconfig = "Release"
    $env:manualbuild = $false
}
else {
    $env:buildlabel = "Manual Build on $(Get-Date -Format g)"
    $env:buildconfig = "Debug"
    $env:manualbuild = $true
}

Framework "4.0"

properties {
    $project_config = $env:buildconfig
    $base_dir = resolve-path .\
    $source_dir = "$base_dir\src"
    $tools_dir = resolve-path .\src\packages

    $package_deploy_path = "Default Web Site/$short_project_name"
    $package_preset_parameters = "$source_dir\$project_name\parameters.xml"

    $artifact_location = "\\team-cpt-01.chilli.local\BuildArtifacts\_$project_owner\$project_name"

    $database_name = "$short_project_name" + "_IntegrationTests"

    $nuget_project_name = "$source_dir\$project_name\$project_name.csproj"
    $nuget_spec_file = "$source_dir\$project_name\$project_name.nuspec"
    $nuget_push_location = "\\team-cpt-01.chilli.local\NuGet"

    $nunit_runner = "$tools_dir\NUnit.Runners.2.6.4\tools\nunit-console.exe"
    $nuget = "$tools_dir\NuGet.CommandLine.2.8.6\tools\NuGet.exe"

    $build_dir = "$base_dir\build"
    $test_dir = "$build_dir\test"
    $dist_dir = "$base_dir\dist"
    $test_copy_ignore_path = "_ReSharper"
    $current_branch = Determine-Git-Branch
    $version = Generate-Semantic-Version-Number
}

task default -depends PrintVariables, Init, Compile, Test
task CI -depends Init, CommonAssemblyInfo, SetTestsConnectionString, Compile , Test
task Package -depends Init, CommonAssemblyInfo, SetTestsConnectionString, Compile, Test, MsBuildPackage

task Init {
    delete_file $package_file
    delete_directory $build_dir
    create_directory $test_dir
    create_directory $build_dir
    delete_directory $dist_dir
    create_directory $dist_dir
    delete_directory $dist_dir\$version
    create_directory $dist_dir\$version
}

task PrintVariables {
  write-host "  ~~~~~~~~ " -ForegroundColor DarkGreen
  write-host "ProjectName: $project_name" -ForegroundColor DarkGreen
  write-host "ShortProjectName: $short_project_name" -ForegroundColor DarkGreen
  write-host "SolutionFilename: $solution_filename" -ForegroundColor DarkGreen
  write-host "ProjectConfig: $project_config" -ForegroundColor DarkGreen
  write-host "BaseDir: $base_dir" -ForegroundColor DarkGreen
  write-host "ToolsDir: $tools_dir" -ForegroundColor DarkGreen
  write-host "Version: [$version]" -ForegroundColor DarkGreen
  write-host "  ~~~~~~~~ " -ForegroundColor DarkGreen
}

# Compiles the solution using msbuild.
task Compile -depends Init {
	write-host "MSBuild config: $project_config"
  exec {
   & msbuild /t:Clean`;Rebuild /p:VisualStudioVersion=12.0 /v:q /nologo /p:Configuration=$project_config $source_dir\$solution_filename /p:NoWarn=1591 /p:Platform="Any CPU"
  }
}

# This task is used to set the connection string for the integration tests. This is needed as local developers would use localhost,
# but the build server requires a dedicated, non-localhost database server.
task SetTestsConnectionString {

  if (($integration_test_config_file) -and (Test-Path "$integration_test_config_file")) {
    $connection_string = "Data Source=$database_server;Initial Catalog=$database_name; Integrated Security=true;"
    write-host "Using connection string: $connection_string" -ForegroundColor Green
    poke-xml $integration_test_config_file "/configuration/connectionStrings/add[@name='NHibernateConnection']/@connectionString" $connection_string @{"e" = ""}
  }
   else {
    write-host "No integration tests found, not setting connection string for it." -ForegroundColor Yellow
  }
}

# Will package the default project as a msdeploy package, zip it up and copied it to
# \\team-cpt-01\BuildArtifacts.
task MsBuildPackage {
  write-host "Building the package: [$project_name]-[$version]-[$project_config]" -ForegroundColor Green

  $package_location = "$dist_dir"
  $packageZip = "$package_location\$version\$project_name.zip"

  exec {
    & msbuild /t:Package /v:q /p:VisualStudioVersion=12.0 /p:Configuration=$project_config /p:PackageLocation=$packageZip /p:ProjectParametersXMLFile=$package_preset_parameters /p:DeployIisAppPath=$package_deploy_path $project_filename
  }

  if ($current_branch.StartsWith("develop"))
  {
    $fullPackageZip = "$dist_dir\$project_name.DEV.$version.zip"
    $latestPackageZip = "$project_name.DEV.zip"
  }
  else
  {
    $fullPackageZip = "$dist_dir\$project_name.$version.zip"
    $latestPackageZip = "$project_name.PROD.zip"
  }

  New-Item -Force -ItemType directory -Path $artifact_location

  Zip-Directory -DestinationFileName $fullPackageZip -SourceDirectory $package_location\$version

  if ($current_branch.StartsWith("develop"))
  {
    write-host "Uploading DEV build artifacts:" -ForegroundColor Yellow
    write-host "==========================" -ForegroundColor Yellow
    write-host "Version: [$project_name]-[$project_config]" -ForegroundColor Yellow
    write-host "From: [$package_location]" -ForegroundColor Yellow
    write-host "To: [$artifact_location]" -ForegroundColor Yellow
    write-host "To: [$artifact_location\$latestPackageZip]" -ForegroundColor Yellow
  }
  else
  {
    write-host "Uploading build artifacts:" -ForegroundColor Green
    write-host "==========================" -ForegroundColor Green
    write-host "Version: [$project_name]-[$version]-[$project_config]" -ForegroundColor Green
    write-host "From: [$package_location]" -ForegroundColor Green
    write-host "To: [$artifact_location]" -ForegroundColor Green
    write-host "To: [$artifact_location\$latestPackageZip]" -ForegroundColor Green

  }
  Copy-Item $fullPackageZip $artifact_location
  Copy-Item $fullPackageZip $artifact_location\$latestPackageZip
  Copy-Item $fullPackageZip $dist_dir\$latestPackageZip
}

task NuGetPackage -depends Init, PrintVariables, CommonAssemblyInfo, Compile, Test {
  poke-xml $nuget_spec_file "//e:id" $project_name @{"e" = ""}
  poke-xml $nuget_spec_file "//e:version" $version @{"e" = ""}

  exec {
    & $nuget pack $nuget_project_name -NoPackageAnalysis -Build -Symbols -verbosity detailed -o $build_dir -Version $version  -p Configuration="release"
  }

  exec {
    & $nuget push $build_dir\$project_name.$version.nupkg -s $nuget_push_location
  }
}

# Builds the required binaries, copies them to the test directory and then runs the unit
# and / or integration tests
task Test {
  copy_all_assemblies_for_test $test_dir

  $testsToRun = ""

  write-host "NUnit: $nunit_runner"

  $testAssemblyPrefix = "build\test\" + ($solution_filename -replace ".sln", "")

  $unitTestAssembly = "$testAssemblyPrefix.UnitTests.dll"
  $unitTestAssemblyExists = (Test-Path $unitTestAssembly);
  write-host  "UnitTestAssembly: $unitTestAssembly"
  if ($unitTestAssemblyExists) {
    write-host "Found unit tests: $unitTestAssembly"
  } else {
    write-host "No Unit test project found" -ForegroundColor Yellow
    $unitTestAssembly = ""
  }

  $integrationTestAssembly = "$testAssemblyPrefix.IntegrationTests.dll"
  $integrationTestAssemblyExists = (Test-Path $integrationTestAssembly);
  write-host "IntegrationTestAssembly: $integrationTestAssembly"
  if ($integrationTestAssemblyExists) {
    write-host "Found integration tests: $integrationTestAssembly"
  } else {
    write-host "No Integration test project found" -ForegroundColor Yellow
    $integrationTestAssembly = ""
  }

  if (!$unitTestAssemblyExists -And !$integrationTestAssemblyExists) {
    write-host "No unit or integration tests found, please add them to the project before continuing." -ForegroundColor Red
    # If you don't want the default behavior to be an error if tests are missing, change the status code to 0. This will
    # however require you to also remove the JUnit report step in the Jenkins job, so would advice against it.
    exit 1
  }

  if($env:manualbuild = $true) {
    write-host "$nunit_runner $testsToRun /xml=$build_dir\TestResult.xml /framework:net-4.0"
	  exec {
  		& $nunit_runner $unitTestAssembly $integrationTestAssembly /xml=$build_dir\TestResult.xml /framework:net-4.0
    }
  } else {
	  exec {
  		& $nunit_runner $unitTestAssembly $integrationTestAssembly  /nologo /nodots /xml=$build_dir\TestResult.xml /framework:net-4.0
  	}
  }
}

task CommonAssemblyInfo -depends PrintVariables{
    Update-AssemblyInfoFiles $version
}

function global:Load-WebPackage-Parameters {

	Write-Host " - Loading web deploy parameters '$PathToParamsFile'..." -NoNewline
	$WDParameters = Get-WDParameters -FilePath $packageParameters -ErrorAction:SilentlyContinue -ErrorVariable e

	if($? -eq $false) {
		throw " - Get-WDParameters failed: $e"
	}
	Write-Host "OK" -ForegroundColor Green

	return $WDParameters
}

function global:Determine-Git-Branch {

  $branch = "develop"
  if ($env:GIT_BRANCH -ne $null) {
    write-host "Looks like a build server build, getting the branch."
    $branch = $env:GIT_BRANCH
  }

  if (!$current_branch) {
    write-host "Looks like current branch is null, defaulting to 'develop'" -ForegroundColor Yellow
  }
  write-host "Current branch is [$current_branch]" -ForegroundColor Yellow

  return $branch -replace "origin/", ""
}

function global:Generate-Semantic-Version-Number {

  $result = "0.0.1"

  if ($current_branch.Equals("master") -or $current_branch.Equals("HEAD")) {
    try {
      $result = git describe --exact-match --abbrev=0 2>&1
    }
    catch
    {
      write-host "Unable to determine correct version from git tag. This is likely due to a missing tag on the master branch, or having committed directly to the branch." -ForegroundColor Red
      throw ""
    }
  } elseif ($current_branch.Equals("develop")) {
    try {
      $result = git describe --exact-match --abbrev=0 2>&1
    }
    catch
    {
      write-host "Unable to determine correct version from git tag. Because this is the [$current_branch], it is fine, we will set a default value." -ForegroundColor Yellow
    }
  }

  $result = $result -replace "`n","" -replace "`r",""
  write-host "Determined version on [$current_branch] with value [$result]" -ForegroundColor Yellow

  if($env:BUILD_NUMBER -ne $null) {
    $result = $result + ".$env:BUILD_NUMBER"
  }
  else {
    $today = Get-Date
    $result = $result + "." + ( ($today.year - 2000) * 1000 + $today.DayOfYear )
  }

  return $result
}

function global:Update-AssemblyInfoFiles ([string] $versionString) {
    $commonAssemblyInfo = "$source_dir\CommonAssemblyInfo.cs"

    $assemblyDescriptionPattern = 'AssemblyDescription\("(.*?)"\)'
    $assemblyDescription = 'AssemblyDescription("' + $env:buildlabel + '")';

    $assemblyVersionPattern = 'AssemblyVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)'
    $assemblyVersion = 'AssemblyVersion("' + $versionString + '")';

    $fileVersionPattern = 'AssemblyFileVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)'
    $fileVersion = 'AssemblyFileVersion("' + $versionString + '")';

    Get-ChildItem $source_dir -r -filter AssemblyInfo.cs | ForEach-Object {
        $filename = $_.Directory.ToString() + '\' + $_.Name
        $filename + ' -> ' + $versionString

        # If you are using a source control that requires to check-out files before
        # modifying them, make sure to check-out the file here.
        # For example, TFS will require the following command:
        # tfs checkout $filename

        (Get-Content $commonAssemblyInfo) | ForEach-Object {
            % {$_ -replace $assemblyVersionPattern, $assemblyVersion } |
            % {$_ -replace $assemblyDescriptionPattern, $assemblyDescription } |
            % {$_ -replace $fileVersionPattern, $fileVersion }
        } | Set-Content $filename
    }
}

function global:copy_website_files($source,$destination){
    $exclude = @('*.user','*.dtd','*.tt','*.cs','*.csproj','*.orig', '*.log')
    copy_files $source $destination $exclude
    delete_directory "$destination\obj"
}

function global:copy_files($source,$destination,$exclude=@()){
    create_directory $destination
    Get-ChildItem $source -Recurse -Exclude $exclude | Copy-Item -Destination {Join-Path $destination $_.FullName.Substring($source.length)}
}

function global:Copy_and_flatten ($source, $filter, $dest) {
  ls $source -filter $filter  -r | Where-Object{!$_.FullName.Contains("$test_copy_ignore_path") -and !$_.FullName.Contains("packages") }| cp -dest $dest -force
}

function global:copy_all_assemblies_for_test($destination){
  create_directory $destination
  Copy_and_flatten $source_dir *.exe $destination
  Copy_and_flatten $source_dir *.dll $destination
  Copy_and_flatten $source_dir *.config $destination
  Copy_and_flatten $source_dir *.xml $destination
  Copy_and_flatten $source_dir *.pdb $destination
  Copy_and_flatten $source_dir *.sql $destination
  Copy_and_flatten $source_dir *.xlsx $destination
}

function global:delete_file($file) {
    if($file) { remove-item $file -force -ErrorAction SilentlyContinue | out-null }
}

function global:delete_directory($directory_name)
{
    rd $directory_name -recurse -force  -ErrorAction SilentlyContinue | out-null
}

function global:delete_files_in_dir($dir)
{
    get-childitem $dir -recurse | foreach ($_) {remove-item $_.fullname}
}

function global:create_directory($directory_name)
{
  mkdir $directory_name  -ErrorAction SilentlyContinue  | out-null
}

function global:Zip-Directory {
    Param(
      [Parameter(Mandatory=$True)][string]$DestinationFileName,
      [Parameter(Mandatory=$True)][string]$SourceDirectory,
      [Parameter(Mandatory=$False)][string]$CompressionLevel = "Optimal",
      [Parameter(Mandatory=$False)][switch]$IncludeParentDir
    )
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $CompressionLevel    = [System.IO.Compression.CompressionLevel]::$CompressionLevel
    [System.IO.Compression.ZipFile]::CreateFromDirectory($SourceDirectory, $DestinationFileName, $CompressionLevel, $IncludeParentDir)
}

function script:poke-xml($file_path, $xpath, $value, $namespaces = @{}) {
    [xml] $fileXml = Get-Content $file_path

    if($namespaces -ne $null -and $namespaces.Count -gt 0) {
        $ns = New-Object Xml.XmlNamespaceManager $fileXml.NameTable
        $namespaces.GetEnumerator() | %{ $ns.AddNamespace($_.Key,$_.Value) }
        $node = $fileXml.SelectSingleNode($xpath,$ns)
    } else {
        $node = $fileXml.SelectSingleNode($xpath)
    }

    if($node -eq $null) {
        return
    }

    if($node.NodeType -eq "Element") {
        $node.InnerText = $value
    } else {
        $node.Value = $value
    }

    $fileXml.Save($file_path)
}

function script:poke-xml-attribute($file_path, $xpath, $attribute, $value, $namespaces = @{}) {
    [xml] $fileXml = Get-Content $file_path

    if($namespaces -ne $null -and $namespaces.Count -gt 0) {
        $ns = New-Object Xml.XmlNamespaceManager $fileXml.NameTable
        $namespaces.GetEnumerator() | %{ $ns.AddNamespace($_.Key,$_.Value) }
        $node = $fileXml.SelectSingleNode($xpath,$ns)
    } else {
        $node = $fileXml.SelectSingleNode($xpath)
    }

    if($node -eq $null) {
        return
    }

	$node.SetAttribute($attribute, $value)

    $fileXml.Save($file_path)
}

function global:create-commonAssemblyInfo($version,$applicationName,$filename)
{
"using System.Reflection;
using System.Runtime.InteropServices;
//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//     Runtime Version:2.0.50727.4927
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------
[assembly: ComVisibleAttribute(false)]
[assembly: AssemblyVersionAttribute(""$version"")]
[assembly: AssemblyFileVersionAttribute(""$version"")]
[assembly: AssemblyCopyrightAttribute(""Copyright 2010-2015"")]
[assembly: AssemblyProductAttribute(""$applicationName"")]
[assembly: AssemblyCompanyAttribute(""Blazingchilli"")]
[assembly: AssemblyConfigurationAttribute(""release"")]
[assembly: AssemblyInformationalVersionAttribute(""$version"")]"  | out-file $filename -encoding "ASCII"
}
