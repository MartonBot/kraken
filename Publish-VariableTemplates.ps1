
$ErrorActionPreference = "Stop"

$octopusProjectFileName = "octopus-project.json"
$octopusControlTypePropertyName = "Octopus.ControlType"

function Write-Changes {
    
    param (
        [string]$TemplateName,
        $PropertyName,
        $OldValue,
        $NewValue
    )
    
    if ($NewValue -ne $OldValue) {
        Write-Host "[$TemplateName] " -ForegroundColor Yellow -NoNewline
        Write-Host "$($PropertyName): " -NoNewline
        Write-Host "$OldValue" -ForegroundColor DarkRed -NoNewline
        Write-Host " -> " -NoNewline
        Write-Host "$NewValue" -ForegroundColor DarkGreen
    }
}

# load the local project and get the relevant information
$localProject = Get-Content -Path ".\$octopusProjectFileName" | ConvertFrom-Json

# get the project from the server
$serverProject = & $PSScriptRoot\Get-OctopusResource.ps1 -Path "api/projects/$($project.Id)"

# loop through the local variable templates
foreach ($localTemplate in $localProject.Templates) {

    Write-Verbose "Processing local variable template $($localTemplate.Name)."

    # find the corresponding variable template on the server, if it exists
    $serverTemplate = $serverProject.Templates | Where-Object { $_.Name -eq $localTemplate.Name }

    # does the template exist on the server?
    if ($null -eq $serverTemplate) {
        Write-Host "Template $($localTemplate.Name) does not exist on the server, creating it." -ForegroundColor DarkGreen
        $serverProject.Templates += $localTemplate
    }
    else {
        Write-Verbose "Template $($localTemplate.Name) already exists on the server."

        # Label
        if ($localTemplate.Label -ne $serverTemplate.Label) {
            Write-Changes `
                -TemplateName $localTemplate.Name `
                -PropertyName "Label" `
                -OldValue $serverTemplate.Label `
                -NewValue $localTemplate.Label
        }

        # Help text
        if ($localTemplate.HelpText -ne $serverTemplate.HelpText) {
            Write-Changes `
                -TemplateName $localTemplate.Name `
                -PropertyName "HelpText" `
                -OldValue $serverTemplate.HelpText `
                -NewValue $localTemplate.HelpText
        }

        # Display settings
        Write-Changes `
            -TemplateName $localTemplate.Name `
            -PropertyName "DisplaySettings/$octopusControlTypePropertyName" `
            -OldValue $serverTemplate.DisplaySettings.$octopusControlTypePropertyName `
            -NewValue $localTemplate.DisplaySettings.$octopusControlTypePropertyName

        # Default value
        # are the local or server variable sensitive?
        $displayOldValue = ($serverTemplate.DisplaySettings.$octopusControlTypePropertyName -eq "Sensitive") ? "*****" : $serverTemplate.DefaultValue
        $displayNewValue = ($localTemplate.DisplaySettings.$octopusControlTypePropertyName -eq "Sensitive") ? "*****" : $localTemplate.DefaultValue

        Write-Changes `
            -TemplateName $localTemplate.Name `
            -PropertyName "DefaultValue" `
            -OldValue $displayOldValue `
            -NewValue $displayNewValue

    }

}

# update the project on the server
Invoke-RestMethod -Method Put -Uri "$($octopusBaseUrl)api/projects/$($project.Id)" -Headers $header -Body ($serverProject | ConvertTo-Json -Depth 10) | Out-Null