@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
REM Created By Nestor B. Gramata Jr.
REM Created: 20171120
REM Program is used to pull server utilization data
REM Program sends an email Regarding Server Utilization
REM Email Subject has a status that is set to either "ALERT" or "OK"
REM  1. ALERT - one or more of the server utilization data exceeds thresholds set
REM  2. OK - no server utilization data exceeds thresholds set
REM Scheduled to run daily
REM Loads 3 variables from Config_Threshold.txt
REM  1. lowThresholdDrive
REM  2. lowThresholdMem
REM  3. highThresholdCPU

:MAIN
  REM Change to working directory
  CD /D "%~dp0"

  REM Create temporary folder to place raw and processed values
  SET "tempDir=temp_daily"
  IF NOT EXIST "%tempDir%" MKDIR "%tempDir%"
  
  REM Load Variables
  REM  1. lowThresholdDrive
  REM  2. lowThresholdMem
  REM  3. highThresholdCPU
  FOR /F "usebackq eol=; tokens=1,2 delims==" %%a IN ("Config_Threshold.txt") DO (
    SET "%%a=%%b"
  )

  REM Check values if program loaded variables correctly
  ECHO lowThresholdDrive: %lowThresholdDrive%%%
  ECHO lowThresholdMem: %lowThresholdMem%%%
  ECHO highThresholdCPU: %highThresholdCPU%%%

  REM Set Error Flag to 0
  SET ERRORFLAG=0

  REM Clear Temporary Files
  (
    DEL "%tempDir%\temp_raw_diskDriveInfo.txt"
    DEL "%tempDir%\temp_raw_memInfo.txt"
    DEL "%tempDir%\temp_raw_CPUInfo.txt"
    DEL "%tempDir%\temp_processed_diskDriveInfo.txt"
    DEL "%tempDir%\temp_processed_memInfo.txt"
    DEL "%tempDir%\temp_processed_CPUInfo.txt"
    DEL "%tempDir%\email_subj.txt"
    DEL "%tempDir%\email_body.html"
  ) 2>NUL
  
  REM Get Free Disk Drive Space Raw Data
  WMIC path win32_logicaldisk get Caption,FreeSpace,Size /value | find "=" >> "%tempDir%\temp_raw_diskDriveInfo.txt"
  REM Parse query raw data to separate variables between different disk drives
  FOR /F "usebackq eol=; tokens=1,2 delims==" %%a IN ("%tempDir%\temp_raw_diskDriveInfo.txt") DO (
    SET %%a=%%b
    REM Check if last variable per disk drive is loaded
    IF "%%a" EQU "Size" (
        CALL:ProcessDriveInfo
    )
  )

  REM Get Free Memory Raw Data
  WMIC OS get FreePhysicalMemory,TotalVisibleMemorySize /value | find "=" >> "%tempDir%\temp_raw_memInfo.txt"
  CALL:ProcessMemoryInfo

  REM Get CPU Utilization Raw Data
  WMIC cpu get LoadPercentage /value | find "=" >> "%tempDir%\temp_raw_CPUInfo.txt"
  CALL:ProcessCPUInfo

  ECHO ERRORFLAG: %ERRORFLAG%
  
  CALL:CreateEmail
  
  CALL:SendEmail
:END
ENDLOCAL
GOTO:EOF

::-------------------------------------------------------
::-----------------Functions Below-----------------------
::-------------------------------------------------------

:ProcessDriveInfo
  REM Stop processing data if size for a disk drive is not defined
  IF "%Size%"=="" (
    GOTO:Eof
  )
  REM Calculate and format output via powershell
  FOR /F %%a IN ('powershell -command "(%FreeSpace%/%Size%*100).tostring(\"#\")"') DO (
    SET "procFreeSpace=%%a"
  )
  
  ECHO %caption% Free Space: %procFreeSpace%%%
  
  REM Output processed values in HTML format
  REM Value in color "Green" if it does not exceed the threshold
  REM Value in color "RED" if it exceeds threshold
  SET colorFreeSpace=#5FBE19
  IF %procFreeSpace% LEQ %lowThresholdDrive% (
    SET ERRORFLAG=1
    SET colorFreeSpace=RED
  )
  (
    ECHO     ^<tr^>
    ECHO       ^<td^>%caption%\ Drive Space^</td^>
    ECHO       ^<td style="background-color: %colorFreeSpace%;"^>%procFreeSpace%%%^</td^>
    ECHO     ^</tr^>
  ) >> "%tempDir%\temp_processed_diskDriveInfo.txt"
GOTO:Eof

