@ECHO off
SETLOCAL ENABLEDELAYEDEXPANSION
::--------------------------------------------------------------
::----------------MigraTor_PS_Proj_v6.cmd-----------------------
::--------------------------------------------------------------
::--Developed By: Nestor B. Gramata Jr.
::--20171206----------------------------------------------------
::  Program that simplifies project migration
::  Faster speed compared to manual
::  folder directories are all automatically created
::  verifies said directories
::  Nothing missed this way unlike manually doing it
::  Program does does not proceed if a prior pside step is not yet done or does not pass the verification (via log file)
::  There are 5 pside steps:
::    1. Initial Compare
::    2. Copy Project to prepare for Target Backup
::    3. Backup Copy to File
::    4. Copy Project and Objects
::    5. Final Compare
::---------------------------------------------------------------

:Main
REM Display Program Information
ECHO Program Start Time: %Time%
CALL :Info

REM set the working directory
CD /D "%~dp0"

REM generate variables for timestamping folders/files
CALL :TimeStamper

REM Log the parameters set for Migration, to review what was run per execution
CALL :Archiver "Migration_Parameters.txt"

REM Load the following variables from "Migration_Parameters.txt":
REM   1. srcEnv -> from what Environment will the project come from
REM   2. destEnv -> to what Environment will the project be copied to
REM   3. projName -> Peoplesoft App Designer Project Name
REM   4. backupDir -> Directory to create the backup
REM   5. psideDir -> Peoplesoft Bin Directory with the pside.exe
CALL :VarLoader "Migration_Parameters.txt"

REM Load Variables To Be used like Translate Tables for Database Name (i.e.):
REM   1. DEV maps to HCM91DEV
REM   2. STG maps to HCM91STG
REM   3. TST maps to HCM91TST
REM   4. PRJ maps to HCM91PRJ
REM   5. PRD maps to HCM91PRD
CALL :VarLoader "Directory_List.txt"

ECHO/
ECHO Project Name: %projName%
ECHO/

REM Required inputs for Source
ECHO Source Environment: %srcEnv%
REM Uses the translate table value for the DB name
SET srcDb=!%srcEnv%!
SET /p "srcUser=Enter source user: "
CALL :GetPassword srcPass "Enter source password: "
ECHO/

REM Required inputs for Destination
ECHO Destination Environment: %destEnv%
SET destDb=!%destEnv%!
SET /p "destUser=Enter destination user: "
CALL :GetPassword destPass "Enter destination password: "
ECHO/

ECHO Project Name: %projName%
ECHO/

REM Verify
ECHO --Project Migration Parameters--
ECHO Source Database: %srcDb%
ECHO Destination Database: %destDb%
ECHO Project Name: %projName%
ECHO Backup Directory: %backupDir%
ECHO/

REM confirmation prior to migration
SET /p "confirm=Proceed with Migration (Y/N): "
IF /I "%confirm%" NEQ "Y" GOTO:EOF
ECHO/

REM To be generated Folders
SET "genDir=%yyyymmdd%_%hhmmss%\%srcEnv% to %destEnv%\%projName%"
SET "iniReportPath=%genDir%\Initial"
SET "backupProjectCopyFilePath=%genDir%\Backup"
SET "finReportPath=%genDir%\Final"

ECHO --Relative File Paths to be created Based on Backup Directory--
ECHO General Dir: %genDir%
ECHO Initial Compare Dir: %iniReportPath%
ECHO Backup Dir %backupProjectCopyFilePath%
ECHO Final Compare Dir: %finReportPath%
ECHO/

REM Folder Generation - Uses PUSHD and POPD to accomodate shared folders also
ECHO --Generate Folders--
ECHO Backup Directory Set: %backupDir%
PUSHD %backupDir%
IF ERRORLEVEL 1 ECHO ERROR^^! backupDir not found. && GOTO:EOF
ECHO Directory After PUSHD: %CD%
ECHO Creating %genDir%
MKDIR "%genDir%"
ECHO Creating %iniReportPath%
MKDIR "%iniReportPath%"
ECHO Creating %backupProjectCopyFilePath%
MKDIR "%backupProjectCopyFilePath%"
ECHO Creating %finReportPath%
MKDIR "%finReportPath%"
POPD
ECHO Directory After POPD: %CD%
ECHO/

REM Folder Verification
IF NOT EXIST "%backupDir%\%genDir%" ECHO ERROR^^! Project Directory not created. && GOTO:EOF
IF NOT EXIST "%backupDir%\%iniReportPath%" ECHO ERROR^^! Initial Folder Directory not created. && GOTO:EOF
IF NOT EXIST "%backupDir%\%backupProjectCopyFilePath%" ECHO ERROR^^! Backup Folder Directory not created. && GOTO:EOF
IF NOT EXIST "%backupDir%\%finReportPath%" ECHO ERROR^^! Final Folder Directory not created. && GOTO:EOF

