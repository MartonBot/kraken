Param(
    [switch]
    $WhatIf
)

$ErrorActionPreference = "Stop"

$octopusProjectFileName = "octopus-project.json"
$octopusControlTypePropertyName = "Octopus.ControlType"
$octopusSelectOptionsPropertyName = "Octopus.SelectOptions"

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

# verify that the project Id is set
if ([string]::IsNullOrWhiteSpace($localProject.Id)) {
    Write-Error "The project Id is not set. You can use kraken pull to set it from the server."
}

# get the project from the server
$serverProject = & $PSScriptRoot\Get-OctopusResource.ps1 -Path "api/projects/$($localProject.Id)"

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
        Write-Changes `
            -TemplateName $localTemplate.Name `
            -PropertyName "Label" `
            -OldValue $serverTemplate.Label `
            -NewValue $localTemplate.Label

        # Help text
        Write-Changes `
            -TemplateName $localTemplate.Name `
            -PropertyName "HelpText" `
            -OldValue $serverTemplate.HelpText `
            -NewValue $localTemplate.HelpText
            
        # Display settings
        Write-Changes `
            -TemplateName $localTemplate.Name `
            -PropertyName "DisplaySettings/$octopusControlTypePropertyName" `
            -OldValue $serverTemplate.DisplaySettings.$octopusControlTypePropertyName `
            -NewValue $localTemplate.DisplaySettings.$octopusControlTypePropertyName
            
        # Select options
        if ($localTemplate.DisplaySettings.$octopusControlTypePropertyName -eq "Select") {
            Write-Changes `
                -TemplateName $localTemplate.Name `
                -PropertyName "DisplaySettings/$octopusSelectOptionsPropertyName" `
                -OldValue $serverTemplate.DisplaySettings.$octopusSelectOptionsPropertyName `
                -NewValue $localTemplate.DisplaySettings.$octopusSelectOptionsPropertyName
        }
            
        # Default value
        # are the local or server variable sensitive?
        $displayOldValue = ($serverTemplate.DisplaySettings.$octopusControlTypePropertyName -eq "Sensitive") ? "*****" : $serverTemplate.DefaultValue
        $displayNewValue = ($localTemplate.DisplaySettings.$octopusControlTypePropertyName -eq "Sensitive") ? "*****" : $localTemplate.DefaultValue
            
        Write-Changes `
            -TemplateName $localTemplate.Name `
            -PropertyName "DefaultValue" `
            -OldValue $displayOldValue `
            -NewValue $displayNewValue
            
        $serverTemplate.Label = $localTemplate.Label
        $serverTemplate.HelpText = $localTemplate.HelpText
        $serverTemplate.DisplaySettings = $localTemplate.DisplaySettings
        $serverTemplate.DefaultValue = $localTemplate.DefaultValue
            
    }
        
}
    
# update the project on the server
if (!$WhatIf.IsPresent) {
    Write-Host "Updating server templates from local." -ForegroundColor Blue
    & $PSScriptRoot\Set-OctopusResource.ps1 -Path "api/projects/$($localProject.Id)" -Resource $serverProject
}
else {
    Write-Host "Server templates were not updated."
}