# Web-Site Connection String Updater
# Provides the opportunity to update the connection string for a web application

param
(
    [string] $file,
    [string] $name,
    [string] $value
)

Clear-Host
Write-Host "Web-Site Connection String Updater 1.0 : Copyright (C) Maxim Korsukov : 2016-08-29"

if (!$file)
{
    Write-Host "Configuration file name/path is not specified." -ForegroundColor Red
    Exit 1
}

if (!$name)
{
    Write-Host "Database connection name is not specified." -ForegroundColor Red
    Exit 1
}

if (!$value)
{
    Write-Host "Database connection string is not specified." -ForegroundColor Red
    Exit 1
}

Try
{
    Write-Host "Updating $file..."

    $config = [xml](Get-Content -LiteralPath $file)
    $connStringElement = $config.SelectSingleNode("configuration/connectionStrings/add[@name='$name']")

    if(!$connStringElement)
    {
        Write-Host "Unable to locate connection string named: $name." -ForegroundColor Red
        Exit 1
    }

    $connStringElement.connectionString = $value
    $config.Save($file) 

    Write-Host "Connection string was successfully updated."
    Write-Host "OK"  -ForegroundColor Green
    Exit 0
}
Catch [Exception]
{
    Write-Host "Unable to update the connection string!" -ForegroundColor Red
    Echo $_.Exception|format-list -force
    Exit 1
}