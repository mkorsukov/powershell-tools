# Configuration

A set of configuration related scripts

## Set-ConfigurationValue.ps1

Allows to update any attribute's value in the configuration file. If configuration element doesn't exist, it will be created.

Web.config example:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
    <system.web>
        <authentication mode="None" />
        <compilation debug="true" targetFramework="4.6.1" />
        <httpRuntime targetFramework="4.6.1" maxRequestLength="65536" />
    </system.web>
</configuration>
```

Script usage example:

```powershell
Set-ConfigurationValue.ps1
    -fileName "Web.config"
    -path "/configuration/system.web/httpRuntime@maxRequestLength"
    -value "524288"
```

## Set-ConnectionString.ps1

Allows to update any connection string with specific name in the ordinal `App.config` or `Web.config` files. This is usefull in continuous integration process, as a step between project build and test/deployment.

Web.config example:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
    <connectionStrings>
        <add name="Default"
            providerName="System.Data.SqlClient"
            connectionString="..." />
    </connectionStrings>
<configuration>
```

Script usage example:

```powershell
Set-ConnectionString.ps1
    -fileName "Web.config"
    -connectionName "Default"
    -connectionString "Data Source=tcp:localhost..."
```