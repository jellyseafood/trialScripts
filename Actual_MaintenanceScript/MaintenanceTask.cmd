@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
set "path=C:\WINDOWS\system32\WindowsPowerShell\v1.0;%path%"
::-----------------------------------------------------------------------------------------------------------
::-----------------------------MaintenanceTask.cmd-----------------------------------------------------------
::-----------------------------------------------------------------------------------------------------------
REM Created By: Nestor B. Gramata Jr.
REM Created On: 25Mar2017
REM Works if the "Remote Scheduled Tasks Management" firewall exception is Enabled -- by default it usually is
REM Auto Generates Folder and Files on:
REM		-- .\Logs_MaintenanceTask\*.
REM Needs 2 Auxiliary Folders (REQUIRED):
REM		-- .\Credentials_MaintenanceTask\*.
REM				files inside here are auto-generated when you execute "S - Set Credential"
REM		-- .\Tasks_MaintenanceTask\
REM				contains the TaskList.csv file
REM			

:StartProgram
REM cls
call:Initialization
call:Intro
call:PromptUserAction
if ERRORLEVEL 1 goto:EndProgram
call:ConfirmAction
if ERRORLEVEL 1 goto:EndProgram
call:LogFileSetup

REM MODIFY .\Tasks_MaintenanceTask\TaskList.csv...calls a function that accepts 2 arguments:
REM 		- 1st Args: Server Name
REM 		- 2nd Args: Task Name
REM			***CRITICAL: double check the argument values found in .\Tasks_MaintenanceTask\TaskList.csv
for /F "EOL=: tokens=1-3 delims=," %%i in (%settingFile%) do (
	call:RemoteMasterControl "%%i" "%%j" "%%k" >> "%logFile%" 2>>&1
)

REM display log contents in cmd window
echo/
type %logFile%

:EndProgram
echo/
pause
ENDLOCAL
goto:EOF
::-----------------------------------------------------------------------------------------------------------
::-----------------------------Below Are The Program Functions-----------------------------------------------
::-----------------------------------------------------------------------------------------------------------

