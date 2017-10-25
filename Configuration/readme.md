# Configuration

A set of configuration related scripts

## Set-ConnectionString.ps1

Allows to update any connection string with specific name in the ordinal `App.config` or `Web.config` files. This is usefull in continuous integration process, as a step between project build and test/deployment.

Web.config example:

```xml
<connectionStrings>
    <add name="Default"
         providerName="System.Data.SqlClient"
         connectionString="..." />
</connectionStrings>
```

Script usage example:

```powershell
Set-ConnectionString.ps1
    -fileName "Web.config"
    -connectionName "Default"
    -connectionString "Data Source=tcp:localhost..."
```