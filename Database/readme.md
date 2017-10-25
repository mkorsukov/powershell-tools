# Database

A set of database related scripts

## Update-Database.ps1

Allows to update SQL Server database.

Script usage example:

```powershell
Update-Database.ps1
    -connectionString "Data Source=tcp:localhost..."
    -schemaFile "c:\Database\Schema.sql"
    -patchFolder "c:\Database\Patches"
    -useVersioning 1
```