# Connection String Updater

param
(
    [string] $fileName,
    [string] $connectionName,
    [string] $connectionString
)

Clear-Host
Write-Host "Connection String Updater 1.0 : Copyright (C) Maxim Korsukov : 2016-08-29"

if (!$fileName)
{
    Write-Host "Required configuration file name/path is not specified" -ForegroundColor Red
    Exit 1
}

if (!$connectionName)
{
    Write-Host "Required database connection name is not specified" -ForegroundColor Red
    Exit 1
}

if (!$connectionString)
{
    Write-Host "Required database connection string is not specified" -ForegroundColor Red
    Exit 1
}

Try
{
    Write-Host "Updating $configurationFile..."

    $config = [xml](Get-Content -LiteralPath $fileName)
    $element = $config.SelectSingleNode("configuration/connectionStrings/add[@name='$connectionName']")

    if (!$element)
    {
        Write-Host "Unable to find connection string: $connectionName" -ForegroundColor Red
        Exit 1
    }

    $element.connectionString = $connectionString
    $config.Save($configurationFile) 

    Write-Host "Connection string was successfully updated"
    Write-Host "OK" -ForegroundColor Green
    Exit 0
}
Catch [Exception]
{
    Write-Host "Unable to update connection string!" -ForegroundColor Red
    Echo $_.Exception | format-list -force
    Exit 1
}