# If there is no octopus-project.json file, this file will create an empty one

Param(
    [string]
    $ProjectName
)

$ErrorActionPreference = "Stop"

$octopusProjectFileName = "octopus-project.json"

# if there is no local octopus-project.json, create it
if (!(Test-Path -Path "./$octopusProjectFileName" -PathType Leaf)) {

    # verify that a project name has been provided
    if ([string]::IsNullOrWhitespace($ProjectName)) {
        $ProjectName = "New Project"
    }

    $octopusProject = @{
        "Name"         = $ProjectName
        "Id"           = ""
        "Templates"    = @()
        "Tenants"      = @()
        "Environments" = @("Green", "Blue", "Red")
    }
    $octopusProject | ConvertTo-Json | Out-File "./$octopusProjectFileName"

    Write-Host "A new $octopusProjectFileName has been created in the current directory, please edit the name of the project and the connected environments." -ForegroundColor DarkGreen

}
else {
    Write-Host "The $octopusProjectFileName file already exists in the current directory."
}