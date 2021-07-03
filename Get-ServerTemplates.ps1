$ErrorActionPreference = "Stop"

$octopusProjectFileName = "octopus-project.json"

# get the local project
# to get the project Id
$project = Get-Content -Path "./$octopusProjectFileName" | ConvertFrom-Json

if ([string]::IsNullOrWhiteSpace($project.Id)) {
    Write-Error "The project Id is not set in $octopusProjectFileName. You can set it manually or use kraken pull project."
}

# get the project from the server
$serverProject = & $PSScriptRoot\Get-OctopusResource.ps1 -Path "api/projects/$($project.Id)"

return $serverProject.Templates | Select-Object -ExcludeProperty Id