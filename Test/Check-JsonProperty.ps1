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

try
{
    Write-Host "Checking URL: $url"

    $info = Invoke-WebRequest $url -UseBasicParsing | ConvertFrom-Json | Select-Object $property

    Write-Host "Value required: '$($value)', detected: '$($info.$property)'"

    if ($info.$property -ne $value)
    {
        throw "Value mismatch (required: '$($value)', detected: '$($info.$property)')"
    }

    Write-Host "OK" -ForegroundColor Green

    exit 0
}
catch
{
    Write-Host "Error: $_" -ForegroundColor Red

    exit 1
}