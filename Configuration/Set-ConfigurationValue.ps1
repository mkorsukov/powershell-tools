# Configuration Updater

[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string] $fileName,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ $_ -match "@" })]
    [string] $path,

    [Parameter(Mandatory = $true)]
    [string] $value
)

function Create-MissingElement([xml] $document, [string[]] $elementNames, [string] $attributeName)
{
    $pathToVerify = ""

    foreach ($elementName in $elementNames)
    {
        if ($pathToVerify.Length -eq 0)
        {
            $pathToVerify += $elementName
        }
        else
        {
            $pathToVerify += "/" + $elementName
        }

        $element = $document.SelectSingleNode($pathToVerify)

        if ($element)
        {
            $finalElement = $element
        }
        else
        {
            $newElement = $document.CreateElement($elementName)
            $finalElement.AppendChild($newElement) | Out-Null
            $finalElement = $newElement
        }
    }

    $finalElement.Attributes.Append($document.CreateAttribute($attributeName)) | Out-Null

    return $finalElement
}

Clear-Host
Write-Host "Configuration Updater 1.0 : Copyright (C) Maxim Korsukov : 2017-11-10" -ForegroundColor Yellow

$elementNames = @()
$attributeName = ""

foreach ($part in $path.Split("/", [System.StringSplitOptions]::RemoveEmptyEntries))
{
    if (!$part.Contains("@"))
    {
        $elementNames += $part
    }
    else
    {
        $elementAndAttribute = ($part -split "@")
        $elementNames += $elementAndAttribute[0]
        $attributeName = $elementAndAttribute[1]
        
        break
    }
}

Try
{
    Write-Host "Updating $fileName..."

    $document = [xml](Get-Content -LiteralPath $fileName)
    $fullPath = "$($elementNames -join "/")[string(@$attributeName)]"
    $node = $document.SelectSingleNode($fullPath)
    $result = "updated"

    if (!$node)
    {
        $node = Create-MissingElement $document $elementNames $attributeName
        $result = "created"
    }

    $node.Attributes[$attributeName].Value = $value
    $document.Save($fileName)

    Write-Host "Configuration value was successfully $result"
    Write-Host "OK" -ForegroundColor Green

    Exit 0
}
Catch [Exception]
{
    Write-Host "Unable to update configuration value!" -ForegroundColor Red
    Echo $_.Exception | Format-List -Force

    Exit 1
}