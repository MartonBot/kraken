$configFilesFileName = "config-files.json"
$substitutionPattern = "#{([^#{}]+)}"

if (!(Test-Path -Path "./$configFilesFileName" -PathType Leaf)) {
    Write-Error "The $configFilesFileName file does not exist in this directory. Please create it before running this script."
}

# open the config-files.json file
$configFilePaths = (Get-Content -Path "./$configFilesFileName" | ConvertFrom-Json).Files

# create an array to return
$substitutions = @()

foreach ($path in $configFilePaths) {
    # collect all the Octopus substitutions for the file being parsed
    Write-Verbose "Parsing ../$path file for Octopus substitutions."
    $lines = Get-Content -Path "../$path"

    $lineNumber = 0

    # loop through the lines
    foreach ($line in $lines) {
        $lineNumber++

        $found = ([regex]$substitutionPattern).Matches($line)

        foreach ($match in $found) {
            $templateName = $match.Groups[1].Value
            Write-Verbose "Found substitution $templateName in file $path, line $lineNumber."
            $sub = [PSCustomObject]@{
                Name = $templateName
                File = $path
                Line = $lineNumber
            }
            $substitutions += $sub
        }
    }

}

# make a list of unique variable template names found in the substitutions
return $substitutions | Sort-Object -Property Name