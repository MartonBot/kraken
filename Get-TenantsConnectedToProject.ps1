[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $ProjectId
)

$ErrorActionPreference = "Stop"

$apikeyVariableName = 'OCTOPUS_CLI_API_KEY'
$octopusUrlVariableName = "OCTOPUS_CLI_SERVER"

# read API key and base URL from environment variables
$apiKey = $(Get-ChildItem -Path "Env:\$apikeyVariableName")[0].Value
$octopusBaseUrl = $(Get-ChildItem -Path "Env:\$octopusUrlVariableName")[0].Value

# Octopus API key header
$header = @{ "X-Octopus-ApiKey" = $apiKey }

$connectedTenants = @()

# get all tenants from the server
$allTenants = (& $PSScriptRoot\Get-OctopusResource.ps1 -Path "api/Spaces-1/tenants").Items

# keep the tenants connected to the project
$allTenants | % {
    $connectedProjects = $_.ProjectEnvironments | Get-Member | ? MemberType -eq NoteProperty | Select-Object -ExpandProperty Name
    if($connectedProjects -contains $projectId) {
        $connectedTenants += $_
    }
}

$connectedTenants | Select-Object -Property Name, Id