:ProcessMemoryInfo
  REM Load Raw Data
  FOR /F "usebackq tokens=1" %%a IN ("%tempDir%\temp_raw_memInfo.txt") DO SET "%%a"
  REM Calculate and format output via powershell
  FOR /F %%a IN ('powershell -command "(%freePhysicalMemory%/%totalVisibleMemorySize%*100).tostring(\"#\")"') DO (
    SET "procFreeMem=%%a"
  )
  
  ECHO Free Memory: %procFreeMem%%%
  
  REM Output processed values in HTML format
  REM Value in color "Green" if it does not exceed the threshold
  REM Value in color "RED" if it exceeds threshold
  SET colorFreeMem=#5FBE19
  IF %procFreeMem% LEQ %lowThresholdMem% (
    SET ERRORFLAG=1
    SET colorFreeMem=RED
  )
  (
    ECHO     ^<tr^>
    ECHO       ^<td^>Free Memory^</td^>
    ECHO       ^<td style="background-color: %colorFreeMem%;"^>%procFreeMem%%%^</td^>
    ECHO     ^</tr^>
  ) >> "%tempDir%\temp_processed_memInfo.txt"
GOTO:Eof

:ProcessCPUInfo
  REM Load and Calculate the Average CPU Utilization
  SET loadPercentage=0
  SET count=0
  FOR /F "usebackq eol=; tokens=2 delims==" %%a IN ("%tempDir%\temp_raw_CPUInfo.txt") DO (
    SET /A "loadPercentage=!loadPercentage!+%%a" 2>NUL
    SET /A "count=!count!+1"
  )
  SET /A loadPercentage=%loadPercentage%/%count%
  
  ECHO CPU UTIL: %loadPercentage%%%
  
  REM Output processed values in HTML format
  REM Value in color "Green" if it does not exceed the threshold
  REM Value in color "RED" if it exceeds threshold
  SET colorCPUUtil=#5FBE19
  IF %loadPercentage% GEQ %highThresholdCPU% (
    SET ERRORFLAG=1
    SET colorCPUUtil=RED
  )
  (
    ECHO     ^<tr^>
    ECHO       ^<td^>CPU Utilization^</td^>
    ECHO       ^<td style="background-color: %colorCPUUtil%;"^>%loadPercentage%%%^</td^>
    ECHO     ^</tr^>
  ) >> "%tempDir%\temp_processed_CPUInfo.txt"
GOTO:Eof

:CreateEmail
  REM Store hostname to variable
  FOR /F "eol=; tokens=1 delims= " %%a IN ('HOSTNAME') DO SET myHostName=%%a
  
  REM Email Subject
  IF %ERRORFLAG% GEQ 1 (
    SET serverStat=ALERT
  ) ELSE (
    SET serverStat=OK
  )
  ECHO %serverStat% -- Windows %myHostName% -- Daily Server Monitoring >> "%tempDir%\email_subj.txt"
  
  REM Email Body
  (
    ECHO ^<html^>
    ECHO ^<head^>
    ECHO ^<style^>
    ECHO   body {
    ECHO     background-color: none;
    ECHO     color: black;
    ECHO     font-size: 11px;
    ECHO   }
    ECHO   table {
    ECHO     background-color: none;
    ECHO     border: 1px solid black;
    ECHO     padding: 2px;
    ECHO     width: 180px;
    ECHO     border-collapse: collapse;
    ECHO   }
    ECHO   td {
    ECHO     border-spacing: 3px;
    ECHO     background-color: none;
    ECHO     border: 1px solid black;
    ECHO     padding: 5px;
    ECHO     text-align: center;
    ECHO     font-size: 14px;
    ECHO     color: black;
    ECHO   }
    ECHO   td:first-child {
    ECHO     width: 70%%;
    ECHO   }
    ECHO   #topHeader {
    ECHO     font-size: 17px;
    ECHO     font-weight: bold;
    ECHO     text-align: left;
    ECHO     color: black;
    ECHO   }
    ECHO ^</style^>
    ECHO ^</head^>
    ECHO ^<body^>
    ECHO   ^<table^>
    ECHO     ^<tr^>
    ECHO       ^<td colspan="2" id="topHeader"^>Windows Server^<br/^>%myHostName%^</td^>
    ECHO     ^</tr^>
    
    REM Get Processed Disk Space Info
    TYPE "%tempDir%\temp_processed_diskDriveInfo.txt"
    REM Get Processed Free Memory/RAM Info
    TYPE "%tempDir%\temp_processed_memInfo.txt"
    REM Get Processed CPU Utilization Info
    TYPE "%tempDir%\temp_processed_CPUInfo.txt"
    
    ECHO   ^</table^>
    ECHO   ^<br/^>
    ECHO   This is an auto-generated email.^<br/^>
    ECHO   Script is deployed in the server indicated by the email.
    ECHO ^</body^>
    ECHO ^</html^>
  ) >> "%tempDir%\email_body.html"
GOTO:Eof

:SendEmail
  cscript //NoLogo "SendEmail.vbs" /subjectFile:"%tempDir%\email_subj.txt" /bodyFile:"%tempDir%\email_body.html"
GOTO:Eof