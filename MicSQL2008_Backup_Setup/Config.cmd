@echo off
SETLOCAL
::---------------------------------------------------
:: Program : Automated Microsoft SQL Database Backup (added Config.cmd to guide users)
:: Version : V1.1
:: Created by : Nestor B. Gramata Jr.
:: Date: May 20, 2017
:: Filename: Config.cmd
::---------------------------------------------------
:: Description:
::  This code was originally created to work on the SQL server "INFAESAD0084\sql2008"
::  The SQL interface here uses Microsoft SQL Server 2008 R2
::  
::  Requires a .\scripts folder containing the following files:
::  1. MicSQL_Backup@DBNAME.cmd               (i.e. MicSQL_Backup@HR91.cmd)
::  2. CreateTask_DAYofWEEK_HHMMSS@DBNAME.cmd (i.e. CreateTask_TUE_000500@HR91.cmd)
::  3. DeleteTask@DBNAME.cmd                  (i.e. DeleteTask@HR91.cmd)
::  4. SendEmail.vbs
::  5. StoreSQLPass.cmd
::
::  This specific batch file has a user-interface with several echoed notes and remarks
::  Its main purpose is to help the user in configuration of the set of batch files 
::    under the "scripts" folder
::---------------------------------------------------

REM pulls data from files under "scripts" and uses it as the inital setting
:StartProg
call:Initialize

:RePrompt
call:DisplayChoices
if [%inpCmd%]==[] (
	echo Blank Input...
	echo/
	pause
	goto:RePrompt
)
findstr /r /c:"^:MyPick_%inpCmd%" "%~fp0" > nul
if errorlevel 1 (
	echo Invalid Input...
	echo/
	pause
	goto:RePrompt
)

REM below is like a switch case
REM depending on case, program may go to either
REM   StartProg, RePrompt, or EndProg
goto MyPick_%inpCmd%

REM rename "%~dp0MicSQL_Backup@%curdBName%.cmd" MicSQL_Backup@%dBName%.cmd
:EndProg
ENDLOCAL
goto:EOF

REM ================================Auxiliary Script Blocks Below==============================================
:Initialize
	echo ==============================================
	echo ==Configuration Program for Automated Backup==
	echo ==============================================
	
	REM initialize directory
	set "scriptDir=%~dp0scripts"

	REM target only one set of specific files based on dBName for editing and get values - locks on to one type of DB
	for /F "usebackq" %%a in (`dir /b "%scriptDir%\MicSQL_Backup@*.cmd"`) do set "micSQL_BackupFile=%%a"
	set "micSQL_BackupFileWDir=%scriptDir%\%micSQL_BackupFile%"
	for /F "usebackq tokens=2 delims=@." %%a in ('%micSQL_BackupFile%') do set dBName=%%a
	REM set createTaskFile since it will be used for several codes below - locks on to one set of schedule
	for /F "usebackq" %%a in (`dir /b "%scriptDir%\CreateTask_*@%dBName%.cmd"`) do set "createTaskFile=%%a"
	REM Target Files
	set "createTaskFileWDir=%scriptDir%\%createTaskFile%"
	set "deleteTaskFileWDir=%scriptDir%\DeleteTask@%dBName%.cmd"

	REM recover current configurations based on files targeted
	for /F "usebackq tokens=2 delims=@_." %%a in ('%createTaskFile%') do set taskDay=%%a
	for /F "usebackq tokens=3 delims=@_." %%a in ('%createTaskFile%') do set taskTime=%%a
	for /F "usebackq tokens=*" %%a in (`type "%micSQL_BackupFileWDir%" ^| find "set serverName"`) do set serverNameLine=%%a
	for /F "usebackq tokens=*" %%a in (`type "%micSQL_BackupFileWDir%" ^| find "set serverUser"`) do set serverUserLine=%%a
	
	REM store these as target lines of code during powershell replace in later code
	set "prevServerNameLine=%serverNameLine%"
	set "prevServerUserLine=%serverUserLine%"
	REM reformat variable below in order to be compatible with syntax from powershell inline execution
	for /F "usebackq tokens=1,2 delims=\" %%a in (`type "%micSQL_BackupFileWDir%" ^| find "set serverName"`) do (
		set part1=%%a
		set part2=%%b
	)
	if "%part2%" NEQ ""	set prevServerNameLine=%part1%\\%part2%
goto:eof

REM Main Menu
:DisplayChoices
	echo/
	echo This program automates and guides the user
	echo in setting up the backup scripts
	echo/
	echo NOTES:
	echo   Current user must have read/write PERMISSION on appropriate files/folders
	echo   Numbers 1-6 sets parameters 
	echo     Values in the bracket are current values (excluding 3)
	echo     Blank input values means use current values (excluding 3)
	echo   Letters L, A, M are CASE-SENSITIVE
	echo     Load Configuration is a must if new parameters in 1-6 (excluding 3) are to be saved
	echo     Backup task schedule here can only be on a weekly basis, edit via task scheduler if needed
	echo   Manually modify .\scripts\SendEmail.vbs with the appropriate SMTP settings to enable email function
	echo/
	echo Pick a number or letter corresponding to desired action:  
	echo   1 - Set Server Name:  [%serverNameLine:~15%]
	echo   2 - Set Server User:  [%serverUserLine:~15%]
	echo   3 - Set Password
	echo   4 - Set DB Name:      [%dBName%]
	echo   5 - Set Task Day:     [%taskDay%]
	echo   6 - Set Task Time     [%taskTime%]
	echo   L - Load Configuration
	echo   A - Load Configuration and Create Task Schedule
	echo   M - Load Configuration and Execute Backup Manually
	echo   q - quit
	echo/
	set inpCmd=
	set /p inpCmd="Choice [1,2,3,4,5,6,L,A,M,q]: "
	echo/
