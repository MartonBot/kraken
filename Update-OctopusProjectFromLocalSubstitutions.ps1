# This script collects all the Octopus substitutions found in files and adds them as variable templates in the project file.

# get all the substitutions from declared config files
$substitutions = & $PSScriptRoot\Get-Substitutions.ps1 | Select-Object -ExpandProperty Name -Unique

# add the variable template names to be added to the project file
$substitutions | & $PSScriptRoot\Add-LocalVariableTemplate.ps1
