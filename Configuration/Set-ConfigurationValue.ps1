# Configuration Updater

[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string] $filePath,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ $_ -match "@" })]
    [string] $path,

    [Parameter(Mandatory = $true)]
    [string] $value
)

function New-MissingElement([xml] $document, [string[]] $elementNames, [string] $attributeName)
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

try
{
    Write-Host "Updating: $filePath"

    $document = [xml](Get-Content -LiteralPath $filePath)
    $fullPath = "$($elementNames -join "/")[string(@$attributeName)]"
    $node = $document.SelectSingleNode($fullPath)

    if (!$node)
    {
        $node = New-MissingElement $document $elementNames $attributeName
    }

    $node.Attributes[$attributeName].Value = $value
    $document.Save($filePath)

    Write-Host "OK" -ForegroundColor Green

    exit 0
}
catch
{
    Write-Host "Error: $_" -ForegroundColor Red

    exit 1
}