goto:eof

REM this code loads the values to the appropriate files
:Loader
	set "ConfigureConfirm=N"
	set /p ConfigureConfirm="Are you sure [Y,N]: "
	if [%ConfigureConfirm%]==[] goto:RePrompt
	if /I "%ConfigureConfirm%" NEQ "Y" (
		goto:RePrompt
	)
	set "psCommand=powershell -Command " ^
		(get-content \"%micSQL_BackupFileWDir%\") -replace \"%prevServerNameLine%\" , \"%serverNameLine%\" ^| set-content \"%micSQL_BackupFileWDir%\" ; ^
		(get-content \"%micSQL_BackupFileWDir%\") -replace \"%prevServerUserLine%\" , \"%serverUserLine%\" ^| set-content \"%micSQL_BackupFileWDir%\"""
	%psCommand%
	move "%micSQL_BackupFileWDir%" "%scriptDir%\MicSQL_Backup@%dBName%.cmd"
	move "%createTaskFileWDir%" "%scriptDir%\CreateTask_%taskDay%_%taskTime%@%dBName%.cmd"
	move "%deleteTaskFileWDir%" "%scriptDir%\DeleteTask@%dBName%.cmd"
	echo Scripts Modified...
	echo/
goto:eof

:::::Switch Start:::::
:MyPick_1
	echo Set Server Name (i.e. INFAESAD0084\sql2008)
	set serverName=%serverNameLine:~15%
	set /p serverName="Enter Server Name [%serverNameLine:~15%]: "
	set "serverNameLine=set serverName=%serverName%"
goto:RePrompt

:MyPick_2
	echo Set User (i.e. sa)
	set serverUser=%serverUserLine:~15%
	set /p serverUser="Enter Server Username [%serverUserLine:~15%]: "
	set "serverUserLine=set serverUser=%serverUser%"
goto:RePrompt

:MyPick_3
	echo Set encrypted password for user: %serverUserLine:~15%
	call "%scriptDir%\StoreSQLPass.cmd"
goto:RePrompt

:MyPick_4
	echo Set Database Name (i.e. HR91)
	set /p dBName="Enter Database Name [%dBName%]: "
goto:RePrompt

:MyPick_5
	echo Set Task Day (MON, TUE, WED, THU, FRI, SAT, SUN)
	echo Choose from one of the 3-letter values from the parenthesis above
	set /p taskDay="Enter Day of Week [%taskDay%]: 
	REM checks to prevent invalid day format
	if /I "%taskDay%" EQU "MON" goto RePrompt
	if /I "%taskDay%" EQU "TUE" goto RePrompt
	if /I "%taskDay%" EQU "WED" goto RePrompt
	if /I "%taskDay%" EQU "THU" goto RePrompt
	if /I "%taskDay%" EQU "FRI" goto RePrompt
	if /I "%taskDay%" EQU "SAT" goto RePrompt
	if /I "%taskDay%" EQU "SUN" goto RePrompt
goto:MyPick_5

:MyPick_6
	echo Set Task Time in HHMMSS (i.e. 132540)
	echo Above example would mean 1:25:40pm
	set /p taskTime="Enter Time [%taskTime%]: "
	REM checks that there are not more than 6 characters
	if "%taskTime:~6,1%" NEQ "" (
		echo Input must be in "HHMMSS" format!
		set taskTime=HHMMSS
		echo/
		goto MyPick_6
	)
	REM pads the input with 0s to avoid values of less than 6 characters
	set taskTime=%taskTime%00000
	set taskTime=%taskTime:~0,6%
	REM the 3 ifs below checks that the time value is within range
	if "%taskTime:~0,2%" GTR "23" (
		echo HH must be 2 digits with a value less than 24!
		echo/
		goto MyPick_6
	)
	if %taskTime:~2,2% GTR 59 (
		echo MM must be 2 digits with a value less than 60!
		echo/
		goto MyPick_6
	)
	if %taskTime:~4,2% GTR 59 (
		echo SS must be 2 digits with a value less than 60!
		echo/
		goto MyPick_6
	)
goto:RePrompt

:MyPick_L
	echo Load Configuration (Uppercase L)
	call:Loader
	pause
goto:EndProg

:MyPick_A
	echo Load Configuration and Create Task (Uppercase A)
	call:Loader
	call "%scriptDir%\CreateTask_%taskDay%_%taskTime%@%dBName%.cmd"
goto:EndProg

:MyPick_M
	echo Load Configuration and Execute Backup Script Now (Uppercase M)
	call:Loader
	call "%scriptDir%\MicSQL_Backup@%dBName%.cmd"
	pause
goto:EndProg

:MyPick_q
	echo You chose Exit (Lowercase q)
goto:EndProg
:::::Switch End:::::