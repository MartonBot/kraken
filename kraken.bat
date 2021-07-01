@echo off

rem Just run the appropriate PowerShell script corresponding to the argument

IF "%1"=="help" (
	SET script="%~dp0\Show-Help.ps1"
	GOTO runScript
)

IF "%1"=="init" (
	SET script="%~dp0\New-LocalProjectFile.ps1"
	GOTO runScript
)

IF "%1"=="substitutions" (
	SET script="%~dp0\Get-Substitutions.ps1"
	GOTO runScript
)

IF "%1"=="status" (
	SET script="%~dp0\Show-Status.ps1"
	GOTO runScript
)

IF "%1"=="update" (
	SET script="%~dp0\Update-LocalOnly.ps1"
	GOTO runScript
)

IF "%1"=="pull" (

	IF "%2"=="project" (
		SET script="%~dp0\Write-OctopusProjectFromServer.ps1"
		GOTO runScript
	)
	
	IF "%2"=="values" (
		SET script="%~dp0\Write-TenantDataFromServer.ps1"
		GOTO runScript
	)
)

echo kraken help
echo kraken init
echo kraken status
echo kraken update

EXIT /b



:runScript
pwsh -File "%script%" -OctopusPath "%cd%" -VerbosePreference "Continue"