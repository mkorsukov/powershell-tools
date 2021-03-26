# Database Updater

[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ $_ -match "Data Source=" })]
    [string] $connectionString,

    [Parameter(Mandatory = $true)]
    [AllowNull()]
    [ValidateScript({ Test-Path -Path $_ })]
    [string] $schemaFile = $null,

    [Parameter(Mandatory = $true)]
    [AllowNull()]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string] $patchFolder = $null,

    [Parameter(Mandatory = $false)]
    [bool] $useVersioning = $true,

    [switch] $useVersioning
)

function Invoke-Sql([string] $connectionString, [string] $script)
{
    $connection = New-Object System.Data.SQLClient.SQLConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()

    $parts = $script -split "`r`ngo`r`n"

    foreach ($part in $parts)
    {
        if (![System.String]::IsNullOrWhiteSpace($part))
        {
            $command = New-Object System.Data.SqlClient.SqlCommand
            $command.Connection = $connection
            $command.CommandType = [System.Data.CommandType]::Text
            $command.CommandText = $part

            $command.ExecuteNonQuery() | Out-Null
            $command.Dispose()
        }
    }

    $connection.Close()
    $connection.Dispose()
}

function Get-PatchesTableExistence([string] $connectionString)
{
    $connection = New-Object System.Data.SQLClient.SQLConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()

    $command = New-Object System.Data.SqlClient.SqlCommand
    $command.Connection = $connection
    $command.CommandType = [System.Data.CommandType]::Text
    $command.CommandText = "
        if (exists(select * from information_schema.tables where [TABLE_NAME] = N'_Patches'))
            select 1;
        else
            select 0;"

    [int] $result = $command.ExecuteScalar()

    $command.Dispose()

    $connection.Close()
    $connection.Dispose()

    return $result
}

function Get-ExistingPatches([string] $connectionString)
{
    $connection = New-Object System.Data.SQLClient.SQLConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()

    $command = New-Object System.Data.SqlClient.SqlCommand
    $command.Connection = $connection
    $command.CommandType = [System.Data.CommandType]::Text
    $command.CommandText = "select [Name] from [_Patches] order by [ID];"

    $reader = $command.ExecuteReader()
    $result = @()

    while ($reader.Read())
    {
        $result += $reader.GetString(0)
    }

    $reader.Dispose()
    $command.Dispose()
    $connection.Close()
    $connection.Dispose()

    return $result
}

function Add-PatchTable([string] $connectionString)
{
    $script = Get-Content $schemaFile -Raw -Encoding UTF8

    Run-Sql $connectionString $script

    if ($useVersioning)
    {
        $script = "
            if (not exists(select * from information_schema.tables where [TABLE_NAME] = N'_Patches'))
            begin
                create table [_Patches]
                (
                    [ID] int identity(1,1) not null,
                    [Name] varchar(255) not null,
                    [User] varchar(255) not null,
                    [Date] datetimeoffset(0) not null,

                    constraint [PK__Patches_ID] primary key ([ID])
                );
                create unique nonclustered index [IX__Patches_Name] on [_Patches] ([Name]);
            end"

        Run-Sql $connectionString $script
        Run-Sql $connectionString "insert into [_Patches] ([Name], [User], [Date]) values ('$([System.IO.Path]::GetFileName($schemaFile))', original_login(), sysdatetimeoffset());"
    }
}

function Add-PatchInfo([string] $connectionString, [string] $name)
{
    Invoke-Sql $connectionString "insert into [_Patches] ([Name], [User], [Date]) values ('$name', original_login(), sysdatetimeoffset());"
}

Clear-Host
Write-Host "Database Updater 1.0 : Copyright (C) Maxim Korsukov : 2017-10-22" -ForegroundColor Yellow

Exit 0

if (!$connectionString)
{
    Write-Host "Error: Specified database schema file doesn't exist" -ForegroundColor Red

    exit 1
}

if ($patchFolder -and !(Test-Path $patchFolder -PathType Container))
{
    Write-Host "Error: Specified database patch folder doesn't exist" -ForegroundColor Red

    exit 1
}

if (!$schemaFile -and !$patchFolder)
{
    Write-Host "Error: No schema file or patch folder specified" -ForegroundColor Red

    exit 1
}

$existingPatches = @()

if ($useVersioning)
{
    Add-PatchTable $connectionString

    $existingPatches = Get-ExistingPatches $connectionString
}

if ($schemaFile)
{
    try
    {
        $scriptFile = [System.IO.Path]::GetFileName($schemaFile)

        if ($existingPatches -notcontains $scriptFile)
        {
            $script = Get-Content $schemaFile -Raw -Encoding UTF8

            Write-Host "Applying schema: $scriptFile"
            Invoke-Sql $connectionString $script

            if ($useVersioning)
            {
                Add-PatchInfo $connectionString $scriptFile
            }
        }
        else
        {
            Write-Host "Skipping schema: $scriptFile"
        }
    }
    catch
    {
        Write-Host "Error: $_" -ForegroundColor Red

        exit 1
    }
}

if ($patchFolder)
{
    try
    {
        $patchFiles = Get-ChildItem -Path $patchFolder -Include "*.sql" -File -Name

        foreach ($patchFile in $patchFiles)
        {
            if ($existingPatches -notcontains $patchFile)
            {
                $filePath = Join-Path $patchFolder $patchFile
                $script = Get-Content $filePath -Raw -Encoding UTF8

                Write-Host "Applying patch: $patchFile"
                Invoke-Sql $connectionString $script

                if ($useVersioning)
                {
                    Add-PatchInfo $connectionString $patchFile
                }
            }
            else
            {
                Write-Host "Skipping patch: $patchFile"
            }
        }
    }
    catch
    {
        Write-Host "Error: $_" -ForegroundColor Red

        exit 1
    }
}

Write-Host "OK" -ForegroundColor Green

exit 0