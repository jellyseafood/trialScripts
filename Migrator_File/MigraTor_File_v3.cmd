@ECHO off
SETLOCAL ENABLEDELAYEDEXPANSION

:Initialize
REM set the working directory
CD /D "%~dp0"

REM create Log folder if it does not exist
IF NOT EXIST "%logDir%" MKDIR "%logDir%"

REM obtain directory variables from file
REM Loads the ff:
REM   1. DEV
REM   2. STG
REM   3. TST
REM   4. PRJ
REM   5. PRD
REM   6. backupDir
REM   7. logDir
FOR /F "eol=; tokens=1,2 delims==" %%a in (Directory_List.txt) do (
  SET "%%a=%%b"
)

:Command_Interface
CLS
ECHO ======================================================
ECHO ==============File Migration Program==================
ECHO ======================================================
ECHO Created By: Nestor B. Gramata Jr.
ECHO Last Update: 20171130
ECHO ======================================================
ECHO/

REM Required inputs
ECHO Input the following...
SET /p "sourceI=Source Environment (DEV,STG,PRD,TST,PRJ): "
SET sourceDir=!%sourceI%!
SET /p "destI=Destination Environment (DEV,STG,PRD,TST,PRJ): "
SET destDir=!%destI%!

REM show details for verification
ECHO/
ECHO Source Environment:      %sourceI%
ECHO Source Directory:        %sourceDir%
ECHO/
ECHO Destination Environment: %destI%
ECHO Destination Directory:   %destDir%
ECHO/
ECHO SQR Files (File_List.txt):
FOR /F "eol=; tokens=1 delims=" %%a IN (File_List.txt) DO (
  ECHO      %%a
)
ECHO/
ECHO Backup Directory: %backupDir%
ECHO Log Directory:    %logDir%

:Confirmation
REM confirmation prior to migration
ECHO/
SET /p "confirm=Proceed with Migration (Y/N): "
IF /I "%confirm%" NEQ "Y" GOTO:EOF
ECHO/

:Prepare_Logs
REM Prepare date suffix
SET "year=%date:~10,4%"
SET "month=%date:~4,2%"
SET "day=%date:~7,2%"
SET "yyyymmdd=%year%%month%%day%"

REM Prepare time suffix
IF "%time:~0,1%"==" " (
  SET "hr=0%time:~1,1%"
) ELSE (
  SET "hr=%time:~0,2%"
)
SET "min=%time:~3,2%"
SET "sec=%time:~6,2%"
SET "hhmmss=%hr%%min%%sec%"

:Backup_Dir_Create
REM BackupDirs Setup
SET "extBackupDir=%yyyymmdd%\%sourceI% to %destI%\SQR"
SET "parBackupSource=%extBackupDir%\%sourceI%"
SET "parBackupDest=%extBackupDir%\%destI%"
SET "fullExtBackupDir=%backupDir%\%extBackupDir%"
SET "backupSource=%fullExtBackupDir%\%sourceI%"
SET "backupDest=%fullExtBackupDir%\%destI%"

ECHO ---------START Create Backup Folder------------
ECHO Dir: %CD% 
PUSHD "%backupDir%"
ECHO PUSHD %backupDir%
ECHO Dir: %CD%

ECHO/
ECHO --Creating Source Backup %sourceI%
ECHO %fullExtBackupDir%\%sourceI%
MKDIR "%parBackupSource%"
ECHO/
ECHO --Creating Destination Backup %destI%
ECHO %fullExtBackupDir%\%destI%
MKDIR "%parBackupDest%"
POPD
ECHO ---------END Create Backup Folder--------------
ECHO/

:Verify_Written_Backup_Dirs
REM verify that given directories were created, this verifies write permissions
IF NOT EXIST "%sourceDir%" ECHO ERROR^^! Invalid Source Dir && GOTO:EOF
IF NOT EXIST "%destDir%" ECHO ERROR^^! Invalid Destination Dir && GOTO:EOF
IF NOT EXIST "%backupSource%" ECHO ERROR^^! Invalid Backup Source Dir && GOTO:EOF
IF NOT EXIST "%backupDest%" ECHO ERROR^^! Invalid Backup Destination Dir && GOTO:EOF
IF NOT EXIST "%logDir%" ECHO ERROR^^! Invalid Log Dir && GOTO:EOF

:Backup_And_Migration
REM Iterate through the SQR List
FOR /F "eol=; tokens=1 delims=" %%a IN (File_List.txt) DO (
  REM Create backup in destination
  ECHO ---------START Backup------------ 
  ECHO --Creating Backup of Dest File on Dest Folder
  ECHO "%destDir%\%%a" to "%destDir%\%%a_%yyyymmdd%_%hhmmss%"
  COPY /-Y "%destDir%\%%a" "%destDir%\%%a_%yyyymmdd%_%hhmmss%"
  ECHO/
  
  REM Create backup in backup folders
  ECHO --Copying Source File to Backup Source Folder
  ECHO %sourceDir%\%%a" to "%backupSource%\%%a_%yyyymmdd%_%hhmmss%
  COPY /-Y "%sourceDir%\%%a" "%backupSource%\%%a_%yyyymmdd%_%hhmmss%"
  ECHO/
  ECHO --Copying Dest File to Backup Dest Folder
  ECHO "%destDir%\%%a" to "%backupDest%\%%a_%yyyymmdd%_%hhmmss%"
  COPY /-Y "%destDir%\%%a" "%backupDest%\%%a_%yyyymmdd%_%hhmmss%"
  ECHO ---------END Backup--------------
  ECHO/
  ECHO ---------START Migration------------ 
  REM Do Migration
  ECHO --Migration proper of file %%a
  ECHO Source: %sourceDir%
  ECHO Destination: %destDir%
  COPY "%sourceDir%\%%a" "%destDir%\%%a"
  ECHO ---------END Migration--------------
  ECHO/
  ECHO/
) >> "%logDir%\SQR_Mig_%yyyymmdd%_%hhmmss%.log" 2>>&1

:Post_Migration_Verifier
FOR /F "eol=; tokens=1 delims=" %%a IN (File_List.txt) DO (
  ECHO/
  ECHO ------------------------------------------------------
  ECHO --SQR Verification: %%a
  REM Display dirs with time for verification
  ECHO ------SOURCE------------------------------------------
  DIR "%sourceDir%\%%a" | findstr "Directory AM PM File"
  ECHO ------DESTINATION-------------------------------------
  DIR "%destDir%\%%a" | findstr "Directory AM PM File"
  ECHO ------------------------------------------------------
  ECHO/
) >> "%logDir%\SQR_Mig_%yyyymmdd%_%hhmmss%.log" 2>>&1

REM Display logs in cmd prompt
TYPE "%logDir%\SQR_Mig_%yyyymmdd%_%hhmmss%.log"

PAUSE