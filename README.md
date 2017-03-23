# PowerShell Scripts Library

A set of helpful scripts in PowerShell.

## Deployment

A set of scripts that helps with deployment tasks for web applications (for instance, ASP.NET MVC).

### ConnectionString.ps1

Allows to update connection string with specific name in the Web.config file. A good example is updating connection string before/after project build and before deployment.

Script arguments:

```powershell
ConnectionString.ps1
    -file "path to Web.config"
    -name "connection name"
    -value "database connection string"
```

Web.config's connection string example:

```xml
<connectionStrings>
    <add name="Default"
         providerName="System.Data.SqlClient"
         connectionString="..." />
</connectionStrings>
```

Script usage example:

```powershell
ConnectionString.ps1
    -file "Web.config"
    -name "Default"
    -value "data source=tcp:localhost..."
```

### JsonProperty.ps1

Allows to verify information (in JSON format) from any web-application. A good example is checking the application version after deployment process.

Script arguments:

```powershell
JsonProperty.ps1
    -url "URL to web-application"
    -property "JSON property name"
    -value "value to check"
```

Possible JSON response from web-application:

```json
{
    "appVersion":"3.0.117.0",
    "dotNetVersion":"4.0.30319.42000",
    "iisVersion":"8.5",
    "lastStart":"2017-03-21 22:00:48"
}
```

Script usage example:

```powershell
JsonProperty.ps1
    -url "https://kazanhome.com/diagnostic/info"
    -property "appVersion"
    -value "3.0.117.0"
```