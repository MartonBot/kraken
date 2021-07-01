Param(

)

$ErrorActionPreference = "Stop"

$octopusProjectFileName = "octopus-project.json"

function Update-Summary {
    
    param(
        [string[]]
        $TemplateList,
        [array]
        $Summary,
        [string]
        $Key
    )

    # loop through local templates
    foreach ($template in $TemplateList) {

        # get the summary entry
        $summaryEntry = $Summary | ? { $_.Name -eq $template }

        if ($null -eq $summaryEntry) {
            #create a new entry if it doesn't exist yet
            $summaryEntry = [PSCustomObject]@{
                "Name"            = $template
                $localProjectKey  = "-"
                $serverProjectKey = "-"
                $configFileKey    = "-"
            }
            $Summary += $summaryEntry
        }

        # update the entry
        $summaryEntry.$Key = "X"

    }

    return $Summary | Sort-Object -Property Name

}

# is there a project file?
if (!(Test-Path -Path "./$octopusProjectFileName" -PathType Leaf)) {
    Write-Error "The $octopusProjectFileName file does not exist in the current directory. Run kraken init to create a new one."
}

# get information from the local project file
$project = Get-Content -Path "./$octopusProjectFileName" | ConvertFrom-Json

$localProjectKey = "Local project"
$serverProjectKey = "Server project"
$configFileKey = "Config files"

# get template lists for the local project, the server, and the config files
$substitutions = @(& $PSScriptRoot\Get-Substitutions.ps1 | Select-Object -ExpandProperty Name -Unique)
$localTemplates = @(& $PSScriptRoot\Get-LocalTemplates.ps1)
$serverTemplates = @(& $PSScriptRoot\Get-ServerTemplates.ps1)

# create an empty array to store the summary
$summary = @()

Write-Host "summary type = $($summary.GetType())"

# enrich the summary with data from the local project, the server, and the config files
$summary = Update-Summary -TemplateList $localTemplates -Summary $summary -Key $localProjectKey
$summary = Update-Summary -TemplateList $serverTemplates -Summary $summary -Key $serverProjectKey
$summary = Update-Summary -TemplateList $substitutions -Summary $summary -Key $configFileKey




# output some information
Write-Host "Project: $($project.Name)"
Write-Host "Environments:"
$project.Environments
Write-Host "Tenants:"
$project.Tenants | Select-Object -ExpandProperty Name
Write-Host "Variable templates:"
$summary | Format-Table
