@echo off
::---------------------------------------------------
:: Program : Automated Microsoft SQL Database Backup
:: Version : V1.0
:: Created by : Nestor B. Gramata Jr.
:: Date: May 2, 2017
:: Filename: StoreSQLPass.cmd
::---------------------------------------------------
:: Description:
::  Stores 1 password in encrypted form by invoking powershell
::
:: This is part of a group of files including:
::  1. MicSQL_Backup@DBNAME.cmd               (i.e. MicSQL_Backup@HR91.cmd)
::  2. CreateTask_DAYofWEEK_HHMMSS@DBNAME.cmd (i.e. CreateTask_TUE_000500@HR91.cmd)
::  3. DeleteTask@DBNAME.cmd                  (i.e. DeleteTask@HR91.cmd)
::  4. SendEmail.vbs
::  5. StoreSQLPass.cmd
::
::---------------------------------------------------

REM StoreSQLPass
echo/
echo NOTE:
echo   only the Windows user who encrypt the password can decrypt it.
echo/
echo SUGGESTION: 
echo   use a common Windows service account (i.e psoft) to run this maintenance program
echo   to avoid problems with decryption
echo/
echo WARNING:
echo   continue below would reset password
echo   blank input would mean no password set
echo/
set "ConfigureConfirm=N"
set /p ConfigureConfirm="Continue [Y,N]: "
if [%ConfigureConfirm%]==[] goto:eof
if /I "%ConfigureConfirm%" NEQ "Y" (
	goto:eof
)

del %~dp0Pass.cred /F /Q 2> NUL
powershell -Command "$ErrorActionPreference = \"SilentlyContinue\"; Read-Host "Password" -assecurestring | ConvertFrom-SecureString | Out-File %~dp0Pass.cred"
