# Web-Site Version Verifier
# Provides the opportunity to verify the web application version

param
(
    [System.String] $appUri,
    [System.String] $appVersion
)

Clear-Host
Write-Host "Web-Site Version Verifier 1.0 : Copyright (C) Maxim Korsukov : 2016-08-23"

if (!$appUri)
{
    Write-Host "Application [URI] is not specified." -ForegroundColor Red
    Exit 1
}

if (!$appVersion)
{
    Write-Host "Application [version] is not specified." -ForegroundColor Red
    Exit 1
}

Try
{
    Write-Host "Checking $appUri..."

    $info = Invoke-WebRequest $appUri -UseBasicParsing | ConvertFrom-Json | Select appVersion

    Write-Host "Version required: $($appVersion), detected: $($info.appVersion)"

    if ($info.appVersion -ne $appVersion)
    {
        Write-Host "Version mismatch!" -ForegroundColor Red
        Exit 1
    }

    Write-Host "OK"  -ForegroundColor Green
    Exit 0
}
Catch [Exception]
{
    Write-Host "Unable to get the version information!" -ForegroundColor Red
    Echo $_.Exception|format-list -force
    Exit 1
}