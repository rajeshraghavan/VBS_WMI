'**************************************************************************************

'Nas_slice_Monitor.vbs
'Author: rajeshr
'Date: 03/29/2009
'Desc: Script to monitor space utilization on NAS Slices

'**************************************************************************************



'***********************
'Main program
'***********************

Dim strPath,objFSO,objstrDrive,strDrive1,strDrive2,strDrive3,objshell
Dim objDrive1,objDrive2,objDrive3,Space1,space2,space3,bytes,StdIn,StdOut,recipients,subj,body
On Error Resume Next
Set StdIn = WScript.StdIn
Set StdOut = WScript.StdOut

'bytes=bytes
Set objshell=wscript.createObject("wscript.shell")
Set objNetwork=wscript.createObject("wscript.Network")
set objFSO=CreateObject("Scripting.FileSystemObject")
Set objArgs=Wscript.Arguments

Drive=objArgs(0)
Share=objArgs(1)

wscript.echo "====================================================================================="

mapdrive objNetwork, Drive, Share

Set objDrive1=objFSO.GetDrive(Drive)
'Wscript.echo FormatNumber((objDrive.AvailableSpace),0)
'Wscript.echo FormatNumber((objDrive.FreeSpace),0)
space1=FormatNumber((objDrive1.FreeSpace),0)
totspace=FormatNumber((objDrive1.TotalSize),0)
totspacegb=(totspace/1024/1024/1024)
'wscript.echo space1
'wscript.echo "Total Space is " & totspacegb
Avspace=(space1/totspace)*100
spacegb=(space1/1024/1024/1024)
spacegb1=Round(spacegb,2)
wscript.echo "Free space remaining on " & Share & " is: " & spacegb1 & "GB"
wscript.echo "Total available space allocated on " & Share & " is: " & totspacegb & "GB"
AvSpace1=Round(AvSpace,2)
AvSpace2=100.00-AvSpace1
wscript.echo "Percentage utilization of the Used Space on " & Share & " is: " & AvSpace2 & "%"
wscript.echo "====================================================================================="
If (AvSpace) < 5 Then 
If (AvSpace) < 1 Then
sendmail "Used Space on " & objArgs(1) & " is above 99%", "The Total used space on the NAS Slice " & objArgs(1) & " is above 99%. The available space is " & spacegb1 & " GB", "mwss.bi.team@qualcomm.com"
else
sendmail "Used Space on " & objArgs(1) & " is above 95%", "The Total used space on the NAS Slice " & objArgs(1) & " is above 95%. The available space is " & spacegb1 & " GB", "mwss.bi.team@qualcomm.com"
'sendmail "Used Space on " & objArgs(1) & " is above 95%", "The Total used space on the NAS Slice " & objArgs(1) & " is above 95%. The available space is " & spacegb & " GB", "rajeshr@qualcomm.com"
End If
End If
strserver = objshell.ExpandEnvironmentStrings("%computername%") 

DisconnectDrive objNetwork, Drive

'***********************
'Sub-routines
'***********************

'***********************
'Mapping the folder
'***********************

Sub MapDrive(objNet, local, network)
On Error Resume Next
Const DRIVE_IN_USE_BY_USER=-2147023694
Const ERR_DRIVE_IN_USE=-2147024811
strCmd = "%comspec% /c net use " & "/" & "Delete " & local
objNet.MapNetworkDrive local, network
'wscript.echo Err.Number
If Err.Number = ERR_DRIVE_IN_USE Then
	'objNet.RemoveNetworkDrive local, True
	objShell.Run strCmd, 0, True
  objNet.MapNetworkDrive local, network
'	sendmail "The share " & network & " has been mapped", "The share " & network & " has been mapped however there was a mapping already exists and had to be removed", "rajeshr@qualcomm.com"	
	ElseIf Err.Number = DRIVE_IN_USE_BY_USER Then
	'objNet.RemoveNetworkDrive local, True
	objShell.Run strCmd, 0, True
	objNet.MapNetworkDrive local, network
	'sendmail "The share " & network & " has been mapped", "The share " & network & " has been mapped however there was a mapping already exists and had to be removed", "rajeshr@qualcomm.com"	
	ElseIf Err.Number = 0 Then
	Exit Sub
Else
sendmail "The share " & network & " could not be mapped", "The share " & network & " could not be mapped", "rajeshr@qualcomm.com"	
End If
End Sub

'***********************
'Delete the Mapped folder
'***********************

Sub DisconnectDrive(objNet, local)
On Error Resume Next
objNet.RemoveNetworkDrive local
End Sub



'***********************
'Sending out an email
'***********************

Sub sendmail(subj,body,recipients)
Set objEmail = CreateObject("CDO.Message")
'objEmail.From = strserver & "@qualcomm.com"
objEmail.From = "rraghavan@illumina.com"
'objEmail.To = "rajeshr@qualcomm.com"
objEmail.To = recipients
'objEmail.Subject = "Server down"
objEmail.Subject = subj
'objEmail.Textbody = "Server1 is no longer accessible over the network."
objEmail.Textbody = body
objEmail.Configuration.Fields.Item _
 ("http://schemas.microsoft.com/cdo/configuration/sendusing") = 2
objEmail.Configuration.Fields.Item _
 ("http://schemas.microsoft.com/cdo/configuration/smtpserver") = _
"smtphost.qualcomm.com"
objEmail.Configuration.Fields.Item _
 ("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = 25
objEmail.Configuration.Fields.Update
objEmail.Send
wscript.echo "Mail Sent"
End Sub