REM Prep Full Log Filenames And Assign to Variables
SET "log1=%backupDir%\%iniReportPath%\Log_Compare_%yyyymmdd%_%hhmmss%.txt"
SET "log2=%backupDir%\%backupProjectCopyFilePath%\Log_CopyProj_%yyyymmdd%_%hhmmss%.txt"
SET "log3=%backupDir%\%backupProjectCopyFilePath%\Log_BackupCopy_%yyyymmdd%_%hhmmss%.txt"
SET "log4=%backupDir%\%genDir%\Log_CopyAll_%yyyymmdd%_%hhmmss%.txt"
SET "log5=%backupDir%\%finReportPath%\Log_Compare_%yyyymmdd%_%hhmmss%.txt"

REM pside.exe with compare arguments
CALL :InitialCompare

REM pside.exe with copy arguments for project definition only
CALL :CopyProjDefnOnly

REM pside.exe with copy arguments to create destination backup
CALL :BackupDestToFile

REM pside.exe full project with objects copy (actual migration)
CALL :CopyProjWObj

REM pside.exe with compare arguments
CALL :FinalCompare

ECHO Program End Time: %Time%
PAUSE

:END
ENDLOCAL
GOTO:EOF

::----------------------------
::Functions Below
::----------------------------

:Info
  ECHO Program that simplifies project migration
  ECHO Faster speed compared to manual
  ECHO folder directories are all automatically created
  ECHO verifies said directories
  ECHO Nothing missed this way unlike manually doing it
  ECHO Program does does not proceed if a prior step is not yet done
  ECHO There are 5 pside steps:
  ECHO 1. Initial Compare
  ECHO 2. Copy Project to prepare for Target Backup
  ECHO 3. Backup Copy to File
  ECHO 4. Copy Project and Objects
  ECHO 5. Final Compare
  ECHO Developed By: Nestor B. Gramata Jr.
  ECHO Last Update: 20171206
  ECHO/
GOTO:EOF

:TimeStamper
  REM Prepare date suffix
  SET "year=%date:~10,4%"
  SET "month=%date:~4,2%"
  SET "day=%date:~7,2%"
  SET "yyyymmdd=%year%%month%%day%"

  REM Prepare time suffix
  IF "%TIME:~0,1%"==" " (
    SET hr=0%TIME:~1,1%
  ) ELSE (
    SET hr=%TIME:~0,2%
  )
  SET "min=%TIME:~3,2%"
  SET "sec=%TIME:~6,2%"
  SET "hhmmss=%hr%%min%%sec%"
GOTO:EOF

:Archiver
  SET archFile=%~1
  ECHO Archiver Working Directory: %CD%
  REM create Archive folder if it does not exist
  IF NOT EXIST "Archive" MKDIR "Archive"
  IF NOT EXIST "Archive" ECHO ERROR^^! Lacking Write Permissions && GOTO:EOF
  REM copy executed file input
  COPY /-Y "%archFile%" "Archive\%yyyymmdd%_%hhmmss%_%archFile%"
GOTO:EOF

:VarLoader
  SET loadFile=%~1
  REM Load Directory Variables From A File
  FOR /F "eol=; tokens=1,2 delims==" %%a in (%loadFile%) do (
    SET "%%a=%%b"
  )
GOTO:EOF
  
:VerifyWait
  SET varFile=%~1
  ECHO Processing... start time: %TIME%
  :Waiter
    TIMEOUT /T 2 /NOBREAK > NUL 2>&1
    find /I "Command line process successfully completed." "%varFile%" > NUL 2>&1
    IF ERRORLEVEL 1 (
      GOTO:Waiter
  )
  ECHO Processing... end time: %TIME%
GOTO:EOF

:InitialCompare
  REM Execute Pside Scripts
  ECHO 1 -- Initial Compare
  ECHO Dir: %iniReportPath%
  %psideDir%\pside ^
  -PJM "%projName%" ^
  -CT ORACLE ^
  -CD "%srcDb%" ^
  -CO "%srcUser%" ^
  -CP "%srcPass%" ^
  -TD "%destDb%" ^
  -TO "%destUser%" ^
  -TP "%destPass%" ^
  -LF "%log1%" ^
  -AF 0 ^
  -PPL 0 ^
  -DDL 0 ^
  -CFD 0 ^
  -CFF 0 ^
  -LNG ALL ^
  -FLTR 11111 11111 11111 11111 11111 ^
  -CMT 1 ^
  -TGT 1 ^
  -ROD "%backupDir%\%iniReportPath%" ^
  -CMTBL 1 ^
  -CMXML 1 -HIDE -QUIET
  CALL :VerifyWait "%log1%"
  ECHO/
GOTO:EOF

