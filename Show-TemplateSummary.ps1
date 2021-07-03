$octopusControlTypePropertyName = "Octopus.ControlType"
$octopusSelectOptionsPropertyName = "Octopus.SelectOptions"

$tableWidths = @(
    @{Expression={$_.Name};Label="Name";width=35},
    @{Expression={$_."Type (local)"};Label="Type (local)";width=15},
    @{Expression={$_."Type (server)"};Label="Type (server)";width=15},
    @{Expression={$_."Default (local)"};Label="Default (local)";width=20},
    @{Expression={$_."Default (server)"};Label="Default (server)";width=20},
    @{Expression={$_."Options (local)"};Label="Options (local)";width=16},
    @{Expression={$_."Options (server)"};Label="Options (server)";width=16}
)

function New-TemplateData {

    Param(
        [string]
        $Name
    )

    return [PSCustomObject]@{
        Name               = $Name
        "Type (local)"     = ""
        "Type (server)"    = ""
        "Default (local)"  = ""
        "Default (server)" = ""
        "Options (local)"  = ""
        "Options (server)" = ""
        
    }

}

$localTemplates = @(& $PSScriptRoot\Get-LocalTemplates.ps1)

$serverTemplates = @(& $PSScriptRoot\Get-ServerTemplates.ps1)

$allTemplates = @()

# add local templates
foreach ($localTemplate in $localTemplates) {

    # try and get the data for that template
    $templateData = $allTemplates | Where-Object { $_.Name -eq $localTemplate.Name }

    # add the template if not in the list yet
    if ($null -eq $templateData) {

        # create a new object to hold the data
        $templateData = New-TemplateData -Name $localTemplate.Name
        $allTemplates += $templateData
    }

    $displayDefaultValue = $localTemplate.DefaultValue.GetType().Name -eq "String" ? $localTemplate.DefaultValue : "*****"

    # update the relevant values
    $templateData."Type (local)" = $localTemplate.DisplaySettings.$octopusControlTypePropertyName
    $templateData."Default (local)" = $displayDefaultValue
    $templateData."Options (local)" = $localTemplate.DisplaySettings.$octopusSelectOptionsPropertyName

}
# add server templates
foreach ($serverTemplate in $serverTemplates) {

    # try and get the data for that template
    $templateData = $allTemplates | Where-Object { $_.Name -eq $serverTemplate.Name }

    # add the template if not in the list yet
    if ($null -eq $templateData) {

        # create a new object to hold the data
        $templateData = New-TemplateData -Name $serverTemplate.Name
        $allTemplates += $templateData
    }

    $displayDefaultValue = $serverTemplate.DefaultValue.GetType().Name -eq "String" ? $serverTemplate.DefaultValue : "*****"

    # update the relevant values
    $templateData."Type (server)" = $serverTemplate.DisplaySettings.$octopusControlTypePropertyName
    $templateData."Default (server)" = $displayDefaultValue
    $templateData."Options (server)" = $serverTemplate.DisplaySettings.$octopusSelectOptionsPropertyName

}

Write-Output $allTemplates | Sort-Object -Property Name | Format-Table -Property $tableWidths