'---------------------------------------------------
' Program : Automated Microsoft SQL Database Backup
' Version : V1.0
' Created by : Nestor B. Gramata Jr.
' Date: May 2, 2017
' Filename: SendEmail.vbs
'---------------------------------------------------
' Description:
'  This VBScript takes 2 arguments and uses it to send an e-mail
'
' Required Inputs/Arguments:
'  databasename -> name of database, used for email body and subject
'  logname      -> Directory and Filename of log file to attach
' 
' This is part of a group of files including:
'  1. MicSQL_Backup@DBNAME.cmd               (i.e. MicSQL_Backup@HR91.cmd)
'  2. CreateTask_DAYofWEEK_HHMMSS@DBNAME.cmd (i.e. CreateTask_TUE_000500@HR91.cmd)
'  3. DeleteTask@DBNAME.cmd                  (DeleteTask@HR91.cmd)
'  4. SendEmail.vbs
'  5. StoreSQLPass.cmd
'
' IMPORTANT:
'  Create a separate empty folder where to place these 4 files! (i.e. E:\BACKUP\HR91\Automated)
'  This is to prevent overwriting of files that may probably have the same name as that generated by the script
'
' Instructions:
'  1. Put this file in the same directory with:
'       MicSQL_Backup@DBNAME.cmd
'       CreateTask_DAYofWEEK_HHMMSS@DBNAME.cmd
'       DeleteTask@DBNAME.cmd 
'---------------------------------------------------

Dim sch, cdoConfig, cdoMessage, databasename, logname

databasename = WScript.Arguments.Unnamed(0)
logname = WScript.Arguments.Unnamed(1)

sch = "http://schemas.microsoft.com/cdo/configuration/"
Set cdoConfig = CreateObject("CDO.Configuration")
With cdoConfig.Fields
	.Item(sch & "sendusing") = 2 ' cdoSendUsingPort
	.Item(sch & "smtpserver") = "10.164.91.22"
	'.Item(sch & "smtpserverport") = 25 'ignore this and it will still use the default 25
	'.Item(sch & "smtpserverpickupdirectory") = "c:\inetpub\mailroot\pickups" 'not needed when sendusing is 2
	.update
End With
Set cdoMessage = CreateObject("CDO.Message")
With cdoMessage
Set .Configuration = cdoConfig
	.From = "auto_hotbackup@peoplesoft.com"
	.To = "SF.Oracle.STS.AAES@accenture.com"
	'.To = "nestor.b.gramata.jr@accenture.com"
	.Cc = ""
	.Subject = "SQL Server: " & databasename & " Backup"
	.TextBody = "Attached is a log file conerning the SQL Server: " & databasename & " Backup"
	.AddAttachment logname
	.Send
End With
Set cdoMessage = Nothing
Set cdoConfig = Nothing
' MsgBox "Email Sent"