:CopyProjDefnOnly
  ECHO 2 -- Copy Project
  ECHO Dir: %backupProjectCopyFilePath%
  %psideDir%\pside ^
  -PJC "%projName%" ^
  -CT ORACLE ^
  -CD "%srcDb%" ^
  -CO "%srcUser%" ^
  -CP "%srcPass%" ^
  -TD "%destDb%" ^
  -TO "%destUser%" ^
  -TP "%destPass%" ^
  -LF "%log2%" ^
  -OVD 0 ^
  -OBJ 41 ^
  -AF 0 ^
  -PPL 0 ^
  -DDL 0 ^
  -CFD 0 ^
  -CFF 0 ^
  -LNG ALL -HIDE -QUIET
  CALL :VerifyWait "%log2%"
  ECHO/
GOTO:EOF

:BackupDestToFile
  ECHO 3 -- Backup Copy to File
  ECHO Dir: %backupProjectCopyFilePath%
  %psideDir%\pside ^
  -PJTF "%projName%" ^
  -CT ORACLE ^
  -CD "%destDb%" ^
  -CO "%destUser%" ^
  -CP "%destPass%" ^
  -LF "%log3%" ^
  -FP "%backupDir%\%backupProjectCopyFilePath%" ^
  -OVD 0 ^
  -RST 1 ^
  -OVW 1 ^
  -AF 0 ^
  -PPL 0 ^
  -DDL 0 ^
  -CFD 0 ^
  -CFF 0 ^
  -LNG ALL -HIDE -QUIET
  CALL :VerifyWait "%log3%"
  ECHO/
GOTO:EOF

:CopyProjWObj
  ECHO 4 -- Copy Project and Objects
  ECHO Dir: %genDir%
  %psideDir%\pside ^
  -PJC "%projName%" ^
  -CT ORACLE ^
  -CD "%srcDb%" ^
  -CO "%srcUser%" ^
  -CP "%srcPass%" ^
  -TD "%destDb%" ^
  -TO "%destUser%" ^
  -TP "%destPass%" ^
  -LF "%log4%" ^
  -OVD 0 ^
  -AF 0 ^
  -PPL 0 ^
  -DDL 0 ^
  -CFD 0 ^
  -CFF 0 ^
  -LNG ALL -HIDE -QUIET
  CALL :VerifyWait "%log4%"
  ECHO/
GOTO:EOF

:FinalCompare
  ECHO 5 -- Final Compare
  ECHO Dir: %finReportPath%
  %psideDir%\pside ^
  -PJM "%projName%" ^
  -CT ORACLE ^
  -CD "%srcDb%" ^
  -CO "%srcUser%" ^
  -CP "%srcPass%" ^
  -TD "%destDb%" ^
  -TO "%destUser%" ^
  -TP "%destPass%" ^
  -LF "%log5%" ^
  -AF 0 ^
  -PPL 0 ^
  -DDL 0 ^
  -CFD 0 ^
  -CFF 0 ^
  -LNG ALL ^
  -FLTR 11111 11111 11111 11111 11111 ^
  -CMT 1 ^
  -TGT 1 ^
  -ROD "%backupDir%\%finReportPath%" ^
  -CMTBL 1 ^
  -CMXML 1 -HIDE -QUIET
  CALL :VerifyWait "%log5%"
  ECHO/
GOTO:EOF

::---------------------------------------------------------------
::--------START PASSWORD MASKING FUNCTION------------------------
::---------------------------------
:: Password-masking code based on http://www.dostips.com/forum/viewtopic.php?p=333538#p33538
:: as referenced by someone in a forum (link now doesn't exist)
:: Modified by: Nestor B. Gramata Jr.
:: Arguments:
::   1. %~1 -> Variable to store password in
::   2. %~2 -> Prompt String
::---------------------------------
:GetPassword
SET "_password="

REM Way to store backspace character in a variable
FOR /f %%a IN ('"PROMPT;$H&for %%b IN (carriageReturner) DO REM"') DO SET "BS=%%a"

REM Way to print messages without carriage return
SET /p "=%~2"<NUL

::--------------Start Enter Key Loop---------------
:KeyLoop
  SET "key="
  REM Way to get inputs by character
  FOR /f "delims=" %%a IN ('XCOPY /w "%~f0" "%~f0" 2^>NUL') DO IF NOT DEFINED key SET "key=%%a"
  SET "key=%key:~-1%"

  REM Action based on captured key
  IF DEFINED key (
    IF "%key%"=="%BS%" (
      IF DEFINED _password (
        SET "_password=%_password:~0,-1%"
        SET /p "=%BS% %BS%"<NUL
      )
    ) ELSE (
        SET "_password=%_password%%key%"
        SET /p "=x"<NUL
    )
    GOTO :KeyLoop
  )
::--------------End Enter Key Loop-----------------

ECHO/

REM Return password value
SET "%~1=%_password%
GOTO:EOF
::--------END PASSWORD MASKING FUNCTION--------------------------
::---------------------------------------------------------------