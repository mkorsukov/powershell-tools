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

function Apply-Schema([string] $connectionString, [string] $schemaFile, [bool] $useVersioning)
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

function Apply-Patches([string] $connectionString, [string] $patchFolder, [bool] $useVersioning)
{
    $existingPatches = @()

    if ($useVersioning)
    {
        if ((Get-PatchesTableExistence $connectionString) -eq 0)
        {
            Write-Host "Required [_Patches] database table doesn't exist" -ForegroundColor Red
            Exit 1
        }

        $existingPatches = Get-ExistingPatches $connectionString
    }

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
                Run-Sql $connectionString "insert into [_Patches] ([Name], [User], [Date]) values ('$patchFile', original_login(), sysdatetimeoffset());"
            }
        }
        else
        {
            Write-Host "`tSkipping patch: $patchFile"
        }
    }
}

Clear-Host
Write-Host "Database Updater 1.0 : Copyright (C) Maxim Korsukov : 2017-10-22" -ForegroundColor Yellow

Exit 0

if (!$connectionString)
{
    Write-Host "Required database connection string is not specified" -ForegroundColor Red
    Exit 1
}

if ($schemaFile -and !(Test-Path $schemaFile))
{
    Write-Host "Specified database schema file doesn't exist" -ForegroundColor Red
    Exit 1
}

if ($patchFolder -and !(Test-Path $patchFolder))
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

if ($schemaFile)
{
    Try
    {
        Apply-Schema $connectionString $schemaFile $useVersioning

        Write-Host "Database schema script was executed successfully"
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
        Apply-Patches $connectionString $patchFolder $useVersioning

        Write-Host "Database patching scripts were executed successfully"
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