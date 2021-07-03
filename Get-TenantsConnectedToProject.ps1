[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $ProjectId
)

$ErrorActionPreference = "Stop"

$connectedTenants = @()

# get all tenants from the server
$allTenants = (& $PSScriptRoot\Get-OctopusResource.ps1 -Path "api/tenants").Items

# keep the tenants connected to the project
$allTenants | % {
    $connectedProjects = $_.ProjectEnvironments | Get-Member | ? MemberType -eq NoteProperty | Select-Object -ExpandProperty Name
    if($connectedProjects -contains $projectId) {
        $connectedTenants += $_
    }
}

$connectedTenants | Select-Object -Property Name, Id