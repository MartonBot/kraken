# If there is no octopus-project.json file, this file will create and populate it with variable templates from the server

Param(
    [string]
    $ProjectName
)

$ErrorActionPreference = "Stop"

$octopusProjectFileName = "octopus-project.json"

# verify that the project file exists
if (!(Test-Path -Path "./$octopusProjectFileName" -PathType Leaf)) {
    Write-Error "The $octopusProjectFileName file does not exist in the current directory. Run kraken init to create a new one."
}

# get the local project
$localProject = Get-Content -Path "./$octopusProjectFileName" | ConvertFrom-Json

# verify that the project name matches if it has been provided
if (![string]::IsNullOrWhitespace($ProjectName) -and $ProjectName -ne $localProject.Name) {
    Write-Error "The supplied project name $ProjectName does not match the name in the $octopusProjectFileName file $($localProject.Name)."
}
$projectName = $localProject.Name

# get the project from the server
$serverProject = (& $PSScriptRoot\Get-OctopusResource.ps1 -Path "api/projects?skip=0&take=10000").Items | ? Name -eq $projectName

# is there a project corresponding to that name on the server
if ($null -eq$serverProject) {
    Write-Error "Project '$projectName' not found on server. Verify the project name in the $octopusProjectFileName file."
}

# get the project Id
$projectId = $serverProject.Id

# create a list of templates to add locally
$newTemplates = @()

# get the local templates
$localTemplates = $localProject.Templates
$existingLocalTemplateNames = $localTemplates | Select-Object -ExpandProperty Name

# get the server templates
$serverTemplates = $serverProject.Templates
Write-Verbose "Found $($serverTemplates.Count) variable templates on the server."

# write the server templates that do not exist locally
foreach ($serverTemplate in $serverTemplates) {
    if ($existingLocalTemplateNames -contains $serverTemplate.Name) {
        Write-Verbose "The local project already contains the $($serverTemplate.Name) template, skipping."
    }
    else {
        Write-Host "Adding server template $($serverTemplate.Name) to local project." -ForegroundColor DarkGreen
        $serverTemplate.PSObject.Properties.Remove('Id')
        $newTemplates += $serverTemplate
    }
}

# create a list of connected tenants to add locally
$newConnectedTenants = @()

# get the local connected tenants
$localConnectedTenants = $localProject.Tenants
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
$localProject.Templates = $localTemplates + $newTemplates | Sort-Object -Property Name
$localProject.Tenants = $localConnectedTenants + $newConnectedTenants | Sort-Object -Property Name

# write to the project file
$localProject | ConvertTo-Json -Depth 5 | Set-Content -Path "./$octopusProjectFileName"
