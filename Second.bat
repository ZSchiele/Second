@echo off
REM only change trapsPassword accoordingly, don't touch the rest
set trapsPassword=N2PEvqnmrq_Ym9Kz
REM DONT CHANGE BELOW
set trapsCytool="%programFiles%\Palo Alto Networks\Traps\cytool.exe"
set logFileNameOnly=UninstallBatchLogs_%computername%_%time:~0,2%%time:~3,2%%time:~6,2%.txt
set logFile=%temp%\%logFileNameOnly%
set accessDenied="Error 5: Access is denied."
:start
echo Start Time: %date% %time%
echo Start Time: %date% %time% > %logFile%
echo Machine Name: %computername%
echo Machine Name: %computername% >> %logFile%
:checkSystemLanguage
for /f "tokens=*" %%v in ('reg query HKLM\SYSTEM\CurrentControlSet\Control\Nls\Language /v InstallLanguage') do (
set searchResults= %%v)
set systemLanguage=%searchResults:~30%
if %systemLanguage% NEQ 0409 (
echo OS Language not in English! OS language is 0x%systemLanguage%! Aborting...
echo OS Language not in English! OS language is 0x%systemLanguage%! Aborting... >> %logFile% 
goto finishSaveLogs )
echo OS Language: English
echo OS Language: English >> %logFile%
:checkOsVersion
for /f "tokens=*" %%v in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName') do (
set searchResults= %%v)
set systemVersion=%searchResults:~26%
echo OS Version: %systemVersion%
echo OS Version: %systemVersion% >> %logFile%
:checkOsArchitecture
if %processor_architecture% EQU AMD64 (
set osArch=x64
echo OS Architecture: x64
echo OS Architecture: x64 >> %logFile% )
if %processor_architecture% EQU x86 (
if not defined processor_architew6432 (
set osArch=x86
echo OS Architecture: x86
echo OS Architecture: x86 >> %logFile% ))
:checkTrapsInstalled
if not exist "%programFiles%\Palo Alto Networks\Traps\cyserver.exe" (
echo Cortex XDR agent not installed! Aborting...
echo Cortex XDR agent not installed! Aborting... >> %logFile%
goto finishSaveLogs )
echo Starting graceful uninstall process for Cortex XDR...
echo Starting graceful uninstall process for Cortex XDR... >> %logFile%
:checkTrapsVersion
for /f "tokens=*" %%v in ('reg query HKLM\Software\Cyvera\Client /v "Product Version"') do (
set searchResults= %%v)
set trapsVersion=%searchResults:~30%
echo Found Cortex XDR version: %trapsVersion%
echo Found Cortex XDR version: %trapsVersion% >> %logFile%
set trapsVersion=%trapsVersion:~0,5%
set trapsMainVersion=%trapsVersion:~0,2%
:checkTrapsCompatible
echo Looking for Cortex XDR product GUID...
echo Looking for Cortex XDR product GUID... >> %logFile%
if %trapsMainVersion% EQU 7. (
goto uninstallGUID_Cortex ) 
if %trapsMainVersion% EQU 6. (
goto uninstallGUID_Traps )
if %trapsMainVersion% EQU 5. (
goto uninstallGUID_Traps )
if %trapsMainVersion% EQU 4. (
goto uninstallGUID_Traps )
echo Cortex XDR version not supported! Script intended for Cortex XDR 7.x, 6.x, 5.x and 4.x. Aborting...
echo Cortex XDR version not supported! Script intended for Cortex XDR 7.x, 6.x, 5.x and 4.x. Aborting... >> %logFile%
goto finishSaveLogs
:uninstallGUID_Cortex
for /f "tokens=*" %%v in ('"reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall /s /f "Cortex XDR"|findstr /i "currentversion\uninstall""') do (
set searchResults= %%v)
set productCode=%searchResults:~72%
echo Cortex XDR productCode: %productCode%
echo Cortex XDR productCode: %productCode% >> %logFile%
:startTraps
echo Making sure Cortex XDR is running...
echo Making sure Cortex XDR is running... >> %logFile%
%trapsCytool% runtime start >> %logFile%
echo Waiting 5 seconds...
echo Waiting 5 seconds... >> %logFile%
timeout 5 > NUL
echo %trapsPassword%|%trapsCytool% checkin
:disableSprot
echo Disabling Cortex XDR agent tampering protection...
echo Disabling Cortex XDR agent tampering protection... >> %logFile%
for /f "tokens=*" %%v in ('"echo %trapsPassword%|%trapsCytool% protect disable"') do (
set searchResults=%%v)
set searchResultsCut=%searchResults:~0,12%
set accessDeniedCut=%accessDenied:~1,12%
if "%searchResultsCut%" EQU "%accessDeniedCut%" (
echo Failed running cytool!! Incorrect password or CMD not elevated. Aborting...
echo Failed running cytool!! Incorrect password or CMD not elevated. Aborting... >> %logFile%
goto finishSaveLogs )
goto uninstallMsiexec_Cortex
:uninstallMsiexec_Cortex
echo Calling msiexec to start Cortex XDR uninstall...
echo Calling msiexec to start Cortex XDR uninstall... >> %logFile%
msiexec /X%productCode% /quiet /l*v %temp%\CortexXdrUninstallLog_%computername%_%time:~0,2%%time:~3,2%%time:~6,2%.txt
echo Finished graceful uninstall process for Cortex XDR...
echo Finished graceful uninstall process for Cortex XDR... >> %logFile% 
goto finishSaveLogs
:uninstallGUID_Traps
for /f "tokens=*" %%v in ('"reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall /s /f "Traps"|findstr /i "currentversion\uninstall""') do (
set searchResults= %%v)
set productCode=%searchResults:~72%
echo Cortex XDR productCode: %productCode%
echo Cortex XDR productCode: %productCode% >> %logFile% 
echo Calling msiexec to start Cortex XDR uninstall...
echo Calling msiexec to start Cortex XDR uninstall... >> %logFile% 
msiexec /X%productCode% /quiet /l*v %temp%\CortexXdrUninstallLog_%computername%_%time:~0,2%%time:~3,2%%time:~6,2%.txt UNINSTALL_PASSWORD=%trapsPassword%
echo Finished graceful uninstall process for Cortex XDR...
echo Finished graceful uninstall process for Cortex XDR... >> %logFile% 
goto finishSaveLogs
:finishSaveLogs
echo Finish Time: %date% %time%
echo Finish Time: %date% %time% >> %logFile%
echo Batch logs at: %logFile%
echo Batch logs at: %logFile% >> %logFile%
echo Uninstall logs at: %temp%\CortexXdrUninstallLog_%computername%_%time:~0,2%%time:~3,2%%time:~6,2%.txt
echo Uninstall logs at: %temp%\CortexXdrUninstallLog_%computername%_%time:~0,2%%time:~3,2%%time:~6,2%.txt >> %logFile%