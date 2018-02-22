@ECHO OFF
CD %~dp0
REM Decode
SET /p encServer="Enter Server: "
CALL "Credential_Manager.cmd" dec cred.dat "%encServer%"
PAUSE