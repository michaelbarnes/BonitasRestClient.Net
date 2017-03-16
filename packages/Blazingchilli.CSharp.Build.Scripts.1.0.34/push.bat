nuget pack Blazingchilli.CSharp.Build.Scripts.nuspec
nuget push Blazingchilli.CSharp.Build.Scripts.*.nupkg -s \\team-cpt-01.chilli.local\NuGet
del Blazingchilli.CSharp.Build.Scripts.*.nupkg
