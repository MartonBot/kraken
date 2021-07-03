$ErrorActionPreference = "Stop"

$octopusProjectFileName = "octopus-project.json"

# get the local project
$octopusProject = Get-Content -Path "./$octopusProjectFileName" | ConvertFrom-Json

# get the variable templates for the project
return $octopusProject.Templates