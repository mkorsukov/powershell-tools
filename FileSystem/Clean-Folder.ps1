# Folder Remover
# Allows to cleanup the specified directory

param
(
    [string] $folderPath
)

Clear-Host
Write-Host "Folder Remover 1.0 : Copyright (C) Maxim Korsukov : 2017-08-01"

if (!$folderPath)
{
    Write-Host "Required folder path is not specified" -ForegroundColor Red
    Exit 1
}

if (!(Test-Path $folderPath))
{
    Write-Host "Required folder doesn't exist" -ForegroundColor Red
    Exit 1
}

Write-Host "Cleaning folder '$folderPath'..."
Get-ChildItem -Path "$folderPath" -include @('bin', 'obj', 'packages') -Directory -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

Write-Host "OK" -ForegroundColor Green
Exit 0