:Initialization
	REM if below variable is undeclared table header will be printed
	set "headerOnce="
	REM use below snippet for powershell commands to minimize retyping
	set psDecodeSnippet= $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($encPass) ; ^
	[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
	REM set variables here
	set "settingDir=%~dp0Tasks_MaintenanceTask"
	set "logDir=%~dp0Logs_MaintenanceTask"
	set "credDir=%~dp0Credentials_MaintenanceTask"
	set "settingFile=%settingDir%\TaskList.csv"
	set "credFile=%credDir%\credList.cred"
	REM check if directory or file exists, recreate if necessary
	if not exist %settingDir% mkdir %settingDir%
	if not exist %credDir% mkdir %credDir%
	if not exist %logDir% mkdir %logDir%
	if not exist %settingFile% echo ServerName,UserName,TaskName > "%settingFile%"
goto:eof

:Intro
	REM cls
	echo Current Program: %~f0
	echo/
	echo This Program is designed to either disable, enable,
	echo      or view several remote tasks...
	echo Check settings to verify targeted tasks prior to running
	echo/
	echo SETUP: edit the .\Tasks_MaintenanceTask\TaskList.csv 
	echo        prior to running this program
	echo SETUP: store passwords in encrypted form and associate it 
	echo        with username using "S - Set Credential" option
	
	echo/
	echo NOTE: An ERROR can occur if either ServerName, Username, Password or TaskName is wrong
	echo NOTE: A prompt would help deter user from accidental execution
	echo/

	echo Pick a number that corresponds to intended program action:
	echo    1 - DISABLE tasks
	echo    2 - ENABLE tasks
	echo    3 - Get Tasks Info (Summarized - filtered table )
	echo    4 - Get Tasks Info (Detailed - Lists)
	echo    5 - Get Tasks Info (Very Detailed - XML)
	echo    E - Edit Settings via excel(TaskList.csv, Uppercase E)
	echo    N - Edit Settings via notepad (TaskList.csv, Uppercase N)
	echo    S - Set Credential (Store password in encrypted form, Uppercase S)
	echo    C - Check List of Stored Credentials (Uppercase C)
	echo    L - Open Log Folder (Uppercase L)
	echo    x - Exit (Lowercase x)	
	echo/
goto:eof

:PromptUserAction
	choice /C 12345ENSCLx /N /CS /M "Pick one [1,2,3,4,5,E,N,S,C,L,x]: "
	set myChoice=%ERRORLEVEL%
	REM cls
	goto myPick_%myChoice%
		:myPick_1
			echo/
			echo You chose DISABLE tasks
			set "storedPick=P_Disable"
		goto:endPick

		:myPick_2
			echo/
			echo You chose ENABLE tasks
			set "storedPick=P_Enable"
		goto:endPick

		:myPick_3
			echo/
			echo You chose Get Tasks Info (Summarized - filtered table )
			set "storedPick=P_Table"
		goto:endPick

		:myPick_4
			echo/
			echo You chose Get Tasks Info (Detailed - Lists)
			set "storedPick=P_Lists"
			REM disable table header print by declaring variable with value
			set headerOnce=noNEED
		goto:endPick

		:myPick_5
			echo/
			echo You chose Get Tasks Info (Very Detailed - XML)
			set "storedPick=P_XML"
			REM disable table header print by declaring variable with value
			set headerOnce=noNEED
		goto:endPick
		
		:myPick_6
			echo/
			echo You chose Edit Settings (TaskList.csv, Uppercase E)
			echo/
			echo The arguments set here are CRITICAL                                   
			echo *disabling or enabling unintended tasks might be harmful to the system
			echo Each line consists of 3 arguments (order of each argument is important)
			echo   1. Server Name (i.e. Computer1) - Column A
			echo   2. User Name (include domain i.e. DOMAIN\username) - Column B
			echo   3. Task Name (i.e. Sample1) - Column C
			echo **there will be prompts when saving the csv via excel
			echo **choose "Yes" to retain format
			echo/
			pause
			echo/
			echo Opening File:
			echo %settingFile%
			start excel %settingFile%
			echo/
			pause
			call:Intro
			goto:PromptUserAction
		goto:endPick
		
		:myPick_7
			echo/
			echo You chose Edit Settings via notepad (TaskList.csv, Uppercase N)
			echo/
			echo The arguments set here are CRITICAL                                   
			echo *disabling or enabling unintended tasks might be harmful to the system
			echo Each line consists of 3 arguments (order of each argument is important)
			echo   1. Server Name
			echo   2. User Name (include domain i.e. DOMAIN\username)
			echo   3. Task Name
			echo *Arguments are delimited by a comma (,)                                 
			echo *Each Argument should NOT be enclosed by double-quotes ("")
			echo   i.e. Server Name,DOMAIN\User Name,Task Name
			echo/
			pause
			echo/
			echo Opening File:
			echo %settingFile%
			start notepad %settingFile%
			echo/
			pause
			call:Intro
			goto:PromptUserAction
		goto:endPick
		
		:myPick_8
			echo/
			echo You chose Set Credential (Store password in encrypted form, Uppercase S)
			echo/
			set /p userName="Username: "
			call:CredentialEncrypt
			call:Intro
			goto:PromptUserAction
		goto:endPick
		
		:myPick_9
			echo/
			echo You chose Check List of Stored Credentials (Uppercase C)
			echo/
			for /f "token=1 delims=:" %%a in ('type %credFile%') do echo %%a
			echo/
			pause
			call:CredentialEncrypt
			call:Intro
			goto:PromptUserAction
		goto:endPick
				
		:myPick_10
			echo/
			echo Open Log Folder (Uppercase L)
			echo/
			echo Opening Log Directory:
			echo %logDir%
			explorer %logDir%
			echo/
			pause
			call:Intro
			goto:PromptUserAction
		goto:endPick
		
		:myPick_11
			echo/
			echo You chose Exit (Lowercase x)
			exit /b 1
		goto:endPick
	:endPick
goto:eof

:ConfirmAction
	REM get password securely, using PowerShell functions to be more concise
	echo/
	set "psCommand=powershell -Command "$encPass = Read-Host "Type CoNFIRM to proceed" -AsSecureString ; ^
		%psDecodeSnippet%""
	for /F %%p in ('%psCommand%') do set confWord="%%p"
	if NOT %confWord%=="CoNFIRM" (
		echo/
		echo CoNFIRM was typed incorrectly
		echo Exiting program
		exit /b 1
	)
goto:eof

:LogFileSetup
	REM get date format and place in variable YYYYMMDD_HHMM
	for /f "tokens=1-3 delims=:. " %%a in ('echo %time%') do (
		set "fixHour=0%%a"
		set "myTime=!fixHour:~-2!%%b%%c"
	)
	for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set myDate=%%c-%%a-%%b)
	REM note that script directory and chosen program action are also in the filename
	set "logFile=%logDir%\%myDate%_%myTime%_%storedPick%.log"

	echo/
	echo Logged to file:
	echo %logFile%
	echo/
	echo %storedPick% executed on %myDate%_%myTime% -- YYYY-MM-DD_HHMMSS  > "%logFile%"
