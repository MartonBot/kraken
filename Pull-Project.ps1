# If there is no octopus-project.json file, this file will create and populate it with general details (Id and connected tenants) from the server

Param(

)

$ErrorActionPreference = "Stop"

$octopusProjectFileName = "octopus-project.json"

# verify that the project file exists
if (!(Test-Path -Path "./$octopusProjectFileName" -PathType Leaf)) {
    Write-Error "The $octopusProjectFileName file does not exist in the current directory. Run kraken init to create a new one."
}

# get the local project
$localProject = Get-Content -Path "./$octopusProjectFileName" | ConvertFrom-Json

$projectName = $localProject.Name

# get the project from the server
$serverProject = (& $PSScriptRoot\Get-OctopusResource.ps1 -Path "api/projects?skip=0&take=10000").Items | ? Name -eq $projectName

# is there a project corresponding to that name on the server
if ($null -eq$serverProject) {
    Write-Error "Project '$projectName' not found on server. Verify the project name in the $octopusProjectFileName file."
}

# get the project Id
$projectId = $serverProject.Id

# create a list of environments to add locally
$newEnvironments = @()

# get the local environments, we want to keep them even if they don't exist on the server
$localEnvironments = @($localProject.Environments)
$existingLocalEnvironmentNames = $localEnvironments | Select-Object -ExpandProperty Name

# get the lifecycle for the project and the environment Ids associated to its first phase
$lifecycle = & $PSScriptRoot\Get-OctopusResource.ps1 -Path "api/lifecycles/$($serverProject.LifecycleId)"
$environmentIds = $lifecycle.Phases[0].OptionalDeploymentTargets

# retrieve the environments that are associated to the project on the server
$serverEnvironments = @((& $PSScriptRoot\Get-OctopusResource.ps1 -Path "api/environments?skip=0&take=10000").Items | ? { $environmentIds -contains $_.Id } | Select-Object -Property Name, Id)
Write-Verbose "Found $($serverEnvironments.Count) associated environments on the server."

# write the server environments that do not exist locally
$serverEnvironments | ForEach-Object {
    if ($existingLocalEnvironmentNames -contains $_.Name) {
        Write-Verbose "The local project is already associated to the $($_.Name) environments, skipping."
    }
    else {
        Write-Host "Adding $($_.Name) environment to local project." -ForegroundColor DarkGreen
        $newEnvironments += $_
    }
}

# create a list of connected tenants to add locally
$newConnectedTenants = @()

# get the local connected tenants, we want to keep them even if they don't exist on the server
$localConnectedTenants = @($localProject.Tenants)
$existingLocalTenantNames = $localConnectedTenants | Select-Object -ExpandProperty Name

# get the connected tenants from the server
$serverConnectedTenants = & $PSScriptRoot\Get-TenantsConnectedToProject.ps1 -ProjectId $projectId
Write-Verbose "Found $($serverConnectedTenants.Count) connected tenants on the server."

# write the server connected tenants that do not exist locally
$serverConnectedTenants | ForEach-Object {
    if ($existingLocalTenantNames -contains $_.Name) {
        Write-Verbose "The local project is already connected to the $($_.Name) tenant, skipping."
    }
    else {
        Write-Host "Connecting $($_.Name) tenant to local project." -ForegroundColor DarkGreen
        $newConnectedTenants += $_
    }
}

# set the local values
$localProject.Id = $serverProject.Id
$localProject.Tenants = $localConnectedTenants + $newConnectedTenants | Sort-Object -Property Name
$localProject.Environments = $localEnvironments + $newEnvironments | Sort-Object -Property Name

# write to the project file
$localProject | ConvertTo-Json -Depth 5 | Set-Content -Path "./$octopusProjectFileName"
