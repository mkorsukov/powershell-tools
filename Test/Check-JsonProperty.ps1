# JSON Value Checker

[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]
    [string] $url,

    [Parameter(Mandatory = $true)]
    [string] $property,

    [Parameter(Mandatory = $true)]
    [string] $value
)

Clear-Host
Write-Host "JSON Value Checker 1.0 : Copyright (C) Maxim Korsukov : 2017-02-27" -ForegroundColor Yellow

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
    Echo $_.Exception | Format-List -Force

    Exit 1
}