goto:eof

:RemoteMasterControl
	set "serverName=%1"
	set "userName=%2"
	set "taskName=%3"
	
	call:CredentialDecrypt
	
	goto case_%storedPick%
		:case_P_Disable
			REM did this to arrange how output is displayed
			set cmdExecCommonTableQuery=schtasks /Change /S %serverName% /U %userName% /P %passWord% /TN %taskName% /DISABLE
			call:CommonTableQuery
		goto endCase

		:case_P_Enable
			REM did this to arrange how output is displayed
			set cmdExecCommonTableQuery=schtasks /Change /S %serverName% /U %userName% /P %passWord% /TN %taskName% /ENABLE
			echo set cmdExecCommonTableQuery=schtasks /Change /S %serverName% /U %userName% /P %passWord% /TN %taskName% /ENABLE			
			call:CommonTableQuery
		goto endCase

		:case_P_Table
			set "cmdExecCommonTableQuery="
			call:CommonTableQuery
		goto endCase

		:case_P_Lists
			echo/
			echo|set /p="Server: %serverName% "
			schtasks /Query /S %serverName% /U %userName% /P %passWord% /FO LIST /TN %taskName%
		goto endCase

		:case_P_XML
			echo/
			schtasks /Query /S %serverName% /U %userName% /P %passWord% /XML ONE /TN %taskName%
			echo/
		goto endCase
	:endCase
goto:eof

:CommonTableQuery
	if NOT DEFINED headerOnce (
		REM disable table header print by declaring variable with value
		set headerOnce=alreadyDONE
		echo/
		echo ServerInfo, Folder, and TaskName         Next Run Time          Status
		echo ======================================== ====================== ===============
	)

	echo/
	echo ________________________________________
	echo Server: %serverName%
	%cmdExecCommonTableQuery%
	echo|set /p="----------------------------------------"
	schtasks /Query /S %serverName% /U %userName% /P %passWord% /FO TABLE /NH /TN %taskName% 2> NUL
	if ERRORLEVEL 1 (
		echo/
		echo ERROR: Access is denied.
	)
goto:eof

:CredentialEncrypt
	REM used powershell since cmd lacks encrypt functions
	set "psCommand=powershell -Command "$encPass = Read-Host \"Password\" -AsSecureString ^| ConvertFrom-SecureString ; ^
		if ($varExist=type %credFile% ^| Select-String -pattern \"`\"%userName:~1,-1%`\"\" -casesensitive) ^
		{(get-content \"%credFile%\") -replace \"$varExist\" , \"`\"%userName:~1,-1%`\":$encPass\" ^| set-content \"%credFile%\"} ^
		else {echo \"`\"%userName:~1,-1%`\":$encPass\" ^>^> \"%credFile%\"}""
	%psCommand%
goto:eof

:CredentialDecrypt
	REM used powershell since cmd lacks encrypt functions
	set "psCommand=powershell -Command "^
		if ($varExist=type \"%credFile%\" ^| Select-String -pattern \"`\"%userName:~1,-1%`\"\" -CaseSensitive -SimpleMatch) ^
			{$encPass=($varExist -split \":\")[1] ^| ConvertTo-SecureString ; ^
			$BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($encPass) ; ^
			[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)} ^
		else {^
		$string1=\"`nStored Password not found for Username in designated task below`n\" ; ^
		$string1=\"$($string1^)^ ^ ^ Server `\"%serverName:~1,-1%`\"`n\" ; ^
		$string1=\"$($string1^)^ ^ ^ Task `\"%taskName:~1,-1%`\"`n\" ; ^
		$string1=\"$($string1^)^ ^ ^ Username `\"%userName:~1,-1%`\"`n\" ; ^
		$string1=\"$($string1^)Enter Password\" ; ^
		$encPass=Read-Host \"$string1\" -AsSecureString ; ^
			%psDecodeSnippet%}""
	for /F %%p in ('%pscommand%') do set passWord="%%p"
goto:eof

::----------OPTIONAL TEST BEFORE EXECUTING ACTUAL SCRIPT------------
REM create "SAMPLE" or any harmless task on destination server
REM MODIFY all variables on line below (do this manually):
REM --->	schtasks /Change /S "%serverName%" /U "%userName%" /P "%passWord%" /TN "%taskName%" /DISABLE
REM if above "schtasks" statement executes successfully, then remote windows server can accept this command 
::----------------------
