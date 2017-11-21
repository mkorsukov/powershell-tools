# Database Updater

param
(
    [string] $connectionString,
    [string] $schemaFile = $null,
    [string] $patchFolder = $null,
    [bool] $useVersioning = $true
)

function Check-Connection([string] $connectionString)
{
    Run-Sql $connectionString "select @@version;"
}

function Run-Sql([string] $connectionString, [string] $script)
{
    $connection = New-Object System.Data.SQLClient.SQLConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()

    $parts = $script -split "go`r`n"

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

function Add-PatchInfo([string] $connectionString, [string] $name)
{
    Run-Sql $connectionString "insert into [_Patches] ([Name], [User], [Date]) values ('$name', original_login(), sysdatetimeoffset());"
}

Clear-Host
Write-Host "Database Updater 1.0 : Copyright (C) Maxim Korsukov : 2017-10-22" -ForegroundColor Yellow

if (!$connectionString)
{
    Write-Host "Required database connection string is not specified" -ForegroundColor Red
    Exit 1
}

if ($schemaFile -and !(Test-Path $schemaFile -PathType Leaf))
{
    Write-Host "Specified database schema file doesn't exist" -ForegroundColor Red
    Exit 1
}

if ($patchFolder -and !(Test-Path $patchFolder -PathType Container))
{
    Write-Host "Specified database patch folder doesn't exist" -ForegroundColor Red
    Exit 1
}

if ($schemaFile -or $patchFolder)
{
    Try
    {
        Check-Connection $connectionString
        Write-Host "Database connection was established successfully"
    }
    Catch
    {
        Write-Host "Unable to establish database connection!" -ForegroundColor Red
        Echo $_.Exception | format-list -force
        Exit 1
    }
}

$existingPatches = @()

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

    $existingPatches = Get-ExistingPatches $connectionString
}

if ($schemaFile)
{
    Try
    {
        $script = Get-Content $schemaFile -Raw -Encoding UTF8

        Run-Sql $connectionString $script

        if ($useVersioning)
        {
            Add-PatchInfo $connectionString $([System.IO.Path]::GetFileName($schemaFile))
        }

        Write-Host "Database schema script was applied successfully"
    }
    Catch [Exception]
    {
        Write-Host "Unable to execute database schema script!" -ForegroundColor Red
        Echo $_.Exception | format-list -force
        Exit 1
    }
}

if ($patchFolder)
{
    Try
    {
        $patchFiles = Get-ChildItem -Path $patchFolder -Include "*.sql" -File -Name

        foreach ($patchFile in $patchFiles)
        {
            if ($existingPatches -notcontains $patchFile)
            {
                $filePath = Join-Path $patchFolder $patchFile
                $script = Get-Content $filePath -Raw -Encoding UTF8

                Write-Host "`tApplying patch: $patchFile"

                Run-Sql $connectionString $script

                if ($useVersioning)
                {
                    Add-PatchInfo $connectionString $patchFile
                }
            }
            else
            {
                Write-Host "`tSkipping patch: $patchFile"
            }
        }

        Write-Host "Database patching scripts were applied successfully"
    }
    Catch [Exception]
    {
        Write-Host "Unable to execute database patching scripts!" -ForegroundColor Red
        Echo $_.Exception | format-list -force
        Exit 1
    }
}

Write-Host "OK" -ForegroundColor Green
Exit 0