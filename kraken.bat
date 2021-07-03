@echo off

rem -WhatIf switch
SET whatif=
IF "%2"=="-whatif" (
	SET whatif=-WhatIf
)
IF "%3"=="-whatif" (
	SET whatif=-WhatIf
)
IF "%4"=="-whatif" (
	SET whatif=-WhatIf
)

rem -TenantName parameter
SET tenantName=

rem Just run the appropriate PowerShell script corresponding to the argument

IF "%1"=="help" (
	SET script="%~dp0Show-Help.ps1"
	GOTO runScript
)

IF "%1"=="init" (
	SET script="%~dp0New-LocalProjectFile.ps1"
	GOTO runScript
)

IF "%1"=="status" (
	SET script="%~dp0Show-Status.ps1"
	GOTO runScript
)

IF "%1"=="substitutions" (
	SET script="%~dp0Get-Substitutions.ps1"
	GOTO runScript
)

IF "%1"=="templates" (
	SET script="%~dp0Show-TemplateSummary.ps1"
	GOTO runScript
)

IF "%1"=="values" (
	SET script="%~dp0Compare-Values.ps1"
	GOTO runScript
)

IF "%1"=="update" (
	SET script="%~dp0Update-LocalEntries.ps1"
	GOTO runScript
)

IF "%1"=="pull" (

	IF "%2"=="project" (
		SET script="%~dp0Pull-Project.ps1"
		GOTO runScript
	)
	
	IF "%2"=="templates" (
	
		SET script="%~dp0Pull-Templates.ps1"
		GOTO runScript
	)
	
	IF "%2"=="values" (
		SET script="%~dp0Pull-Values.ps1"
		GOTO runScript
	)
	
)

IF "%1"=="push" (

	IF "%2"=="templates" (
		SET script="%~dp0Push-Templates.ps1"
		GOTO runScript
	)
	
	IF "%2"=="values" (
		SET script="%~dp0Push-Values.ps1"
		GOTO runScript
	)
	
)



:helpMessage
echo Try:
echo kraken help
echo kraken init
echo kraken substitutions
echo kraken status
echo kraken update
echo kraken pull project
echo kraken pull templates
echo kraken pull values
echo kraken push templates
echo kraken push values

EXIT /b

:runScript
pwsh -File %script% %whatif%