@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "UseSetx=1"
if not "%CD:~1024,1%" == "" set "UseSetx="
if not exist %SystemRoot%\System32\setx.exe set "UseSetx="
if defined UseSetx (
    %SystemRoot%\System32\setx.exe KRAKEN_PATH "%CD%" >nul
) else (
    %SystemRoot%\System32\reg.exe ADD "HKCU\Environment" /f /v KRAKEN_PATH /t REG_SZ /d "%CD%" >nul
)

set "UserPath="
for /F "skip=2 tokens=1,2*" %%N in ('%SystemRoot%\System32\reg.exe query "HKEY_CURRENT_USER\Environment" /v "Path" 2^>nul') do (
    if /I "%%N" == "Path" (
        set "UserPath=%%P"
        if defined UserPath goto CheckPath
    )
)

if exist %SystemRoot%\System32\setx.exe (
    %SystemRoot%\System32\setx.exe Path "%%MyAppPath%%" >nul
) else (
    %SystemRoot%\System32\reg.exe ADD "HKCU\Environment" /f /v Path /t REG_EXPAND_SZ /d "%%MyAppPath%%" >nul
)
endlocal
goto :EOF

:CheckPath
setlocal EnableDelayedExpansion
set "Separator="
if not "!UserPath:~-1!" == ";" set "Separator=;"
if "!UserPath:%%KRAKEN_PATH%%=!" == "!UserPath!" (
    set "PathToSet=!UserPath!%Separator%%%KRAKEN_PATH%%"
    set "UseSetx=1"
    if not "!PathToSet:~1024,1!" == "" set "UseSetx="
    if not exist %SystemRoot%\System32\setx.exe set "UseSetx="
    if defined UseSetx (
        %SystemRoot%\System32\setx.exe Path "!PathToSet!" >nul
    ) else (
        %SystemRoot%\System32\reg.exe ADD "HKCU\Environment" /f /v Path /t REG_EXPAND_SZ /d "!PathToSet!" >nul
    )
)
endlocal
endlocal