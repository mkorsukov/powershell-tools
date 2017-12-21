# Loads all dependent scripts

foreach ($script in (Get-ChildItem -Path $PSScriptRoot\*.ps1 -Recursive -Exclude "*.Tests.*", "_*"))
{
    . $script.FullName
}