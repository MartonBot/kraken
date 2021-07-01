[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline)]
    [string]
    $TemplateName
)

begin {

    $projectFileName = "octopus-project.json"
    $newTemplates = @()

    # get local project
    $project = Get-Content "./$projectFileName" | ConvertFrom-Json
    $templates = $project.Templates
    $existingTemplateNames = $templates | Select-Object -ExpandProperty Name

}

process {

    if ([string]::IsNullOrWhiteSpace($TemplateName)) {
        Write-Error "The template name cannot be empty."
    }
    
    if ($existingTemplateNames -contains $TemplateName) {
        Write-Host "The $TemplateName template already exists, skipping."
    }
    else {
        Write-Host "Adding $TemplateName to the project templates." -ForegroundColor DarkGreen
        $newTemplate = @{
            "Name"            = $TemplateName;
            "Label"           = $TemplateName;
            "HelpText"        = $TemplateName;
            "DefaultValue"    = "";
            "DisplaySettings" = @{
                "Octopus.ControlType" = "SingleLineText"
            }
        }
        $newTemplates += $newTemplate
    }

}

end {
    $project.Templates = $templates + $newTemplates | Sort-Object -Property Name
    Write-Host "Updating $projectFileName file." -ForegroundColor Blue
    $project | ConvertTo-Json -Depth 5 | Set-Content -Path $projectFileName
}

