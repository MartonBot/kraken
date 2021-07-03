<#
.SYNOPSIS

    Update (or create) the tenant value files for each environment associated to the project.

.DESCRIPTION

    Update the tenant value files for each environment associated to the project, so that they have the entries corresponding to the connected tenants and the variable templates defined in the project file.

    Let's consider the project named MyProject.

    2 environments are associated to the project:
    - Blue
    - Green

    3 tenants are connected to the project:
    - LIVE
    - UAT AU
    - UAT CA

    N project variable templates (PVTs) are defined for the project:
    - variableTemplate1
    - ...
    - variableTemplateN

    Then upon running this script, 2 files will be created (or updated if they exist):
    - MyProject.Blue.values.json
    - MyProject.Green.values.json

    The content of one of these 2 files will be aligned against the following structure:

    [
        {
            "Tenant Name": "LIVE",
            "variableTemplate1" : "this value is already defined",
            "variableTemplate1" : "",
            ...
            "variableTemplateN" : ""
        },
        {
            "Tenant Name": "UAT AU",
            "variableTemplate1" : "this value is already defined",
            "variableTemplate1" : "",
            ...
            "variableTemplateN" : ""
        },
        {
            "Tenant Name": "UAT CA",
            "variableTemplate1" : "this value is already defined",
            "variableTemplate1" : "",
            ...
            "variableTemplateN" : ""
        }
    ]
    
    The "Tenant Name" property is always added for a tenant. If a variable template entry already exists, its value is preserved.
	
.EXAMPLE

    .\Update-TenantValueFiles.ps1 

#>

$ErrorActionPreference = "Stop"

$octopusProjectFileName = "octopus-project.json"
$tenantNameKey = "Tenant Name"

# get the local project
$octopusProject = Get-Content -Path "./$octopusProjectFileName" | ConvertFrom-Json
$projectName = $octopusProject.Name

# get the variable templates for the project
$variableTemplates = $octopusProject.Templates | Select-Object -ExpandProperty Name

# get all tenants and environments from the project file
$connectedTenants = $octopusProject.Tenants | Select-Object -ExpandProperty Name
$environments = $octopusProject.Environments | Select-Object -ExpandProperty Name

# create or update the tenant value files
foreach ($environment in $environments) {

    $tenantValueFileName = "$projectName.$environment.values.json"

    if (!(Test-Path -Path $tenantValueFileName -PathType Leaf)) {
        Write-Host "The $tenantValueFileName file does not exist in the current directory, creating it." -ForegroundColor DarkGreen
        New-Item -ItemType File -Name "./$tenantValueFileName" | Out-Null
    }
    else {
        Write-Verbose "The $tenantValueFileName file already exists in the current directory."
    }

    # get the current contents of the tenant value file
    $tenantsInFile = Get-Content -Path "./$tenantValueFileName" | ConvertFrom-Json -AsHashtable

    # if the file is empty, set the JSON to an empty array
    if ($null -eq $tenantsInFile) {
        $tenantsInFile = @()
    }

    # create an empty array to store the updated tenants
    $updatedTenants = @()

    # loop through the connected tenants
    foreach ($tenantToUpdate in $connectedTenants) {

        # retrieve the current tenant values for the tenant to be updated
        $tenant = $tenantsInFile | ? { $_.$tenantNameKey -eq $tenantToUpdate }
        if ($null -eq $tenant) {
            $tenant = @{}
        }

        # create an array to store the existing tenant value entries (remove the $tenantNameKey entry as we will add it later)
        $tenantValueEntries = @($tenant.GetEnumerator() | ? { $_.Name -ne $tenantNameKey })

        # loop through the project's variable templates and add the missing tenant value entries
        foreach ($variableTemplate in $variableTemplates) {

            # if the entry corresponding to the variable template is not present, add it
            if (!($tenant.ContainsKey($variableTemplate))) {
                Write-Host "Adding missing entry for $($tenantToUpdate): #{$variableTemplate}" -ForegroundColor DarkGreen
                $tenantValueEntries += @{
                    Name  = $variableTemplate
                    Value = ""
                }
            }

        }

        # sort the tenant value entries
        $tenantValueEntries = $tenantValueEntries | Sort-Object -Property Name

        #prepend the tenant name entry, so that it is the first one in the list
        $nameEntry = @{
            Name  = $tenantNameKey
            Value = $tenantToUpdate
        }
        $tenantValueEntries = @($nameEntry) + $tenantValueEntries

        # transform each object in the array
        $updatedTenant = New-Object -TypeName PSObject
        
        $tenantValueEntries | % {
            $updatedTenant | Add-Member -MemberType NoteProperty -Name $_.Name -Value $_.Value -Force
        }

        $updatedTenants += $updatedTenant

    }

    # write the updated tenant values to the file
    Write-Host "Updating $tenantValueFileName file." -ForegroundColor Blue
    $updatedTenants | ConvertTo-Json -Depth 5 | Set-Content -Path "./$tenantValueFileName"

}