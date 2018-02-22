'---------------------------------------------------
' Program : Email Notifier
' Version : V4.0
' Created by : Nestor B. Gramata Jr.
' Modified: November 15, 2017
' Filename: SendEmail.vbs
'---------------------------------------------------
' Description:
'  Revised the Script to enable easy and fast deployment
'    of email notifications
'  This VBScript takes 2 arguments and uses it to send an e-mail
' 
' Required File:
'  This file should be in the same directory with "Config_SendEmail.txt"
'
'---------------------------------------------------

'Initialize Variables
subjectFile = "Email_Subj.txt"
bodyFile = "temp.tmp"

' Pull config information from text file
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set listFile = objFSO.OpenTextFile("Config_SendEmail.txt")
Do Until listFile.AtEndOfStream
  lineContent = listFile.ReadLine
  If Left(lineContent, 1) <> ";" And Left(lineContent, 1) <> " " And Left(lineContent, 1) <> "" Then
    a = Split(lineContent, "=", -1, 1)
    Select Case a(0)
      Case "smtpServer"
        smtpServer = a(1)
      Case "emailFrom"
        emailFrom = a(1)
      Case "emailTo"
        emailTo = a(1)
	    Case "subjectFile"
        subjectFile = a(1)
      Case "bodyFile"
        bodyFile = a(1)
      Case Else
				MsgBox "Unidentified Configuration: " & a(0)
        'objShell.Popup "Variable " + a(0) + " Not Recognized!!!", 3, "Warning", 48
    End Select
  End If
Loop

' Populate email subject variable from text file
Set fso = CreateObject("Scripting.FileSystemObject")
Set file = fso.OpenTextFile (subjectFile)
Do Until file.AtEndofStream
  subjectArg = subjectArg & file.Readline & vbCrlf
Loop
file.close

' Populate email body variable from text file
Set fso = CreateObject("Scripting.FileSystemObject")
Set file = fso.OpenTextFile (bodyFile)
Do Until file.AtEndofStream
  bodyArg = bodyArg & file.Readline & vbCrlf
Loop
file.close

' Prepare Delivery Config
sch = "http://schemas.microsoft.com/cdo/configuration/"
Set CdoConfig = CreateObject("CDO.Configuration")
With CdoConfig.fields
	.item(sch & "sendusing") = 2 ' cdoSendUsingPort
	.item(sch & "smtpserver") = smtpServer
	'.item(sch & "smtpserverport") = 465 'ignore this and it will still use the default 25
	'.item(sch & "smtpauthenticate") = 1
	'.item(sch & "smtpusessl") = true
	'.item(sch & "sendusername") = emailFrom
	'.item(sch & "sendpassword") = "Password"	
.update
End With

' Prepare Message Object
Set CdoMessage = CreateObject("CDO.Message")
With CdoMessage
Set .configuration = cdoConfig
	.from = emailFrom
	.to = emailTo
	.cc = ""
	.subject = subjectArg
	.textBody = bodyArg
	.send
End With

' Reset Configurations and Message
Set CdoConfig = Nothing
Set CdoMessage = Nothing