# Test

A set of test / validation / verification related scripts

## Check-JsonProperty.ps1

Allows to verify information (in JSON format) from any web-application's response. Example: checking the web-application version after deployment process.

Possible response from web-application (in JSON format):

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
Check-JsonProperty.ps1
    -url "https://kazanhome.com/diagnostic/info"
    -property "appVersion"
    -value "3.0.117.0"
```