# If there is no octopus-project.json file, this file will create and populate it with variable templates from the server

Param(
    [switch]
    $WhatIf
)

Write-Host "Server templates will only be copied if the local version does not exist. If a template exists locally, it will be left unmodified." -ForegroundColor Blue

$ErrorActionPreference = "Stop"

$octopusProjectFileName = "octopus-project.json"

# verify that the project file exists
if (!(Test-Path -Path "./$octopusProjectFileName" -PathType Leaf)) {
    Write-Error "The $octopusProjectFileName file does not exist in the current directory. Run kraken init to create a new one."
}

# get the local project
$localProject = Get-Content -Path "./$octopusProjectFileName" | ConvertFrom-Json

# get the project from the server
$serverProject = (& $PSScriptRoot\Get-OctopusResource.ps1 -Path "api/projects?skip=0&take=10000").Items | ? Name -eq $localProject.Name

# is there a project corresponding to that name on the server
if ($null -eq $serverProject) {
    Write-Error "Project '$($localProject.Name)' not found on server. Verify the project name in the $octopusProjectFileName file."
}

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

# set the local values
$localProject.Templates = $localTemplates + $newTemplates | Sort-Object -Property Name

# write to the project file
if (!$WhatIf.IsPresent) {
    Write-Host "Updated local project file with templates from the server." -ForegroundColor Blue
    $localProject | ConvertTo-Json -Depth 5 | Set-Content -Path "./$octopusProjectFileName"
}
else {
    Write-Host "Local project file was not updated."
}
