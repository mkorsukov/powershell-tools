# Folder Remover
# Allows to cleanup the specified directory

[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string] $folderPath
)

Clear-Host
Write-Host "Folder Remover 1.0 : Copyright (C) Maxim Korsukov : 2017-08-01" -ForegroundColor Yellow

Write-Host "Cleaning folder '$folderPath'..."
Get-ChildItem -Path "$folderPath" -include @('bin', 'obj', 'packages') -Directory -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

Write-Host "OK" -ForegroundColor Green

Exit 0