# Connection String Updater

[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string] $fileName,

    [Parameter(Mandatory = $true)]
    [string] $connectionName,

    [Parameter(Mandatory = $true)]
    [string] $connectionString
)

Clear-Host
Write-Host "Connection String Updater 1.0 : Copyright (C) Maxim Korsukov : 2016-08-29" -ForegroundColor Yellow

Try
{
    Write-Host "Updating $configurationFile..."

    $document = [xml](Get-Content -LiteralPath $fileName)
    $element = $document.SelectSingleNode("configuration/connectionStrings/add[@name='$connectionName']")

    if (!$element)
    {
        throw "Unable to find connection string: $connectionName"
    }

    $element.connectionString = $connectionString
    $document.Save($fileName) 

    Write-Host "Connection string was successfully updated"
    Write-Host "OK" -ForegroundColor Green

    Exit 0
}
Catch
{
    Write-Host "Unable to update connection string!" -ForegroundColor Red
    Write-Host $_.Exception | Format-List -Force

    Exit 1
}