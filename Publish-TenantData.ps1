# In Octopus, each tenant connected to a project can deploy to a different set of environments. However, in the VendorPanel world and so far, all tenants deploy to the same set of environments (either Blue/Gree or Red).

# TODO implement for multiple tenants in an array, or ALL

Param(
    [ValidateSet(
        "AU LIVE",
        "CA LIVE",
        "NZ LIVE",
        "GLOBAL LIVE",
        "UAT AU",
        "UAT AU #2",
        "UAT AU #3",
        "UAT AU #4",
        "UAT AU #5",
        "UAT AU #6",
        "UAT AU #7",
        "UAT AU #8",
        "ALL"
    )]
    $TenantName = "UAT AU"
)

$ErrorActionPreference = "Stop"

$octopusServer = & $PSScriptRoot\Get-OctopusServerInfo.ps1

$octopusProjectFileName = "octopus-project.json"
$stringContainsOctopusSubstitutionsRegex = "[^#{}]*(#{[^#{}]+})+[^#{}]*"

# Octopus API key header
$header = @{ "X-Octopus-ApiKey" = $octopusServer.apiKey }

# load the local project and get the relevant information
$project = Get-Content -Path ".\$octopusProjectFileName" | ConvertFrom-Json
$environmentNames = $project.Environments

# get the environments from the server as an array
$environments = @()
foreach ($envName in $environmentNames) {
    $env = (Invoke-RestMethod -Method Get -Uri "$($octopusServer.octopusBaseUrl)api/environments?name=$envName" -Headers $header).Items | Select-Object -Property Name, Id
    $environments += $env
}

# Get the tenant from the server
$tenantsSearch = Invoke-RestMethod -Method Get -Uri "$($octopusServer.octopusBaseUrl)api/tenants?name=$TenantName" -Headers $header
$tenant = $tenantsSearch.Items | Select-Object -First 1

# get the tenant variables object from the server
# this object stores the values for all variable templates for all environments
# edit the object, once done update the server with a PUT
$serverVariables = Invoke-RestMethod -Method Get -Uri "$($octopusServer.octopusBaseUrl)api/tenants/$($tenant.Id)/variables" -Headers $header

# Get project templates from the server
$serverProject = $serverVariables.ProjectVariables.$($project.Id)
$variableTemplates = $serverProject.Templates

# loop through each environment targeted by the project
foreach ($env in $environments) {
    
    Write-Verbose "Updating server values from local values for environment $($env.Name)."

    # get the contents of the local tenant value file for this combination of environment and tenant
    $tenantValueFileName = "$($project.Name).$($env.Name).values.json"
    $localTenantValues = Get-Content $tenantValueFileName | ConvertFrom-Json | ? { $_.$tenantNameKey -eq $tenantName }

    # loop through each variable template on the server (local only variable templates are ignored)
    foreach ($template in $variableTemplates) {

        # determine whether the variable template is sensitive or not
        $templateType = $template.DisplaySettings."Octopus.ControlType"
        Write-Verbose "Processing template $($template.Name) of type $templateType (template ID = $($template.Id))."
        $isSensitive = $templateType -eq "Sensitive"

        # retrieve the value stored in the local tenant value file
        $localValue = $localTenantValues.$($template.Name)
        Write-Verbose "$($template.Name) local value = $($isSensitive ? '*****' : "'$localValue'")"

        # retrieve the server value
        $serverValue = $serverProject.Variables.$($env.Id).$($template.Id)

        # check whether the variable template entry exists, and add it if not present
        if ($null -eq $serverValue) {
            $serverProject.Variables.$($env.Id) | Add-Member -MemberType NoteProperty -Name $template.Id -Value ""
            $serverValue = ""
        }

        # is it sensitive, but also containing references to other Octopus variables?
        # if the local value denotes one or more Octopus variable, e.g. 'This #{Variable} contains #{Substitutions}', treat it as if it were text
        $sensitiveAndBoundToOctopusVariable = $isSensitive -and $localValue -match $stringContainsOctopusSubstitutionsRegex

        Write-Verbose "$($template.Name) server value = $(-not $isSensitive -or $sensitiveAndBoundToOctopusVariable ? "'$serverValue'" : '*****')"

        # if the variable template is not sensitive
        if (-not $isSensitive -or $sensitiveAndBoundToOctopusVariable) {

            if ($serverValue -ne $localValue) {

                # get the value to display for the server value
                $displayOldValue = $isSensitive ? "*****" : $serverValue

                # output the update info
                Write-Host "[$($env.Name)]`t" -ForegroundColor Yellow -NoNewline
                Write-Host "$($template.Name):`t" -NoNewline
                Write-Host "'$displayOldValue'`t" -ForegroundColor DarkRed -NoNewline
                Write-Host "->`t" -NoNewline
                Write-Host "'$localValue'" -ForegroundColor DarkGreen

                # update the value on the server object
                $serverProject.Variables.$($env.Id).$($template.Id) = $localValue
            }

        }
        else {

            # output the update info
            Write-Host "[$($env.Name)] " -ForegroundColor Yellow -NoNewline
            Write-Host "$($template.Name): " -NoNewline
            Write-Host "setting sensitive value" -ForegroundColor Blue

            # update the value on the server object
            $newSensitiveValue = @{
                HasValue = $True
                NewValue = $localValue
            }
            $serverProject.Variables.$($env.Id).$($template.Id) = $newSensitiveValue

        }

    }

}

# update $serverVariables object on the server
Invoke-RestMethod -Method Put -Uri "$($octopusServer.octopusBaseUrl)api/tenants/$($tenant.Id)/variables" -Headers $header -Body ($serverVariables | ConvertTo-Json -Depth 10) | Out-Null