# This script retrives the tenant values from the server and updates the local tenant value files.
# It only updates entries for tenants, environments and templates defined in the octopus-project.json file.

$ErrorActionPreference = "Stop"

$octopusProjectFileName = "octopus-project.json"
$tenantNameKey = "Tenant Name"

# load the local project and get the relevant information
$project = Get-Content -Path ".\$octopusProjectFileName" | ConvertFrom-Json
$environmentNames = $project.Environments

# get the environments from the server as an array
$environments = @()
foreach ($envName in $environmentNames) {
    $env = (& $PSScriptRoot\Get-OctopusResource.ps1 -Path "api/environments?name=$envName").Items | Select-Object -Property Name, Id
    $environments += $env
}

# get the list of tenants connected to this project
$tenants = $project.Tenants

# get a list of the locally defined templates, for which we will get the values from the server
$localTemplates = $project.Templates

# loop through each environment targeted by the project
foreach ($env in $environments) {
    
    Write-Verbose "Updating local values from server values for environment $($env.Name)."

    # get the contents of the local tenant value file for this environment
    $tenantValueFileName = "$($project.Name).$($env.Name).values.json"

    if (!(Test-Path -Path $tenantValueFileName -PathType Leaf)) {
        Write-Error "The tenant value file $tenantValueFileName doesn't exist. Run kraken update to create this file."
    }

    $localTenantValues = Get-Content $tenantValueFileName | ConvertFrom-Json

    # loop through each tenant
    foreach ($tenant in $tenants) {

        # get the object storing all data for this tenant from the server
        
        $serverVariables = & $PSScriptRoot\Get-OctopusResource.ps1 -Path "api/tenants/$($tenant.Id)/variables"
        $serverProject = $serverVariables.ProjectVariables.$($project.Id)

        # Get project templates from the server
        $serverTemplates = $serverProject.Templates

        # get the data specific to this environment
        $serverValues = $serverProject.Variables.$($env.Id)

        # loop through each variable template that is locally defined
        foreach ($localTemplate in $localTemplates) {
            
            # get the corresponding server template
            $serverTemplate = $serverTemplates | ? { $_.Name -eq $localTemplate.Name }

            # get the local value
            $localValuesForTenant = $localTenantValues | ? { $_.$tenantNameKey -eq $tenant.Name }
            $localValue = $localValuesForTenant.$($localTemplate.Name)

            # get the server value for this template
            $serverValue = $serverValues.$($serverTemplate.Id)

            # if the server value is null
            if ($null -eq $serverValue) {
                Write-Verbose "Server value for $($localTemplate.Name) is null."
            }
            # or if the server value is not a string
            elseif ($serverValue.GetType().Name -ne "String") {
                Write-Verbose "Server value for $($localTemplate.Name) is not a string."
            }
            # or if the server value is the same as the local value
            elseif ($localValue -eq $serverValue) {
                Write-Verbose "Server value for $($localTemplate.Name) is the same as the local value."
            }
            else {
                # output the update info
                Write-Host "[$($env.Name)]`t" -ForegroundColor Yellow -NoNewline
                Write-Host "$($localTemplate.Name):`t" -NoNewline
                Write-Host "'$localValue'`t" -ForegroundColor DarkRed -NoNewline
                Write-Host "<- `t" -NoNewline
                Write-Host "'$serverValue'" -ForegroundColor DarkGreen

                # perform the update
                $localValuesForTenant.$($localTemplate.Name) = $serverValue
            }

        }

    }

    # write the updated tenant values to the file
    $localTenantValues | ConvertTo-Json -Depth 5 | Set-Content -Path "./$tenantValueFileName"

}