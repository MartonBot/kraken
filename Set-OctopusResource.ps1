Param (
    [Parameter(Mandatory)]
    [string]
    $Path,
    [Parameter(Mandatory)]
    $Resource
)

$apikeyVariableName = 'OCTOPUS_CLI_API_KEY'
$octopusUrlVariableName = "OCTOPUS_CLI_SERVER"

# read API key and base URL from environment variables
try {
    $apiKey = $(Get-ChildItem -Path "Env:\$apikeyVariableName")[0].Value
    $octopusBaseUrl = $(Get-ChildItem -Path "Env:\$octopusUrlVariableName")[0].Value
}
catch {
    Write-Error "To set an Octopus resource, you must set both environment variables OCTOPUS_CLI_API_KEY (e.g. API-XXXXXXX) and OCTOPUS_CLI_SERVER (e.g. https://octopus.vendorpanel.com.au)."
}

# Octopus API key header
$headers = @{ "X-Octopus-ApiKey" = $apiKey }

Write-Verbose "Writing to Octopus resource $Path."
return Invoke-RestMethod -Method Put -Uri "$octopusBaseUrl/$Path" -Headers $headers -Body ($Resource | ConvertTo-Json -Depth 10) | Out-Null