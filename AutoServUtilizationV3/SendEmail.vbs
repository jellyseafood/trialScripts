'---------------------------------------------------
' Program : Email Notifier
' Version : V5.0
' Created by : Nestor B. Gramata Jr.
' Created: November 20, 2017
' Filename: SendEmail.vbs
'---------------------------------------------------
' Description:
'  Created new Script to enable easy and fast deployment
'    of email notifications
'  Sends email from an unauthenticated user
'  This VBScript takes 2 arguments and uses it to send an e-mail
'   1. subjectFile -> Text file loaded to email subject
'   2. bodyFile -> HTML file loaded to email body
'  Sample command below to invoke and pass arguments to this vbScript
'   cscript //NoLogo "SendEmail.vbs" /subjectFile:"temp\email_subj.txt" /bodyFile:"temp\email_body.html"
' Required File:
'  This file should be in the same directory with "Config_SendEmail.txt"
'
'---------------------------------------------------

' Initialize Variables
Set colArgs = WScript.Arguments.Named
subjectFile = colArgs.Item("subjectFile")
bodyFile = colArgs.Item("bodyFile")
'WScript.echo subjectFile & " and " & bodyFile

' Instantiate Object Required To Open Files
Set ObjFSO = CreateObject("Scripting.FileSystemObject")

' Loads the following config information from text file
'  1. smtpServer 
'  2. emailFrom
'  3. emailTo
'  4. subjectFile (if present, overrides arguments passed when calling this program)
'  5. bodyFile (if present, overrides arguments passed when calling this program)
Set file = ObjFSO.OpenTextFile("Config_SendEmail.txt")
Do Until file.AtEndOfStream
  lineContent = file.ReadLine
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
    End Select
  End If
Loop
file.close

' Populate email subject variable from text file
Set file = ObjFSO.OpenTextFile (subjectFile)
Do Until file.AtEndofStream
  subjectArg = subjectArg & file.Readline & vbCrlf
Loop
file.close

' Populate email body variable from text file
Set file = ObjFSO.OpenTextFile (bodyFile)
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
  .item(sch & "smtpserverport") = 25
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
  .htmlBody = bodyArg
  .send
End With

' Reset Config and Message
Set CdoConfig = Nothing
Set CdoMessage = Nothing