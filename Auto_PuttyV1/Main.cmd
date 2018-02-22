@ECHO OFF
CD %~dp0

REM %~dp0plink -l %gUser% -pw %gPassword% -batch -m %~dp0linux_commands.txt %gServer%>>%gLogTo% >> %gLogTo% 2>>&1
REM plink -l %gUser% -pw %gPassword% -batch -m %~dp0linux_commands.txt %gServer% >> temp.tmp 2>>&1

REM Current Sessions below:
REM CODP.PDCJCS -> "CODP.PDCJCS" sudo
REM CODP.PDCDB -> "CODP.PDCDB" sudo 
REM heyfit_compute - 129.191.22.63 -> "heyfit_app" sudo
REM heyfit_database – 129.191.22.23 -> "heyfit_db" sudo
REM aws_accenturefit - 54.165.67.118 -> "AccentureFit AWS" sudo
REM Liquid Anki - 129.150.64.172 -> "liquid_anki_db" -> needs credentials
REM VHI PRD compute - 144.21.68.35 -> "VHI_PRD_compute" sudo
REM VHI PRD database - 144.21.68.116 -> "VHI_PRD_database"

REM Decode
FOR /F "usebackq tokens=1,2 delims=	" %%a IN (`call "Credential_Manager.cmd" dec cred.dat liquid`) DO (
  SET userNameLiq=%%a
  SET passWordLiq=%%b
)

(
ECHO ===START===
ECHO 1. CODP.PDCJCS
ECHO ===========
plink -t -batch -m "linux_commands_wKey.txt" "CODP.PDCJCS"
ECHO/
ECHO/
ECHO ===========
ECHO 2. CODP.PDCDB
ECHO ===========
plink -t -batch -m "linux_commands_wKey.txt" "CODP.PDCDB"
ECHO/
ECHO/
ECHO ===========
ECHO 3. heyfit_compute - 129.191.22.63
ECHO ===========
plink -batch -m "linux_commands_wKey.txt" "heyfit_app"
ECHO/
ECHO/
ECHO ===========
ECHO 4. heyfit_database - 129.191.22.2
ECHO ===========
plink -batch -m "linux_commands_wKey.txt" "heyfit_db"
ECHO/
ECHO/
ECHO ===========
ECHO 5. aws_accenturefit - 54.165.67.118
ECHO ===========
plink -batch -m "linux_commands_wKey.txt" "AccentureFit AWS"
ECHO/
ECHO/
ECHO ===========
ECHO 6. Liquid Anki - 129.150.64.172
ECHO ===========
plink -l %userNameLiq% -pw %passWordLiq% -batch -m "linux_commands_liquidAnka.txt" "liquid_anki_db"
ECHO/
ECHO/
ECHO ===========
ECHO 7. VHI PRD compute - 144.21.68.35
ECHO ===========
plink -batch -m "linux_commands_wKey.txt" "VHI_PRD_compute"
ECHO/
ECHO/
ECHO ===========
ECHO 8. VHI PRD database - 144.21.68.116
ECHO ===========
plink -batch -m "linux_commands_wKey.txt" "VHI_PRD_database"
ECHO ===END=====
) > temp.tmp



cscript //NoLogo "SendEmail.vbs"