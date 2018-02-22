@ECHO off
SETLOCAL
REM Created By: Nestor B. Gramata Jr.
REM Modified: 20171115
REM Encrypts and Decrypts Credentials
REM This program requires 4 arguments for ENC and 3 for DEC:
REM  1. MODE
REM      ENC - Prompts for a password then stores credentials
REM      DEC - Returns an unencrypted SET of credentials
REM  2. Credential Filename (i.e. "C:\myProgramFile\storage creds\secretPass.txt")
REM  3. Server Name (i.e. WIN-eDFSLKJ342) 
REM  4. Username (i.e. JuanRizal) -- only required for ENC
REM
REM Sample:
REM Credential_Manager ENC "C:\myProgs\user\cred1.txt" WIN-sErever123 JuanDoe
REM Credential_Manager DEC "C:\myProgs\user\cred1.txt" WIN-sErever123
REM Credential_Manager ENC "C:\myProgs\user\cred1.txt" "WIN-sErever123" "JuanDoe"

:Main
IF [%~1]==[] GOTO:HelpInfo
IF [%~2]==[] GOTO:HelpInfo
IF [%~3]==[] GOTO:HelpInfo
IF [%~1]==[ENC] (
  IF [%~4]==[] GOTO:HelpInfo
)
REM TODO create loader to accept comma delimited input.
REM TODO create loader to accept tab separated input

SET credFile=%~2
SET serverName=%~3

IF /I [%~1]==[DEC] GOTO:CredentialDecrypt

SET userName=%~4
IF /I [%~1]==[ENC] GOTO:CredentialEncrypt

EXIT /b 1


::=======================Sub-Routines Below==========================

:CredentialEncrypt
  REM used powershell since cmd lacks encrypt functions
  REM delimiter is <TAB>
  IF not exist %credFile% ECHO Server	Username	Password >%credFile%
  SET "psCommand=powershell -Command "$ErrorActionPreference = \"SilentlyContinue\"; ^
    $encPass = Read-Host \"Password\" -AsSecureString ^| ConvertFrom-SecureString ; ^
    IF ($varExist=type %credFile% ^| Select-String -pattern \"^^%serverName%\") ^
    {(get-content \"%credFile%\") -replace \"$varExist\" , \"%serverName%`t%userName%`t$encPass\" ^| set-content \"%credFile%\"} ^
    ELSE {Add-Content -path \"%credFile%\" -value \"%serverName%`t%userName%`t$encPass\"}""
  %psCommand%
EXIT /b 0

:CredentialDecrypt
  REM Delimiter is <TAB>
  SET userNamepassWord=
  REM used powershell since cmd lacks encrypt functions
  SET "psCommand=powershell -Command "$ErrorActionPreference = \"SilentlyContinue\"; ^
  IF ($varExist=type \"%credFile%\" ^| Select-String -pattern \"^^%serverName%\") {^
    $User=($varExist -split \"^	\")[1] ; ^
    $encPass=($varExist -split \"^	\")[2] ^| ConvertTo-SecureString ; ^
    $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($encPass) ; ^
    $Pass=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR) ; ^
    ECHO \"$User`t$Pass\" } ^
  ELSE {^
    EXIT 2}""
  %pscommand%
  IF [%ERRORLEVEL%] EQU [2] (
    ECHO %serverName% -- Credential Not Found!
    EXIT /b 2
  )
EXIT /b 0

REM ELSE {ECHO \"%serverName%`t%userName%`t$encPass\" ^>^> \"%credFile%\"}""

:HelpInfo
  ECHO This program requires 4 arguments for ENC and 3 for DEC:
  ECHO 1. MODE
  ECHO 	ENC - Prompts for a password then stores credentials
  ECHO 	DEC - Returns an unencrypted SET of credentials
  ECHO 2. Credential Filename (i.e. "C:\myProgramFile\storage creds\secretPass.txt")
  ECHO 3. Server Name (i.e. WIN-eDFSLKJ342) 
  ECHO 4. Username (i.e. JuanRizal) -- only required for ENC
  ECHO/ 
  ECHO Sample:
  ECHO Credential_Manager ENC "C:\myProgs\user\cred1.txt" WIN-sErever123 JuanDoe
  ECHO Credential_Manager DEC "C:\myProgs\user\cred1.txt" WIN-sErever123
  ECHO Credential_Manager ENC "C:\myProgs\user\cred1.txt" "WIN-sErever123" "JuanDoe"
EXIT /b 1