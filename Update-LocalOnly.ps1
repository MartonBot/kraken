# This script is meant to be run after some new Octopus substitutions have been introduced in the tracked configuration files.
# It updates the list of variable templates in the project file, and then updates the tenant value files to generate new entries.
# It does not delete any template already defined in the project file.
# It does not retrieve any data from the server.

& $PSScriptRoot\Update-OctopusProjectFromLocalSubstitutions.ps1

& $PSScriptRoot\Update-TenantValueFiles.ps1