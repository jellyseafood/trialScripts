@ECHO OFF
CD %~dp0
REM Encode
SET /p encServer="Enter Server: "
SET /p encUser="Enter User: "
CALL "Credential_Manager.cmd" enc cred.dat "%encServer%" "%encUser%"
