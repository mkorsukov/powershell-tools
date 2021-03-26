# Loads all dependent scripts

foreach ($script in (Get-ChildItem -Path $PSScriptRoot -Include "*.ps1" -Recurse -Exclude "*.Tests.ps1"))
{
    . $script.FullName
}