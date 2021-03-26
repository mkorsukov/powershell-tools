# Connection String Updater

[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string] $filePath,

    [Parameter(Mandatory = $true)]
    [string] $connectionName,

    [Parameter(Mandatory = $true)]
    [string] $connectionString
)

Clear-Host
Write-Host "Connection String Updater 1.0 : Copyright (C) Maxim Korsukov : 2016-08-29" -ForegroundColor Yellow

try
{
    Write-Host "Updating: $filePath"

    $document = [xml](Get-Content -LiteralPath $filePath)
    $element = $document.SelectSingleNode("configuration/connectionStrings/add[@name='$connectionName']")

    if (!$element)
    {
        throw "Unable to find connection string by name '$connectionName'"
    }

    $element.connectionString = $connectionString
    $document.Save($filePath)

    Write-Host "OK" -ForegroundColor Green

    exit 0
}
catch
{
    Write-Host "Error: $_" -ForegroundColor Red

    exit 1
}