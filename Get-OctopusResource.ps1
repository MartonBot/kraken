Param (
    [Parameter(Mandatory)]
    [string]
    $Path
)

$VerbosePreference = "Continue"

$apikeyVariableName = 'OCTOPUS_CLI_API_KEY'
$octopusUrlVariableName = "OCTOPUS_CLI_SERVER"

# read API key and base URL from environment variables
try {
    $apiKey = $(Get-ChildItem -Path "Env:\$apikeyVariableName")[0].Value
    $octopusBaseUrl = $(Get-ChildItem -Path "Env:\$octopusUrlVariableName")[0].Value
}
catch {
    Write-Error "To query an Octopus resource, you must set both environment variables OCTOPUS_CLI_API_KEY (e.g. API-XXXXXXX) and OCTOPUS_CLI_SERVER (e.g. https://octopus.vendorpanel.com.au)."
}

# Octopus API key header
$headers = @{ "X-Octopus-ApiKey" = $apiKey }

Write-Verbose "Querying Octopus resource $Path."
return Invoke-RestMethod -Method Get -Uri "$octopusBaseUrl/$Path" -Headers $headers