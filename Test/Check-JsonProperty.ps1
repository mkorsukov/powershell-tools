# JSON Value Checker

param
(
    [string] $url,
    [string] $property,
    [string] $value
)

Clear-Host
Write-Host "JSON Value Checker 1.0 : Copyright (C) Maxim Korsukov : 2017-02-27" -ForegroundColor Yellow

if (!$url)
{
    Write-Host "Required [URL] is not specified" -ForegroundColor Red
    Exit 1
}

if (!$property)
{
    Write-Host "Required [property] is not specified" -ForegroundColor Red
    Exit 1
}

if (!$value)
{
    Write-Host "Required [value] is not specified" -ForegroundColor Red
    Exit 1
}

Try
{
    Write-Host "Checking $url..."

    $info = Invoke-WebRequest $url -UseBasicParsing | ConvertFrom-Json | Select $property

    Write-Host "Value required: '$($value)', detected: '$($info.$property)'"

    if ($info.$property -ne $value)
    {
        Write-Host "Value mismatch!" -ForegroundColor Red
        Exit 1
    }

    Write-Host "OK" -ForegroundColor Green
    Exit 0
}
Catch [Exception]
{
    Write-Host "Unable to get the version information!" -ForegroundColor Red
    Echo $_.Exception | format-list -force
    Exit 1
}