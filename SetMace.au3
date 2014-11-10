#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Comment=Advanced timestamp manipulation on NTFS
#AutoIt3Wrapper_Res_Description=Change or dump any file timestamp by using low level disk access
#AutoIt3Wrapper_Res_Fileversion=1.0.0.16
#AutoIt3Wrapper_Res_LegalCopyright=Joakim Schicht
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#AutoIt3Wrapper_Res_File_Add=C:\tmp\sectorio.sys
#AutoIt3Wrapper_Res_File_Add=C:\tmp\sectorio64.sys
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#Include <WinAPIEx.au3>
#include <Array.au3>
#Include <String.au3>
#Include <FileConstants.au3>
#Include <APIConstants.au3>
;
; https://github.com/jschicht
; http://code.google.com/p/mft2csv/
;
Global $DoSi=0				; -x, -si
Global $DoFn=0				; -x, -fn
Global $DoCTime=0			; -z, -c
Global $DoATime=0			; -z, -m
Global $DoMTime=0			; -z, -e
Global $DoRTime=0			; -z, -a
Global $DoAll4Timestamps=0	; -z
Global $DoRead=0			; -d
Global $DoShadows=0         ; -shadow
Global $NeedLock=0, $drive, $FormattedTimestamp1, $SIArrValue[13][1], $SIArrOffset[13][1], $SIArrSize[13][1], $FNArrValue[14][1], $FNArrOffset[14][1], $IsFirstRun=1, $SI_Number, $FN_Number
Global $LockedFileName,$DirArray,$NeedIndx=0, $ResidentIndx, $AttributesArr[18][4], $DoExtractMeta=False, $TargetFileName, $DATA_Name, $FN_FileName, $NameQ[5], $FN_ParentReferenceNo, $HEADER_MFTREcordNumber
Global $TargetImageFile, $Entries, $InputFile, $IsRawShadowCopy=0, $IsPhysicalDrive=False, $IsImage=False, $hDisk, $sBuffer, $ComboPhysicalDrives, $Combo, $Mode2Data, $SkipFixups=0, $LogicalClusterNumberforthefileMFT, $ClustersPerFileRecordSegment, $MftAttrListString
Global $OutPutPath=@ScriptDir, $InitState = False, $DATA_Clusters, $AttributeOutFileName, $DATA_InitSize, $ImageOffset=0, $ADS_Name, $IndexNumber, $NonResidentFlag, $DATA_RealSize, $DataRun, $DATA_LengthOfAttribute
Global $TargetDrive = "", $ALInnerCouner, $MFTSize, $TargetOffset, $SectorsPerCluster,$MFT_Record_Size,$BytesPerCluster,$BytesPerSector,$MFT_Offset,$IsDirectory, $SplitMftRecArr[1]
Global $IsolatedAttributeList, $AttribListNonResident=0,$IsCompressed,$IsSparse, $_COMMON_KERNEL32DLL=DllOpen("kernel32.dll"),$Drivername = "sectorio", $RawTestOffsetArray, $ParentMode=0, $IndxCTimeFromParentArr[1],$IndxATimeFromParentArr[1],$IndxMTimeFromParentArr[1],$IndxRTimeFromParentArr[1],$IndxFileNameFromParentArr[1],$IndxMFTReferenceFromParentArr[1],$IndxMFTReferenceOfParentFromParentArr[1]
Global $RUN_VCN[1],$RUN_Clusters[1],$MFT_RUN_Clusters[1],$MFT_RUN_VCN[1],$DataQ[1],$sBuffer,$AttrQ[1],$IndxCTimeFromParentCurrentArr,$IndxATimeFromParentCurrentArr,$IndxMTimeFromParentCurrentArr,$IndxRTimeFromParentCurrentArr,$IndxFileNameFromParentCurrentArr,$IndxMFTReferenceFromParentCurrentArr,$IndxMFTReferenceOfParentFromParentCurrentArr
Global $IndxEntryNumberArr[1],$IndxMFTReferenceArr[1],$IndxMFTRefSeqNoArr[1],$IndxMFTReferenceOfParentArr[1],$IndxMFTParentRefSeqNoArr[1],$IndxCTimeArr[1],$IndxATimeArr[1],$IndxMTimeArr[1],$IndxRTimeArr[1],$IndxFileNameArr[1]
;Global $IndxEntryNumberArr[1],$IndxMFTReferenceArr[1],$IndxMFTRefSeqNoArr[1],$IndxIndexFlagsArr[1],$IndxMFTReferenceOfParentArr[1],$IndxMFTParentRefSeqNoArr[1],$IndxCTimeArr[1],$IndxATimeArr[1],$IndxMTimeArr[1],$IndxRTimeArr[1],$IndxAllocSizeArr[1],$IndxRealSizeArr[1],$IndxFileFlagsArr[1],$IndxFileNameArr[1],$IndxSubNodeVCNArr[1],$IndxNameSpaceArr[1]
Global $IndxEntryNumberArr2[1],$IndxMFTReferenceArr2[1],$IndxFileNameArr2[1],$ShadowModifyMftArr[1],$ShadowModifyIndxArr[1],$ShadowModifyParentMftArr[1],$RawOffsetIndxArray[1]
Global $IRArr[12][2],$IndxArr[20][2],$InfoArrShadowMainTarget[3],$InfoArrShadowParent[3],$NewTimestampShifted,$IRTimestampsArray[1][4],$DummyVar=0,$IsCurrentIndxOfParent=0,$DoIndxOffsetArray=0
Global $ShadowPath = "System Volume Information\", $ShadowGuid = "{3808876b-c176-4e48-b7ae-04046e6cc752}", $GlobalShadowArray[1][8], $GlobalShadowFileCounter=0, $ShadowPathResolved, $FromHarddiskVolumeShadowCopyXArr[15][1],$INDX_Record_Size=4096
Global $DateTimeFormat = 6 ; YYYY-MM-DD HH:MM:SS:MSMSMS:NSNSNSNS = 2007-08-18 08:15:37:733:1234
Global $tDelta = _WinTime_GetUTCToLocalFileTimeDelta()
Global Const $RecordSignature = '46494C45' ; FILE signature
Global Const $RecordSignatureBad = '44414142' ; BAAD signature
Global Const $STANDARD_INFORMATION = '10000000'
Global Const $ATTRIBUTE_LIST = '20000000'
Global Const $FILE_NAME = '30000000'
Global Const $OBJECT_ID = '40000000'
Global Const $SECURITY_DESCRIPTOR = '50000000'
Global Const $VOLUME_NAME = '60000000'
Global Const $VOLUME_INFORMATION = '70000000'
Global Const $DATA = '80000000'
Global Const $INDEX_ROOT = '90000000'
Global Const $INDEX_ALLOCATION = 'A0000000'
Global Const $BITMAP = 'B0000000'
Global Const $REPARSE_POINT = 'C0000000'
Global Const $EA_INFORMATION = 'D0000000'
Global Const $EA = 'E0000000'
Global Const $PROPERTY_SET = 'F0000000'
Global Const $LOGGED_UTILITY_STREAM = '00010000'
Global Const $ATTRIBUTE_END_MARKER = 'FFFFFFFF'
Global Const $tagUNICODESTRING = "ushort Length;ushort MaximumLength;ptr Buffer"

Global $Timerstart = TimerInit()

ConsoleWrite("Starting SetMace by Joakim Schicht" & @CRLF)
ConsoleWrite("Version 1.0.0.16" & @CRLF & @CRLF)

If Not $cmdline[0] Then
	ConsoleWrite("Error: Missing parameters" & @CRLF)
	_PrintHelp()
	Exit
EndIf

$TargetDrive = StringMid($cmdline[1],1,2)
$IndexNumber = StringMid($cmdline[1],3)
If Not StringIsDigit($IndexNumber) Then $TargetFileName = $cmdline[1]

_validate_parameters()
If Not $DoRead Then
	$FormattedTimestamp = _config_timestamp()
	$FormattedTimestamp1 = StringMid($FormattedTimestamp[0],1,14) & $FormattedTimestamp[8]
EndIf

;ConsoleWrite("$TargetDrive: " & $TargetDrive & @CRLF)
_ReadBootSector($TargetDrive)
If @error Then
	ConsoleWrite("Error: Filesystem not NTFS" & @CRLF)
	Exit
EndIf

$hDisk = _WinAPI_CreateFile("\\.\" & $TargetDrive,2,2,7)
If $hDisk = 0 Then
	ConsoleWrite("CreateFile: " & _WinAPI_GetLastErrorMessage() & @CRLF)
	Exit
EndIf
$MFTEntry = _FindMFT($TargetDrive,0)
If $MFTEntry = "" Then ;something wrong with record for $MFT
	ConsoleWrite("Error: Getting MFT record 0" & @CRLF)
	Exit
EndIf

$MFT = _DecodeMFTRecord0($MFTEntry, 0)        ;produces DataQ for $MFT, record 0
If $MFT = "" Then
	ConsoleWrite("Error: Parsing the MFT record 0" & @CRLF)
	Exit
EndIf
_GetRunsFromAttributeListMFT0() ;produces datarun for $MFT and converts datarun to RUN_VCN[] and RUN_Clusters[]
_WinAPI_CloseHandle($hDisk)

$MFTSize = $DATA_RealSize
$MFT_RUN_VCN = $RUN_VCN
$MFT_RUN_Clusters = $RUN_Clusters
$IsFirstRun=0

_GenRefArray()

If Not _Prep($TargetDrive,$IndexNumber,$TargetFileName) Then
	ConsoleWrite("Error initializing structs and arrays" & @crlf)
	Exit
EndIf

If $DoRead Then
	ConsoleWrite("Start reading timestamps from disk" & @crlf)
	_DumpTimestampsToConsole()
	ConsoleWrite("Finished reading timestamps from disk" & @crlf & @crlf)
EndIf

$hDisk = _WinAPI_CreateFile("\\.\" & $TargetDrive,2,2,7)
If Not $hDisk Then
	ConsoleWrite("Error CreateFile in core script returned: " & _WinAPI_GetLastErrorMessage() & @CRLF)
	Exit
EndIf

If $DoShadows And $DoRead Then
	;Get some volume information to compare against with shadows
	$VolumeInfoTarget = _WinAPI_GetVolumeInformationByHandle($hDisk)

	;Start VSS info gathering by vssadmin+++
	$sVolumeMountPoint = StringUpper($TargetDrive) & "\"
	;ConsoleWrite("$sVolumeMountPoint: " & $sVolumeMountPoint & @CRLF)
	$Ret = DllCall('kernel32.dll', 'int', 'GetVolumeNameForVolumeMountPointW', 'wstr', $sVolumeMountPoint, 'wstr', '', 'dword', 256)
	If Not $Ret[0] Then
		ConsoleWrite("Error in GetVolumeNameForVolumeMountPoint: " & _WinAPI_GetLastErrorMessage() & @CRLF)
	EndIf
	;ConsoleWrite("GetVolumeNameForVolumeMountPoint: " & $Ret[2] & @CRLF)
	$VolumeGUIDPath = $Ret[2]

	$vssPID = run("cmd /c vssadmin list shadows /for="&$TargetDrive,"",@SW_HIDE, 0x2)
	ProcessWaitClose($vssPID)
	$sOutput = StdoutRead($vssPID)
	;ConsoleWrite($sOutput & @CRLF)
	$VssArray = StringSplit(StringTrimRight(StringStripCR($sOutput), StringLen(@CRLF)), @CRLF)
	;_ArrayDisplay($VssArray)

	Global $ShadowsArray[UBound($VssArray)/3][7]
	$ShadowsArray[0][0] = "ShadowCopySetId"
	$ShadowsArray[0][1] = "Creation Time"
	$ShadowsArray[0][2] = "ShadowCopyId"
	$ShadowsArray[0][3] = "ShadowOriginalVolume"
	$ShadowsArray[0][4] = "ShadowCopyVolume"
	$ShadowsArray[0][5] = "Originating Machine"
	$ShadowsArray[0][6] = "Servicing Machine"
	$tCounter=0

	;Note: the parsing of vssadmin output is language dependent, however that limitation does not make any difference as the result is not currently used when parsing
	For $VssLine = 1 To UBound($VssArray)-1
		If StringInStr($VssArray[$VssLine],"Contents of shadow copy set ID: {") Then
			$ShadowCopySetId = $VssArray[$VssLine]
			$ShadowCopySetId = StringMid($ShadowCopySetId,StringInStr($ShadowCopySetId,":")+2)
			If StringRight($ShadowCopySetId,1) <> "}" Or StringLeft($ShadowCopySetId,1) <> "{" Then ConsoleWrite("Error: Something went wrong with parsing the output of vssadmin.exe" & @CRLF)
			$ShadowCreationTime = $VssArray[$VssLine+1]
			$ShadowCreationTime = StringMid($ShadowCreationTime,StringInStr($ShadowCreationTime,":")+2)
		EndIf
		If StringInStr($VssArray[$VssLine],"Shadow Copy ID: {") Then
			$ShadowCopyId = $VssArray[$VssLine]
			$ShadowCopyId = StringMid($ShadowCopyId,StringInStr($ShadowCopyId,":")+2)
			If StringRight($ShadowCopyId,1) <> "}" Or StringLeft($ShadowCopyId,1) <> "{" Then ConsoleWrite("Error: Something went wrong with parsing the output of vssadmin.exe" & @CRLF)
			$ShadowOriginalVolume = $VssArray[$VssLine+1]
			$ShadowOriginalVolume = StringMid($ShadowOriginalVolume,StringInStr($ShadowOriginalVolume,"("))
			$ShadowCopyVolume = $VssArray[$VssLine+2]
			$ShadowCopyVolume = StringMid($ShadowCopyVolume,StringInStr($ShadowCopyVolume,"\\"))
			$ShadowOriginatingMachine = $VssArray[$VssLine+3]
			$ShadowOriginatingMachine = StringMid($ShadowOriginatingMachine,StringInStr($ShadowOriginatingMachine,":")+2)
			$ShadowServicingMachine = $VssArray[$VssLine+4]
			$ShadowServicingMachine = StringMid($ShadowServicingMachine,StringInStr($ShadowServicingMachine,":")+2)
			If StringInStr($ShadowOriginalVolume,$VolumeGUIDPath) Then
				$tCounter+=1
				#cs
				ConsoleWrite(@CRLF & "Shadow copy matches:" & @CRLF)
				ConsoleWrite("$ShadowCopySetId: " & $ShadowCopySetId & @CRLF)
				ConsoleWrite("$ShadowCreationTime: " & $ShadowCreationTime & @CRLF)
				ConsoleWrite("$ShadowCopyId: " & $ShadowCopyId & @CRLF)
				ConsoleWrite("$ShadowOriginalVolume: " & $ShadowOriginalVolume & @CRLF)
				ConsoleWrite("$ShadowCopyVolume: " & $ShadowCopyVolume & @CRLF)
				ConsoleWrite("$ShadowOriginatingMachine: " & $ShadowOriginatingMachine & @CRLF)
				ConsoleWrite("$ShadowServicingMachine: " & $ShadowServicingMachine & @CRLF)
				#ce
				$ShadowsArray[$tCounter][0] = $ShadowCopySetId
				$ShadowsArray[$tCounter][1] = $ShadowCreationTime
				$ShadowsArray[$tCounter][2] = $ShadowCopyId
				$ShadowsArray[$tCounter][3] = $ShadowOriginalVolume
				$ShadowsArray[$tCounter][4] = $ShadowCopyVolume
				$ShadowsArray[$tCounter][5] = $ShadowOriginatingMachine
				$ShadowsArray[$tCounter][6] = $ShadowServicingMachine
			EndIf
		EndIf
	Next
	ReDim $ShadowsArray[$tCounter+1][7]
	;_ArrayDisplay($ShadowsArray)

	$IndexNumberBak = $IndexNumber
	$TargetMatchInShadowsCounter=1

	;With dump mode, search through each and every ShadowCopy for a match
	If $DoRead Then
		$DummyVar=1
		ConsoleWrite("Start reading timestamps from symbolic links of shadow copies" & @crlf & @crlf)
		$FromHarddiskVolumeShadowCopyXArr[0][0] = "VolumeShadowCopy"
		$FromHarddiskVolumeShadowCopyXArr[1][0] = "FileName"
		$FromHarddiskVolumeShadowCopyXArr[2][0] = "IndexNumber"
		$FromHarddiskVolumeShadowCopyXArr[3][0] = "SI: CreationTime"
		$FromHarddiskVolumeShadowCopyXArr[4][0] = "SI: LastWriteTime"
		$FromHarddiskVolumeShadowCopyXArr[5][0] = "SI: ChangeTime(MFT)"
		$FromHarddiskVolumeShadowCopyXArr[6][0] = "SI: LastAccessTime"
		$FromHarddiskVolumeShadowCopyXArr[7][0] = "FN: CreationTime"
		$FromHarddiskVolumeShadowCopyXArr[8][0] = "FN: LastWriteTime"
		$FromHarddiskVolumeShadowCopyXArr[9][0] = "FN: ChangeTime(MFT)"
		$FromHarddiskVolumeShadowCopyXArr[10][0] = "FN: LastAccessTime"
		$FromHarddiskVolumeShadowCopyXArr[11][0] = "INDX: CreationTime"
		$FromHarddiskVolumeShadowCopyXArr[12][0] = "INDX: LastWriteTime"
		$FromHarddiskVolumeShadowCopyXArr[13][0] = "INDX: ChangeTime(MFT)"
		$FromHarddiskVolumeShadowCopyXArr[14][0] = "INDX: LastAccessTime"
		$k=1 ;We traverse from 1 to 50 although we strictly speaking could have grabbed the relevant shadows from $ShadowsArray and saved a couple of sec.
		$sDrivePath = '\\.\GLOBALROOT\Device\HarddiskVolumeShadowCopy'
		Do
			$hDisk = _WinAPI_CreateFile($sDrivePath & $k,2,2,2)
			If $hDisk <> 0 Then
				$HarddiskVolumeShadowCopyX = StringMid($sDrivePath,5)&$k
				$VolumeInfoShadow = _WinAPI_GetVolumeInformationByHandle($hDisk)
				_WinAPI_CloseHandle($hDisk)
				If $VolumeInfoTarget[0] = $VolumeInfoShadow[0] And $VolumeInfoTarget[1] = $VolumeInfoShadow[1] Then ;Likely a shadow of target volume
	;				Global $IndxEntryNumberArr[1],$IndxMFTReferenceArr[1],$IndxIndexFlagsArr[1],$IndxMFTReferenceOfParentArr[1],$IndxCTimeArr[1],$IndxATimeArr[1],$IndxMTimeArr[1],$IndxRTimeArr[1],$IndxAllocSizeArr[1],$IndxRealSizeArr[1],$IndxFileFlagsArr[1],$IndxFileNameArr[1],$IndxSubNodeVCNArr[1],$IndxNameSpaceArr[1]
					Global $IndxEntryNumberArr[1],$IndxMFTReferenceArr[1],$IndxMFTReferenceOfParentArr[1],$IndxCTimeArr[1],$IndxATimeArr[1],$IndxMTimeArr[1],$IndxRTimeArr[1],$IndxFileNameArr[1]
					ConsoleWrite("Found shadow: " & $sDrivePath & $k & @CRLF)
					_ReadBootSector($HarddiskVolumeShadowCopyX)
					If @error Then
						ConsoleWrite("Error: Filesystem not NTFS" & @CRLF)
						$k+=1
						Continueloop
					EndIf
					$BytesPerCluster = $SectorsPerCluster*$BytesPerSector
					$MFTEntry = _FindMFT($HarddiskVolumeShadowCopyX,0)
					$IndexNumber = $IndexNumberBak
					If _DecodeMFTRecord($HarddiskVolumeShadowCopyX,$MFTEntry,0) < 1 Then
						ConsoleWrite("Could not verify MFT record of MFT itself (volume corrupt)" & @CRLF)
						$k+=1
						Continueloop
					EndIf
					_DecodeDataQEntry($DataQ[1])
					$MFTSize = $DATA_RealSize
					Global $RUN_VCN[1], $RUN_Clusters[1]
					_ExtractDataRuns()
					$MFT_RUN_VCN = $RUN_VCN
					$MFT_RUN_Clusters = $RUN_Clusters
					;Parent of target
					$RetRec = _FindFileMFTRecord($HarddiskVolumeShadowCopyX,$InfoArrShadowParent[0])
					$NewRecord = $RetRec[1]
					If _DecodeMFTRecord($HarddiskVolumeShadowCopyX,$NewRecord,1) < 1 Then
						ConsoleWrite("Could not verify MFT record at offset: 0x" & $RetRec[0] & @CRLF)
						$k+=1
						Continueloop
					EndIf
					If $InfoArrShadowParent[0] = $HEADER_MFTREcordNumber And $InfoArrShadowParent[1] = $FN_FileName Then
	;					ConsoleWrite("Found parent of target with ref " & $HEADER_MFTREcordNumber & " and name " & $FN_FileName & " at offset: 0x" & Hex($RetRec[0])& @CRLF)
					Else
						ConsoleWrite("Error: target file not found by parent object comparison in " & $HarddiskVolumeShadowCopyX & @CRLF) ;Validation check 1
						$k+=1
						ContinueLoop
					EndIf
					If Not _PopulateIndxTimestamps($InfoArrShadowMainTarget[1],$InfoArrShadowMainTarget[0]) Then
						ConsoleWrite("Error: target file not found by INDX method in " & $HarddiskVolumeShadowCopyX & @CRLF) ;Validation check 2
						$k+=1
						ContinueLoop
					EndIf
					Redim $FromHarddiskVolumeShadowCopyXArr[15][$TargetMatchInShadowsCounter+1]

					;Target
					$RetRec = _FindFileMFTRecord($HarddiskVolumeShadowCopyX,$InfoArrShadowMainTarget[0])
					$NewRecord = $RetRec[1]
					If _DecodeMFTRecord($HarddiskVolumeShadowCopyX,$NewRecord,1) < 1 Then
						ConsoleWrite("Could not verify MFT record at offset: 0x" & $RetRec[0] & @CRLF)
						$k+=1
						Continueloop
					EndIf
					If $InfoArrShadowMainTarget[0] = $HEADER_MFTREcordNumber And $InfoArrShadowMainTarget[1] = $FN_FileName And $InfoArrShadowParent[0] = $FN_ParentReferenceNo Then
	;					ConsoleWrite("Found main target with ref " & $HEADER_MFTREcordNumber & " and name " & $FN_FileName & " at offset: 0x" & Hex($RetRec[0])& @CRLF)
					Else
						ConsoleWrite("Error: target file not found by direct $MFT method in " & $HarddiskVolumeShadowCopyX & @CRLF) ;Validation check 3
						$k+=1
						ContinueLoop
					EndIf
					_DumpTimestampsToConsole()
					_PopulateShadowTimestampsArray($TargetMatchInShadowsCounter)
					$FromHarddiskVolumeShadowCopyXArr[0][$TargetMatchInShadowsCounter] = $HarddiskVolumeShadowCopyX
					$TargetMatchInShadowsCounter+=1
				Else
	;				ConsoleWrite("Shadow of other volume: " & $sDrivePath & $k & @CRLF)
				EndIf
				$VolumeInfoShadow=''
			EndIf
			$k+=1
		Until $k = 50
		If $TargetMatchInShadowsCounter = 1 Then ConsoleWrite("No shadow copies for volume " & $TargetDrive & " contained target file" & @CRLF)
		ConsoleWrite("Finished reading symbolic links of shadow copies" & @CRLF & @CRLF)
		$DummyVar=0
;		_ArrayDisplay($FromHarddiskVolumeShadowCopyXArr,"$FromHarddiskVolumeShadowCopyXArr")
	EndIf
EndIf

If Not $DoRead Then
	;Prep timestamp before write
	$NewTimestamp = Hex($FormattedTimestamp1)
	If NOT IsInt(StringLen($NewTimestamp)/2) Then
		$NewTimestamp = '0' & $NewTimestamp
	EndIf

	$StrLn = StringLen($NewTimestamp)
	Select
		Case $StrLn = 0
			$out = '0000000000000000'
		Case $StrLn = 2
			$out = '00000000000000' & $NewTimestamp
		Case $StrLn = 4
			$out = '000000000000' & $NewTimestamp
		Case $StrLn = 6
			$out = '0000000000' & $NewTimestamp
		Case $StrLn = 8
			$out = '00000000' & $NewTimestamp
		Case $StrLn = 10
			$out = '000000' & $NewTimestamp
		Case $StrLn = 12
			$out = '0000' & $NewTimestamp
		Case $StrLn = 14
			$out = '00' & $NewTimestamp
		Case $StrLn = 16
			$out =  $NewTimestamp
	EndSelect
	$NewTimestampShifted = _ShiftEndian($out)

	;Start write
	ConsoleWrite("Start patching timestamps" & @CRLF & @CRLF)
	ConsoleWrite("Trying volume offset 0x" & Hex(Int($InfoArrShadowMainTarget[2])) & @CRLF)
	_RawModMft($InfoArrShadowMainTarget[2],$InfoArrShadowMainTarget[0])

	If $DoSi Then
		ConsoleWrite(@CRLF & "Patching resident INDX records of parent ($INDEX_ROOT)" & @CRLF)
		ConsoleWrite(@CRLF & "Trying volume offset 0x" & Hex(Int($InfoArrShadowParent[2])) & @CRLF)
		_RawModIndexRoot($TargetDrive,$InfoArrShadowParent[2],$InfoArrShadowMainTarget[0])

		;Check for current INDX of parent
		ConsoleWrite(@CRLF & "Patching non-resident INDX records of parent ($INDEX_ALLOCATION)" & @CRLF)
		If IsArray($RawOffsetIndxArray) And Ubound($RawOffsetIndxArray) > 1 Then
;			_ArrayDisplay($RawOffsetIndxArray,"$RawOffsetIndxArray")
			For $i = 1 To UBound($RawOffsetIndxArray)-1
				ConsoleWrite(@CRLF & "Trying volume offset 0x" & Hex(Int($RawOffsetIndxArray[$i][0])) & @CRLF)
				_RawModIndx($RawOffsetIndxArray[$i][0],$RawOffsetIndxArray[$i][2]/4096,$InfoArrShadowParent[0],$InfoArrShadowMainTarget[0])
			Next
		Else
			ConsoleWrite("There was no INDX records of parent to patch" & @CRLF)
		EndIf
	EndIf
EndIf

If $DoShadows Then
	;Scan shadow copies for MFT and INDX records
	ConsoleWrite(@CRLF & "Start parsing shadow copies in raw mode (modified clusters)" & @CRLF & @CRLF)
	_RawShadowParse($TargetDrive)
	ConsoleWrite(@CRLF & "Finished parsing shadow copies in raw mode (modified clusters)" & @CRLF & @CRLF)
EndIf

If $DoShadows And Not $DoRead Then
	ConsoleWrite("Start patching timestamps within shadow copies" & @CRLF & @CRLF)

	ConsoleWrite("Patching $MFT records of target" & @CRLF)
	;Write directly to MFT records within shadow copies
	If UBound($ShadowModifyMftArr) > 1 Then
		For $i = 1 To UBound($ShadowModifyMftArr)-1
			ConsoleWrite(@CRLF & "Trying volume offset 0x" & Hex(Int($ShadowModifyMftArr[$i])) & @CRLF)
			_RawModMft($ShadowModifyMftArr[$i],$InfoArrShadowMainTarget[0])
		Next
	Else
		ConsoleWrite("There was no $MFT records of target to patch" & @CRLF)
	EndIf

	;$STANDARD_INFORMATION related operations
	If $DoSi Then
		ConsoleWrite(@CRLF & "Patching resident INDX records of parent ($INDEX_ROOT)" & @CRLF)
		;Write directly to parent MFT record within shadow copies
		If UBound($ShadowModifyParentMftArr) > 1 Then
			For $i = 1 To UBound($ShadowModifyParentMftArr)-1
				ConsoleWrite(@CRLF & "Trying volume offset 0x" & Hex(Int($ShadowModifyParentMftArr[$i])) & @CRLF)
				_RawModIndexRoot($TargetDrive,$ShadowModifyParentMftArr[$i],$InfoArrShadowMainTarget[0])
			Next
		Else
			ConsoleWrite("There was no $MFT records of parent with $INDEX_ROOT attributes to patch" & @CRLF)
		EndIf

		ConsoleWrite(@CRLF & "Patching non-resident INDX records of parent ($INDEX_ALLOCATION)" & @CRLF)
		;Write directly to INDX records within shadow copies
		If UBound($ShadowModifyIndxArr) > 1 Then
			For $i = 1 To UBound($ShadowModifyIndxArr)-1
				ConsoleWrite(@CRLF & "Trying volume offset 0x" & Hex(Int($ShadowModifyIndxArr[$i])) & @CRLF)
				_RawModIndx($ShadowModifyIndxArr[$i],1,$InfoArrShadowParent[0],$InfoArrShadowMainTarget[0])
			Next
		Else
			ConsoleWrite("There was no INDX records of parent to patch" & @CRLF)
		EndIf
	EndIf
EndIf

;Close existing handle to volume
_WinAPI_CloseHandle($hDisk)

If Not $DoRead Then
;	Trick to force the cache manager to re-generate file system cache (effectively wiping the timestamps stored in memory by the system)
	$ret = DllCall('kernel32.dll', 'ptr', 'CreateFileW', 'wstr', "\\.\" & $TargetDrive, 'dword', $GENERIC_READ , 'dword', 1, 'ptr', 0, 'dword', 3, 'dword', 0x20000000, 'ptr', 0)
	$hDisk = $ret[0]
	If $hDisk Then
		_WinAPI_CloseHandle($hDisk)
	EndIf
	ConsoleWrite(@CRLF & "File system cache cleared in RAM" & @CRLF)
EndIf

_End($Timerstart)

Func _SplitPath($InPath)
	Local $Reconstruct,$FilePathSplit[3], $DirArray
;	ConsoleWrite("_SplitPath()" & @CRLF)
;	ConsoleWrite("$InPath: " & $InPath & @CRLF)
	If StringRight($InPath,1) = "\" Then $InPath = StringTrimRight($InPath,1)
	$DirArray = StringSplit($InPath,"\")
;	ConsoleWrite("$DirArray[0]: " & $DirArray[0] & @CRLF)
	If StringLen($InPath) = 2 Then
		$FilePathSplit[0] = $InPath
		$FilePathSplit[1] = ""
		$FilePathSplit[2] = ""
		Return $FilePathSplit
	EndIf
	If $DirArray[0] = 2 Then
		$FilePathSplit[0] = $DirArray[1]
		$FilePathSplit[1] = $DirArray[2]
		$FilePathSplit[2] = ""
		Return $FilePathSplit
	EndIf
	For $i = 1 To $DirArray[0]-2
;		ConsoleWrite("$DirArray[$i]: " & $DirArray[$i] & @CRLF)
		$Reconstruct &= $DirArray[$i]&"\"
	Next
	$Reconstruct = StringTrimRight($Reconstruct,1)
	$FilePathSplit[0] = $Reconstruct
	$FilePathSplit[1] = $DirArray[Ubound($DirArray)-2]
	$FilePathSplit[2] = $DirArray[Ubound($DirArray)-1]
	Return $FilePathSplit
EndFunc

Func _GenDirArray($InPath)
	Local $Reconstruct
;	ConsoleWrite("_GenDirArray()" & @CRLF)
;	ConsoleWrite("$InPath: " & $InPath & @CRLF)
	Global $DirArray = StringSplit($InPath,"\")
	$LockedFileName = $DirArray[$DirArray[0]]
	For $i = 1 To $DirArray[0]-1
		$Reconstruct &= $DirArray[$i]&"\"
	Next
	$Reconstruct = StringTrimRight($Reconstruct,1)
	Return $Reconstruct
EndFunc

Func _RawResolveRef($TargetDevice,$ParentPath, $FileName, $ReParseNtfs)
	Local $ParentDir,$NextRef,$ResolvedPath,$RetRec[2],$NewRecord,$ResolvedRef;,$StartStr,$TargetDriveLocal
	Local $ResolvedRef=0 ;We don't use this function for resolving $MFT itself anyway
;	ConsoleWrite("$ParentPath: " & $ParentPath & @CRLF)
;	ConsoleWrite("$FileName: " & $FileName & @CRLF)
	If StringLen($ParentPath)=2 Then $ParentPath&="\"
	$ParentDir = _GenDirArray($ParentPath)
;	ConsoleWrite("$ParentDir: " & $ParentDir & @CRLF)
	Global $MftRefArray[$DirArray[0]+1]

	If $ReParseNtfs Then
		_ReadBootSector($TargetDevice)
		If @error Then
			ConsoleWrite("Error: Filesystem not NTFS" & @CRLF)
			Exit
		EndIf

		$hDisk = _WinAPI_CreateFile("\\.\" & $TargetDevice,2,2,7)
		If $hDisk = 0 Then
			ConsoleWrite("CreateFile: " & _WinAPI_GetLastErrorMessage() & @CRLF)
			Exit
		EndIf
		$MFTEntry = _FindMFT($TargetDevice,0)
		If $MFTEntry = "" Then ;something wrong with record for $MFT
			ConsoleWrite("Error: Getting MFT record 0" & @CRLF)
			Exit
		EndIf
		$MFT = _DecodeMFTRecord0($MFTEntry, 0)        ;produces DataQ for $MFT, record 0
		If $MFT = "" Then
			ConsoleWrite("Error: Parsing the MFT record 0" & @CRLF)
			Exit
		EndIf
		_GetRunsFromAttributeListMFT0() ;produces datarun for $MFT and converts datarun to RUN_VCN[] and RUN_Clusters[]
		_WinAPI_CloseHandle($hDisk)
		$MFTSize = $DATA_RealSize
		$MFT_RUN_VCN = $RUN_VCN
		$MFT_RUN_Clusters = $RUN_Clusters
		_GenRefArray()
	EndIf
	$NextRef = 5
	$MftRefArray[1]=$NextRef
	$ResolvedPath = $DirArray[1]
	For $i = 2 To $DirArray[0]
		Global $DataQ[1]
		$RetRec = _FindFileMFTRecord($TargetDevice,$NextRef)
		If Not IsArray($RetRec) Then Return SetError(1,0,0)
		$NewRecord = $RetRec[1]
		If _DecodeMFTRecord($TargetDevice,$NewRecord,1) < 1 Then
			ConsoleWrite("Could not verify MFT record at offset: 0x" & $RetRec[0] & @CRLF)
			Return 0
		EndIf
		$NextRef = _ParseIndex($DirArray[$i])
		$MftRefArray[$i]=$NextRef
		If @error Then
			Global $DataQ[1]
			$RetRec = _FindFileMFTRecord($TargetDevice,$MftRefArray[$i-1])
			If Not IsArray($RetRec) Then Return SetError(1,0,0)
			$NewRecord = $RetRec[1]
			If _DecodeMFTRecord($TargetDevice,$NewRecord,1) < 1 Then
				ConsoleWrite("Could not verify MFT record at offset: 0x" & $RetRec[0] & @CRLF)
				Return 0
			EndIf
			$ResolvedRef = _GetMftRefFromIndex($FileName)
		ElseIf $i=$DirArray[0] Then
			Global $DataQ[1]
			$RetRec = _FindFileMFTRecord($TargetDevice,$MftRefArray[$i])
			If Not IsArray($RetRec) Then Return SetError(1,0,0)
			$NewRecord = $RetRec[1]
			If _DecodeMFTRecord($TargetDevice,$NewRecord,1) < 1 Then
				ConsoleWrite("Could not verify MFT record at offset: 0x" & $RetRec[0] & @CRLF)
				Return 0
			EndIf
			$ResolvedRef = _GetMftRefFromIndex($FileName)
			If @error Then ; In case last part was a file and not a directory
				Global $DataQ[1]
				$RetRec = _FindFileMFTRecord($TargetDevice,$MftRefArray[$i-1])
				If Not IsArray($RetRec) Then Return SetError(1,0,0)
				$NewRecord = $RetRec[1]
				If _DecodeMFTRecord($TargetDevice,$NewRecord,1) < 1 Then
					ConsoleWrite("Could not verify MFT record at offset: 0x" & $RetRec[0] & @CRLF)
					Return 0
				EndIf
				$ResolvedRef = _GetMftRefFromIndex($FileName)
			EndIf
		ElseIf StringIsDigit($NextRef) Then
			$ResolvedPath &= "\" & $DirArray[$i]
			ContinueLoop
		Else
			ConsoleWrite("Error: Something went wrong" & @CRLF)
			ExitLoop
		EndIf
	Next
;	If StringRight($ParentPath,1) = "\" Then $ParentPath = StringTrimRight($ParentPath,1)
;	If $FileName <> "$MFT" And $ResolvedRef <> 0 Then ConsoleWrite("MFT Ref of " & $ParentPath & "\" & $FileName & ": " & $ResolvedRef & @CRLF)
	Return $ResolvedRef
EndFunc

Func _RawShadowParse($TargetDevice)
	Local $tBuffer,$nBytes,$hVol,$VolDataTmp,$ShadowDataTmp

	$GlobalShadowArray[0][0] = "FileRef"
	$GlobalShadowArray[0][1] = "FileName"
	$GlobalShadowArray[0][2] = "CreationTime"
	$GlobalShadowArray[0][3] = "StoreHeaderOffset"
	$GlobalShadowArray[0][4] = "BlockListOffset"
	$GlobalShadowArray[0][5] = "StoreBlockRangeListOffset"
	$GlobalShadowArray[0][6] = "ShadowCopyIdGuid"
	$GlobalShadowArray[0][7] = "ShadowCopySetIdGuid"

	;Resolve the MFT ref of the Shadow copy master file
	$ShadowPathResolved = $TargetDevice & "\" & $ShadowPath
	$ShadowMasterRef = _RawResolveRef($TargetDevice,$ShadowPathResolved, $ShadowGuid, 1)
	If $ShadowMasterRef Then
;		ConsoleWrite("$ShadowMasterRef: " & $ShadowMasterRef & @CRLF)
	Else
		ConsoleWrite("Error resolving: " & $ShadowPathResolved & $ShadowGuid & " (no shadow copy found)" & @CRLF)
		Return 0
	EndIf
	;Find the MFT record and decode it

	$NewRecord = _FindFileMFTRecord($TargetDevice,$ShadowMasterRef)
	If _DecodeMFTRecord($TargetDevice,$NewRecord[1],2) < 1 Then
		ConsoleWrite("Could not verify MFT record at offset: 0x" & $NewRecord[0] & @CRLF)
		Return 0
	EndIf

	;Read the shadow information from the volume offset 0x1e00
	$hVol = _WinAPI_CreateFile("\\.\" & $TargetDevice,2,6,6)
	If $hVol = 0 Then
		ConsoleWrite("CreateFile in function _RawShadowParse(): " & _WinAPI_GetLastErrorMessage() & @CRLF)
		Return 0
	EndIf
	_WinAPI_SetFilePointerEx($hVol, 0x1e00, $FILE_BEGIN)
	$tBuffer = DllStructCreate("byte[512]")
	If Not _WinAPI_ReadFile($hVol, DllStructGetPtr($tBuffer), DllStructGetSize($tBuffer), $nBytes) Then
		ConsoleWrite("Error in ReadFile: " & _WinAPI_GetLastErrorMessage() & @CRLF)
		Return 0
	EndIf
	$VolDataTmp = DllStructGetData($tBuffer,1)
	;_WinAPI_CloseHandle($hVol)

;	ConsoleWrite("Volume VSS data decode of: " & $TargetDevice & @CRLF)
;	ConsoleWrite(_HexEncode($VolDataTmp) & @CRLF)
;	_DecodeVolumeVssData($VolDataTmp)

	;Decode the VSS master file
	_DecodeShadowMasterFileData($TargetDevice,$Mode2Data)
;	_ArrayDisplay($GlobalShadowArray,"$GlobalShadowArray")

	For $i = 1 To Ubound($GlobalShadowArray)-1
		ConsoleWrite("Scanning Shadow Copy with filename: " & $GlobalShadowArray[$i][1] & @CRLF)
		$SkipFixups=0
		$IsRawShadowCopy=0 ;The file itself is not a shadow copy, only its content :)
		$NewRecord = _FindFileMFTRecord($TargetDevice,$GlobalShadowArray[$i][0])
		_DecodeMFTRecord($TargetDevice,$NewRecord[1],3) ;Mode=3 will populate $RawTestOffsetArray
		$TestOffset = $RawTestOffsetArray[1][0]
		$BlockSize = 16384
		;$SkipFixups=1 ;For MFT records found within shadow copies, fixups are already applied.
		$IsRawShadowCopy=1 ;The MFT records we process from here are from within a shadow copy
		$ParentMode=0
;		_ArrayDisplay($RawTestOffsetArray,"$RawTestOffsetArray")
		For $j = 1 To UBound($RawTestOffsetArray)-1
			$TestOffset = Int($RawTestOffsetArray[$j][0])
			$BytesProcessed = 0
;			ConsoleWrite("Loop per run: " & $j & @CRLF)
			Do
;				ConsoleWrite("Loop within run for each 0x4000 bytes: " & @CRLF)
				;ConsoleWrite("$BytesProcessed: " & $BytesProcessed & @CRLF)
				_WinAPI_SetFilePointerEx($hVol, $TestOffset, $FILE_BEGIN)
				$tBuffer = DllStructCreate("byte[512]")
				If Not _WinAPI_ReadFile($hVol, DllStructGetPtr($tBuffer), 512, $nBytes) Then
					ConsoleWrite("Error in ReadFile: " & _WinAPI_GetLastErrorMessage() & @CRLF)
					Return 0
				EndIf
				$ShadowDataTmp = DllStructGetData($tBuffer,1)
				$tBuffer=0
				$First4Bytes = StringMid($ShadowDataTmp,3,8)
				If $First4Bytes = '46494C45' Then ;FILE
					_WinAPI_SetFilePointerEx($hVol, $TestOffset, $FILE_BEGIN)
					$tBuffer = DllStructCreate("byte["&$MFT_Record_Size&"]")
					If Not _WinAPI_ReadFile($hVol, DllStructGetPtr($tBuffer), DllStructGetSize($tBuffer), $nBytes) Then
						ConsoleWrite("Error in ReadFile: " & _WinAPI_GetLastErrorMessage() & @CRLF)
						Return 0
					EndIf
					$ShadowDataTmp = DllStructGetData($tBuffer,1)
					$tBuffer=0
					$HEADER_MFTREcordNumber = StringMid($ShadowDataTmp, 91, 8)
					$HEADER_MFTREcordNumber = Dec(_SwapEndian($HEADER_MFTREcordNumber),2)
					_DecodeMFTRecord($TargetDevice,$ShadowDataTmp,1)
;					ConsoleWrite("MFT record " & $HEADER_MFTREcordNumber & " with name " & $FN_FileName & " found at offset: 0x" & Hex($TestOffset) & @crlf)
					;If $InfoArrShadowMainTarget[0] = $HEADER_MFTREcordNumber And $InfoArrShadowMainTarget[1] = $FN_FileName Then
					If $InfoArrShadowMainTarget[0] = $HEADER_MFTREcordNumber And $InfoArrShadowMainTarget[1] = $FN_FileName And $InfoArrShadowParent[0] = $FN_ParentReferenceNo Then
;						ConsoleWrite("Found main target with ref " & $HEADER_MFTREcordNumber & " and name " & $FN_FileName & " at offset: 0x" & Hex($TestOffset)& @CRLF)
						If $DoRead Then _DumpTimestampsToConsole()
						ReDim $ShadowModifyMftArr[Ubound($ShadowModifyMftArr)+1]
						$ShadowModifyMftArr[Ubound($ShadowModifyMftArr)-1] = $TestOffset
					EndIf
					If $InfoArrShadowParent[0] = $HEADER_MFTREcordNumber And $InfoArrShadowParent[1] = $FN_FileName Then
;						ConsoleWrite("Found parent of target with ref " & $HEADER_MFTREcordNumber & " and name " & $FN_FileName & " at offset: 0x" & Hex($TestOffset)& @CRLF)
						ReDim $ShadowModifyParentMftArr[Ubound($ShadowModifyParentMftArr)+1]
						$ShadowModifyParentMftArr[Ubound($ShadowModifyParentMftArr)-1] = $TestOffset
					EndIf
					$BytesProcessed2=$MFT_Record_Size
					$TestOffset2 = Int($TestOffset) + Int($MFT_Record_Size)
					Do
						;ConsoleWrite("Loop inner most " & @CRLF)
						_WinAPI_SetFilePointerEx($hVol, $TestOffset2, $FILE_BEGIN)
						$tBuffer = DllStructCreate("byte["&$MFT_Record_Size&"]")
						If Not _WinAPI_ReadFile($hVol, DllStructGetPtr($tBuffer), DllStructGetSize($tBuffer), $nBytes) Then
							ConsoleWrite("Error in ReadFile: " & _WinAPI_GetLastErrorMessage() & @CRLF)
							Return 0
						EndIf
						$ShadowDataTmp = DllStructGetData($tBuffer,1)
						$First4Bytes = StringMid($ShadowDataTmp,3,8)
						If $First4Bytes = '46494C45' Then ;FILE
							$HEADER_MFTREcordNumber = StringMid($ShadowDataTmp, 91, 8)
							$HEADER_MFTREcordNumber = Dec(_SwapEndian($HEADER_MFTREcordNumber),2)
							_DecodeMFTRecord($TargetDevice,$ShadowDataTmp,1)
;							ConsoleWrite("MFT record " & $HEADER_MFTREcordNumber & " with name " & $FN_FileName & " found at offset: 0x" & Hex($TestOffset2) & @crlf)
							;If $InfoArrShadowMainTarget[0] = $HEADER_MFTREcordNumber And $InfoArrShadowMainTarget[1] = $FN_FileName Then
							If $InfoArrShadowMainTarget[0] = $HEADER_MFTREcordNumber And $InfoArrShadowMainTarget[1] = $FN_FileName And $InfoArrShadowParent[0] = $FN_ParentReferenceNo Then
;								ConsoleWrite("Found main target with ref " & $HEADER_MFTREcordNumber & " and name " & $FN_FileName & " at offset: 0x" & Hex($TestOffset2)& @CRLF)
								If $DoRead Then _DumpTimestampsToConsole()
								ReDim $ShadowModifyMftArr[Ubound($ShadowModifyMftArr)+1]
								$ShadowModifyMftArr[Ubound($ShadowModifyMftArr)-1] = $TestOffset2
							EndIf
							If $InfoArrShadowParent[0] = $HEADER_MFTREcordNumber And $InfoArrShadowParent[1] = $FN_FileName Then
;								ConsoleWrite("Found parent of target with ref " & $HEADER_MFTREcordNumber & " and name " & $FN_FileName & " at offset: 0x" & Hex($TestOffset2)& @CRLF)
								ReDim $ShadowModifyParentMftArr[Ubound($ShadowModifyParentMftArr)+1]
								$ShadowModifyParentMftArr[Ubound($ShadowModifyParentMftArr)-1] = $TestOffset2
							EndIf
							$TestOffset2+=$MFT_Record_Size
							$BytesProcessed2+=$MFT_Record_Size
						ElseIf $First4Bytes = '494e4458' Then ;INDX
							$ShadowDataTmp=""
							_WinAPI_SetFilePointerEx($hVol, $TestOffset2, $FILE_BEGIN)
							$tBuffer = DllStructCreate("byte["&$INDX_Record_Size&"]")
							If Not _WinAPI_ReadFile($hVol, DllStructGetPtr($tBuffer), DllStructGetSize($tBuffer), $nBytes) Then
								ConsoleWrite("Error in ReadFile: " & _WinAPI_GetLastErrorMessage() & @CRLF)
								Return 0
							EndIf
							$ShadowDataTmp = DllStructGetData($tBuffer,1)
;							ConsoleWrite("Found INDX at offset: 0x" & Hex($TestOffset2)& @CRLF)
							$FixedIndxRecord = _StripIndxRecord(StringTrimLeft($ShadowDataTmp,2))
							If _DecodeIndxEntriesExpress($FixedIndxRecord) Then
;								ConsoleWrite("INDX success at offset: 0x" & Hex($TestOffset2)& @CRLF)
								ReDim $ShadowModifyIndxArr[Ubound($ShadowModifyIndxArr)+1]
								$ShadowModifyIndxArr[Ubound($ShadowModifyIndxArr)-1] = $TestOffset2
							EndIf
							;$IndxEntryNumberArr2[1],$IndxMFTReferenceArr2[1],$IndxFileNameArr2[1]
							$TestOffset2+=$INDX_Record_Size
							$BytesProcessed2+=$INDX_Record_Size
						Else
							$TestOffset2+=$MFT_Record_Size
							$BytesProcessed2+=$MFT_Record_Size
						EndIf
						$ShadowDataTmp=""
						$tBuffer=0
;						$TestOffset2+=$MFT_Record_Size
;						$BytesProcessed2+=$MFT_Record_Size
					Until $BytesProcessed2 >= $BlockSize
				ElseIf $First4Bytes = '494e4458' Then ;INDX
;					#cs
;					ConsoleWrite("Found INDX at offset: 0x" & Hex($TestOffset)& @CRLF)
					_WinAPI_SetFilePointerEx($hVol, $TestOffset, $FILE_BEGIN)
					$tBuffer = DllStructCreate("byte["&$INDX_Record_Size&"]")
					If Not _WinAPI_ReadFile($hVol, DllStructGetPtr($tBuffer), DllStructGetSize($tBuffer), $nBytes) Then
						ConsoleWrite("Error in ReadFile: " & _WinAPI_GetLastErrorMessage() & @CRLF)
						Return 0
					EndIf
					$ShadowDataTmp = DllStructGetData($tBuffer,1)
					$tBuffer=0
					$FixedIndxRecord = _StripIndxRecord(StringTrimLeft($ShadowDataTmp,2))
					If _DecodeIndxEntriesExpress($FixedIndxRecord) Then
;						ConsoleWrite("INDX success at offset: 0x" & Hex($TestOffset)& @CRLF)
						ReDim $ShadowModifyIndxArr[Ubound($ShadowModifyIndxArr)+1]
						$ShadowModifyIndxArr[Ubound($ShadowModifyIndxArr)-1] = $TestOffset
					EndIf
					$BytesProcessed2=$INDX_Record_Size
					$TestOffset2 = Int($TestOffset) + Int($INDX_Record_Size)
					Do
						_WinAPI_SetFilePointerEx($hVol, $TestOffset2, $FILE_BEGIN)
						$tBuffer = DllStructCreate("byte["&$INDX_Record_Size&"]")
						If Not _WinAPI_ReadFile($hVol, DllStructGetPtr($tBuffer), DllStructGetSize($tBuffer), $nBytes) Then
							ConsoleWrite("Error in ReadFile: " & _WinAPI_GetLastErrorMessage() & @CRLF)
							Return 0
						EndIf
						$ShadowDataTmp = DllStructGetData($tBuffer,1)
						$First4Bytes = StringMid($ShadowDataTmp,3,8)
;--------------------------------Should never occur..?
						If $First4Bytes = '46494C45' Then ;FILE
							$HEADER_MFTREcordNumber = StringMid($ShadowDataTmp, 91, 8)
							$HEADER_MFTREcordNumber = Dec(_SwapEndian($HEADER_MFTREcordNumber),2)
							_DecodeMFTRecord($TargetDevice,$ShadowDataTmp,1)
							;ConsoleWrite("MFT record " & $HEADER_MFTREcordNumber & " with name " & $FN_FileName & " found at offset: 0x" & Hex($TestOffset2) & @crlf)
							;If $InfoArrShadowMainTarget[0] = $HEADER_MFTREcordNumber And $InfoArrShadowMainTarget[1] = $FN_FileName Then
							If $InfoArrShadowMainTarget[0] = $HEADER_MFTREcordNumber And $InfoArrShadowMainTarget[1] = $FN_FileName And $InfoArrShadowParent[0] = $FN_ParentReferenceNo Then
;								ConsoleWrite("Found main target with ref " & $HEADER_MFTREcordNumber & " and name " & $FN_FileName & " at offset: 0x" & Hex($TestOffset2)& @CRLF)
								If $DoRead Then _DumpTimestampsToConsole()
								ReDim $ShadowModifyMftArr[Ubound($ShadowModifyMftArr)+1]
								$ShadowModifyMftArr[Ubound($ShadowModifyMftArr)-1] = $TestOffset2
							EndIf
							If $InfoArrShadowParent[0] = $HEADER_MFTREcordNumber And $InfoArrShadowParent[1] = $FN_FileName Then
;								ConsoleWrite("Found parent of target with ref " & $HEADER_MFTREcordNumber & " and name " & $FN_FileName & " at offset: 0x" & Hex($TestOffset2)& @CRLF)
								ReDim $ShadowModifyParentMftArr[Ubound($ShadowModifyParentMftArr)+1]
								$ShadowModifyParentMftArr[Ubound($ShadowModifyParentMftArr)-1] = $TestOffset2
							EndIf
;							MsgBox(0,"Warning","Unexpected data in shadow copy.")
						ElseIf $First4Bytes = '494e4458' Then ;INDX
;							ConsoleWrite("Found INDX at offset: 0x" & Hex($TestOffset)& @CRLF)
							$FixedIndxRecord = _StripIndxRecord(StringTrimLeft($ShadowDataTmp,2))
							If _DecodeIndxEntriesExpress($FixedIndxRecord) Then
;								ConsoleWrite("INDX success at offset: 0x" & Hex($TestOffset2)& @CRLF)
								ReDim $ShadowModifyIndxArr[Ubound($ShadowModifyIndxArr)+1]
								$ShadowModifyIndxArr[Ubound($ShadowModifyIndxArr)-1] = $TestOffset2
							EndIf
						EndIf
						$tBuffer=0
						$TestOffset2+=$INDX_Record_Size
						$BytesProcessed2+=$INDX_Record_Size
					Until $BytesProcessed2 >= $BlockSize
				EndIf
				$TestOffset+=$BlockSize
				$BytesProcessed+=$BlockSize
			Until $BytesProcessed >= $RawTestOffsetArray[$j][2]
		Next
	Next
	_WinAPI_CloseHandle($hVol)
	Return 1
EndFunc

Func _DecodeVolumeVssData($InputData)
	Local $VssGuid,$CatalogEntryType,$vssRecordType,$vssCurrentOffset,$vssUnknownNextOffset,$vssUnknown1,$vssCatalogOffset,$vssMaxSize,$vssVolumeIdGuid,$vssVolumeIdGuidMod,$vssVolumeIdGuidMod2,$vssShadowStorageIdGuid,$vssShadowStorageIdGuidMod,$vssShadowStorageIdGuidMod2
	If StringLeft($InputData,2) = "0x" Then $InputData = StringTrimLeft($InputData,2)
	ConsoleWrite(@CRLF & "Decode of Volume VSS data" & @CRLF)
	$VssGuid = StringMid($InputData,1,32)
	If Not $VssGuid = "6b87083876c1484eb7ae04046e6cc752" Then
		ConsoleWrite("Error the header Guid is not as expected: " & $VssGuid& @CRLF)
		Return 0
	EndIf

	$vssVersion = StringMid($InputData,33,8)
	$vssVersion = Dec(_SwapEndian($vssVersion))
	$vssRecordType = StringMid($InputData,41,8)
	$vssRecordType = Dec(_SwapEndian($vssRecordType))
	$vssCurrentOffset = StringMid($InputData,49,16)
	$vssCurrentOffset = _SwapEndian($vssCurrentOffset)
	$vssUnknownNextOffset = StringMid($InputData,65,16)
	$vssUnknownNextOffset = _SwapEndian($vssUnknownNextOffset)
	$vssUnknown1 = StringMid($InputData,81,16)
	$vssUnknown1 = _SwapEndian($vssUnknown1)
	$vssCatalogOffset = StringMid($InputData,97,16)
	$vssCatalogOffset = _SwapEndian($vssCatalogOffset)
	$vssMaxSize = StringMid($InputData,113,16)
	$vssMaxSize = _SwapEndian($vssMaxSize)
	$vssVolumeIdGuid = StringMid($InputData,129,32)
	;$vssVolumeIdGuid = _SwapEndian($vssVolumeIdGuid)
	$vssVolumeIdGuidMod = _SwapEndian(StringMid($vssVolumeIdGuid,1,8)) & _SwapEndian(StringMid($vssVolumeIdGuid,9,4)) & _SwapEndian(StringMid($vssVolumeIdGuid,13,4)) & StringMid($vssVolumeIdGuid,17,4) & StringMid($vssVolumeIdGuid,21,12)
	$vssVolumeIdGuidMod2 = "{" & _SwapEndian(StringMid($vssVolumeIdGuid,1,8)) & "-" & _SwapEndian(StringMid($vssVolumeIdGuid,9,4)) & "-" & _SwapEndian(StringMid($vssVolumeIdGuid,13,4)) & "-" & StringMid($vssVolumeIdGuid,17,4) & "-" & StringMid($vssVolumeIdGuid,21,12) & "}"
	$vssShadowStorageIdGuid = StringMid($InputData,161,32)
	;$vssShadowStorageIdGuid = _SwapEndian($vssShadowStorageIdGuid)
	$vssShadowStorageIdGuidMod = _SwapEndian(StringMid($vssShadowStorageIdGuid,1,8)) & _SwapEndian(StringMid($vssShadowStorageIdGuid,9,4)) & _SwapEndian(StringMid($vssShadowStorageIdGuid,13,4)) & StringMid($vssShadowStorageIdGuid,17,4) & StringMid($vssShadowStorageIdGuid,21,12)
	$vssShadowStorageIdGuidMod2 = "{" & _SwapEndian(StringMid($vssShadowStorageIdGuid,1,8)) & "-" & _SwapEndian(StringMid($vssShadowStorageIdGuid,9,4)) & "-" & _SwapEndian(StringMid($vssShadowStorageIdGuid,13,4)) & "-" & StringMid($vssShadowStorageIdGuid,17,4) & "-" & StringMid($vssShadowStorageIdGuid,21,12) & "}"
	;$vssUnknown2 = StringMid($InputData,195,8)
	;$vssUnknown2 = _SwapEndian($vssUnknown2)
	;$vssUnknown3 = StringMid($InputData,203,824)
	;$vssUnknown3 = _SwapEndian($vssUnknown3)
	ConsoleWrite("$vssVersion: " & $vssVersion & @CRLF)
	ConsoleWrite("$vssRecordType: " & $vssRecordType & @CRLF)
	ConsoleWrite("$vssCurrentOffset: " & $vssCurrentOffset & @CRLF)
	ConsoleWrite("$vssUnknownNextOffset: " & $vssUnknownNextOffset & @CRLF)
	ConsoleWrite("$vssUnknown1: " & $vssUnknown1 & @CRLF)
	ConsoleWrite("$vssCatalogOffset: " & $vssCatalogOffset & @CRLF)
	ConsoleWrite("$vssMaxSize: " & $vssMaxSize & @CRLF)
;	ConsoleWrite("$vssVolumeIdGuid: " & $vssVolumeIdGuid & @CRLF)
;	ConsoleWrite("$vssVolumeIdGuidMod: " & $vssVolumeIdGuidMod & @CRLF)
	ConsoleWrite("$vssVolumeIdGuidMod2: " & $vssVolumeIdGuidMod2 & @CRLF)
;	ConsoleWrite("$vssShadowStorageIdGuid: " & $vssShadowStorageIdGuid & @CRLF)
;	ConsoleWrite("$vssShadowStorageIdGuidMod: " & $vssShadowStorageIdGuidMod & @CRLF)
	ConsoleWrite("$vssShadowStorageIdGuidMod2: " & $vssShadowStorageIdGuidMod2 & @CRLF)
	Return 1
EndFunc

Func _DecodeShadowMasterFileData($TargetDevice,$InputDataFull)
	Local $VssGuid,$vssVersion,$vssRecordType,$vssOffset1,$vssOffset2,$vssOffset3,$CatalogEntryType,$CatalogEntry
	;Catalog block header
;	ConsoleWrite("Decode of Shadow Master File" & @CRLF)
	$StartPos=1
	$DataSize = BinaryLen($InputDataFull)
;	ConsoleWrite("$DataSize: " & $DataSize & @CRLF)
	For $i = 1 To $DataSize/16384
		$InputData = StringMid($InputDataFull,$StartPos,32768)
;		ConsoleWrite(_HexEncode("0x"&StringMid($InputData,1,1024)) & @CRLF)
;		ConsoleWrite(@CRLF & "Decode of Catalog block header " & $i & @CRLF)
		$VssGuid = StringMid($InputData,1,32)
		If Not $VssGuid = "6b87083876c1484eb7ae04046e6cc752" Then
;			ConsoleWrite("Error the header Guid is not as expected: " & $VssGuid & @CRLF)
			Return 0
		EndIf
;		ConsoleWrite("Header GUID OK" & @CRLF)
		$vssVersion = StringMid($InputData,33,8)
		$vssVersion = Dec(_SwapEndian($vssVersion))
		$vssRecordType = StringMid($InputData,41,8)
		$vssRecordType = Dec(_SwapEndian($vssRecordType))
		$vssOffset1 = StringMid($InputData,49,16)
		$vssOffset1 = _SwapEndian($vssOffset1)
		$vssOffset2 = StringMid($InputData,65,16)
		$vssOffset2 = _SwapEndian($vssOffset2)
		$vssOffset3 = StringMid($InputData,81,16)
		$vssOffset3 = _SwapEndian($vssOffset3)
		;$vssUnknown1 = StringMid($InputData,97,160) ;Irrelevant
;		ConsoleWrite("$vssVersion: " & $vssVersion & @CRLF)
;		ConsoleWrite("$vssRecordType: " & $vssRecordType & @CRLF)
;		ConsoleWrite("$vssOffset1: " & $vssOffset1 & @CRLF)
;		ConsoleWrite("$vssOffset2: " & $vssOffset2 & @CRLF)
;		ConsoleWrite("$vssOffset3: " & $vssOffset3 & @CRLF)
		$sCounter = 1
		Do
			$sCounter += 256
			;Catalog entry
			$CatalogEntryType = StringMid($InputData,$sCounter,16)
			$CatalogEntryType = Dec(_SwapEndian($CatalogEntryType))
;			ConsoleWrite("$CatalogEntryType: " & $CatalogEntryType & @CRLF)

			;Put this into a loop
			$CatalogEntry = StringMid($InputData,$sCounter,256)
			Select
				Case $CatalogEntryType = 1
					_DecodeCatalogEntryType1($CatalogEntry)
				Case $CatalogEntryType = 2
					_DecodeCatalogEntryType2($CatalogEntry)
				Case $CatalogEntryType = 3
					_DecodeCatalogEntryType3($TargetDevice,$CatalogEntry)
			EndSelect
		Until $CatalogEntryType <> 2 And $CatalogEntryType <> 3
		$StartPos+=32768
	Next
	Return 1
EndFunc

Func _DecodeCatalogEntryType1($InputData)
	ConsoleWrite("Catalog type 1 (not in use ?)" & @CRLF)
	Return 0
EndFunc

Func _DecodeCatalogEntryType2($InputData)
	Local $CECatalogEntryType,$CEVolumeSize,$CEGuidFilename,$CEGuidFilenameMod,$CEGuidFilenameMod2,$CESequenceNumber,$CEFlags,$CEShadowTimestamp,$CEShadowTimestamp_tmp,$ActualShadowFileName,$ActualShadowFileNameRef
	$CECatalogEntryType = StringMid($InputData,1,16)
	$CECatalogEntryType = Dec(_SwapEndian($CECatalogEntryType))
;	ConsoleWrite(@CRLF & "Decode of Catalog type 2" & @CRLF)
	If Not $CECatalogEntryType = 2 Then
		ConsoleWrite("Error: Received wrong catalog type: " & $CECatalogEntryType & @CRLF)
		Return 0
	EndIf
;	ConsoleWrite(_HexEncode("0x"&$InputData) & @CRLF)
	$CEVolumeSize = StringMid($InputData,17,16)
	$CEVolumeSize = _SwapEndian($CEVolumeSize)
	$CEGuidFilename = StringMid($InputData,33,32)
	$CEGuidFilenameMod = _SwapEndian(StringMid($CEGuidFilename,1,8)) & _SwapEndian(StringMid($CEGuidFilename,9,4)) & _SwapEndian(StringMid($CEGuidFilename,13,4)) & StringMid($CEGuidFilename,17,4) & StringMid($CEGuidFilename,21,12)
	$CEGuidFilenameMod2 = "{" & _SwapEndian(StringMid($CEGuidFilename,1,8)) & "-" & _SwapEndian(StringMid($CEGuidFilename,9,4)) & "-" & _SwapEndian(StringMid($CEGuidFilename,13,4)) & "-" & StringMid($CEGuidFilename,17,4) & "-" & StringMid($CEGuidFilename,21,12) & "}"
	$CESequenceNumber = StringMid($InputData,65,16)
	$CESequenceNumber = _SwapEndian($CESequenceNumber)
	$CEFlags = StringMid($InputData,81,16)
	$CEFlags = _SwapEndian($CEFlags)
	$CEShadowTimestamp = StringMid($InputData,97,16)
	$CEShadowTimestamp = _SwapEndian($CEShadowTimestamp)
	$CEShadowTimestamp_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $CEShadowTimestamp)
	$CEShadowTimestamp = _WinTime_UTCFileTimeFormat(Dec($CEShadowTimestamp)-$tDelta,$DateTimeFormat,2)
	$CEShadowTimestamp = $CEShadowTimestamp & ":" & _FillZero(StringRight($CEShadowTimestamp_tmp,4))
	;$CEUnknown1 = StringMid($InputData,115,144) ;Irrelevant
	$ActualShadowFileName = $CEGuidFilenameMod2&$ShadowGuid
;	ConsoleWrite("$CEVolumeSize: 0x" & $CEVolumeSize & @CRLF)
;	ConsoleWrite("$CEGuidFilenameMod2: " & $CEGuidFilenameMod2 & @CRLF)
;	ConsoleWrite("$CESequenceNumber: " & $CESequenceNumber & @CRLF)
;	ConsoleWrite("$CEFlags: " & $CEFlags & @CRLF)
;	ConsoleWrite("$CEShadowTimestamp: " & $CEShadowTimestamp & @CRLF)
;	ConsoleWrite("$ActualShadowFileName: " & $ActualShadowFileName & @CRLF)
	$ActualShadowFileNameRef = _RawResolveRef($TargetDrive,$ShadowPathResolved, $ActualShadowFileName, 1)
	;$ActualShadowFileNameRef = _RawResolveRef($TargetDrive,$ShadowPathResolved, $ShadowGuid)
	#cs
	;--------------------Check deactivated because in some rare cases there will be an actual mismatch here. Bug from Microsoft side??
	If $ActualShadowFileNameRef Then
		;ConsoleWrite("$ActualShadowFileNameRef: " & $ActualShadowFileNameRef & @CRLF)
		$GlobalShadowFileCounter+=1
		Redim $GlobalShadowArray[Ubound($GlobalShadowArray)+1][8]
		$GlobalShadowArray[$GlobalShadowFileCounter][0] = $ActualShadowFileNameRef
		$GlobalShadowArray[$GlobalShadowFileCounter][1] = $ActualShadowFileName
		$GlobalShadowArray[$GlobalShadowFileCounter][2] = $CEShadowTimestamp
		Return 1
	Else
		ConsoleWrite("Error resolving: " & $ShadowPathResolved & $ActualShadowFileName & @CRLF)
		Return 0
	EndIf
	#ce
	$GlobalShadowFileCounter+=1
	Redim $GlobalShadowArray[Ubound($GlobalShadowArray)+1][8]
	$GlobalShadowArray[$GlobalShadowFileCounter][0] = $ActualShadowFileNameRef
	$GlobalShadowArray[$GlobalShadowFileCounter][1] = $ActualShadowFileName
	$GlobalShadowArray[$GlobalShadowFileCounter][2] = $CEShadowTimestamp
	Return 1
EndFunc

Func _DecodeCatalogEntryType3($TargetDevice,$InputData)
	Local $CECatalogEntryType,$CEBlockListOffset,$CEStoreIdGuid,$CEStoreIdGuidMod2,$CEStoreHeaderOffset,$CEStoreBlockRangeListOffset,$CEStoreCurrentBitampOffset,$CENtfsMetaDataFileReference,$CENtfsMetaDataFileReferenceSeqNo
	Local $CEAllocatedSize,$CEStorePreviousBitmapOffset,$CEUnknownIndex,$CEUnknown1,$nBytes
	$CECatalogEntryType = StringMid($InputData,1,16)
	$CECatalogEntryType = Dec(_SwapEndian($CECatalogEntryType))
;	ConsoleWrite(@CRLF & "Decode of Catalog type 3" & @CRLF)
	If Not $CECatalogEntryType = 3 Then
		ConsoleWrite("Error: Received wrong catalog type: " & $CECatalogEntryType & @CRLF)
		Return 0
	EndIf
;	ConsoleWrite(_HexEncode("0x"&$InputData) & @CRLF)
	$CEBlockListOffset = StringMid($InputData,17,16)
	$CEBlockListOffset = _SwapEndian($CEBlockListOffset)
	$CEStoreIdGuid = StringMid($InputData,33,32)
	$CEStoreIdGuidMod2 = "{" & _SwapEndian(StringMid($CEStoreIdGuid,1,8)) & "-" & _SwapEndian(StringMid($CEStoreIdGuid,9,4)) & "-" & _SwapEndian(StringMid($CEStoreIdGuid,13,4)) & "-" & StringMid($CEStoreIdGuid,17,4) & "-" & StringMid($CEStoreIdGuid,21,12) & "}"
	$CEStoreHeaderOffset = StringMid($InputData,65,16)
	$CEStoreHeaderOffset = _SwapEndian($CEStoreHeaderOffset)
	$CEStoreBlockRangeListOffset = StringMid($InputData,81,16)
	$CEStoreBlockRangeListOffset = _SwapEndian($CEStoreBlockRangeListOffset)
	$CEStoreCurrentBitampOffset = StringMid($InputData,97,16)
	$CEStoreCurrentBitampOffset = _SwapEndian($CEStoreCurrentBitampOffset)
	$CENtfsMetaDataFileReference = StringMid($InputData,113,12)
	$CENtfsMetaDataFileReference = Dec(_SwapEndian($CENtfsMetaDataFileReference))
	$CENtfsMetaDataFileReferenceSeqNo = StringMid($InputData,126,4)
	$CENtfsMetaDataFileReferenceSeqNo = Dec(_SwapEndian($CENtfsMetaDataFileReferenceSeqNo))
	$CEAllocatedSize = StringMid($InputData,129,16)
	$CEAllocatedSize = _SwapEndian($CEAllocatedSize)
	$CEStorePreviousBitmapOffset = StringMid($InputData,145,16)
	$CEStorePreviousBitmapOffset = _SwapEndian($CEStorePreviousBitmapOffset)
	$CEUnknownIndex = StringMid($InputData,161,16)
	$CEUnknownIndex = _SwapEndian($CEUnknownIndex)
;	$CEUnknown1 = StringMid($InputData,177,80)
;	ConsoleWrite("$CEBlockListOffset: " & $CEBlockListOffset & @CRLF)
;	ConsoleWrite("$CEStoreIdGuid: " & $CEStoreIdGuid & @CRLF)
;	ConsoleWrite("$CEStoreIdGuidMod2: " & $CEStoreIdGuidMod2 & @CRLF)
;	ConsoleWrite("$CEStoreHeaderOffset: " & $CEStoreHeaderOffset & @CRLF)
;	ConsoleWrite("$CEStoreBlockRangeListOffset: " & $CEStoreBlockRangeListOffset & @CRLF)
;	ConsoleWrite("$CEStoreCurrentBitampOffset: " & $CEStoreCurrentBitampOffset & @CRLF)
;	ConsoleWrite("$CENtfsMetaDataFileReference: " & $CENtfsMetaDataFileReference & @CRLF)
;	ConsoleWrite("$CENtfsMetaDataFileReferenceSeqNo: " & $CENtfsMetaDataFileReferenceSeqNo & @CRLF)
;	ConsoleWrite("$CEAllocatedSize: " & $CEAllocatedSize & @CRLF)
;	ConsoleWrite("$CEStorePreviousBitmapOffset: " & $CEStorePreviousBitmapOffset & @CRLF)
;	ConsoleWrite("$CEUnknownIndex: " & $CEUnknownIndex & @CRLF)
;	ConsoleWrite("$GlobalShadowArray[$GlobalShadowFileCounter][0]: " & $GlobalShadowArray[$GlobalShadowFileCounter][0] & @CRLF)
	$GlobalShadowArray[$GlobalShadowFileCounter][3] = $CEStoreHeaderOffset
	$GlobalShadowArray[$GlobalShadowFileCounter][4] = $CEBlockListOffset
	$GlobalShadowArray[$GlobalShadowFileCounter][5] = $CEStoreBlockRangeListOffset
	$GlobalShadowArray[$GlobalShadowFileCounter][0] = $CENtfsMetaDataFileReference
;	If $CENtfsMetaDataFileReference <> $GlobalShadowArray[$GlobalShadowFileCounter][0] Then
;		ConsoleWrite("Error: The MFT ref of the shadow copy file has mismatching information in header" & @CRLF)
;		Return 0
;	EndIf

;	ConsoleWrite("Dumping and parsing header of shadow copy file" & @CRLF)
	Local $hVol = _WinAPI_CreateFile("\\.\" & $TargetDevice,2,6,6)
	If $hVol = 0 Then
		ConsoleWrite("Error in CreateFile in function _DecodeCatalogEntryType3(): " & _WinAPI_GetLastErrorMessage() & @CRLF)
		Return 0
	EndIf
	_WinAPI_SetFilePointerEx($hVol, Dec($CEStoreHeaderOffset), $FILE_BEGIN)
	Local $tBuffer = DllStructCreate("byte[512]")
	If Not _WinAPI_ReadFile($hVol, DllStructGetPtr($tBuffer), DllStructGetSize($tBuffer), $nBytes) Then
		ConsoleWrite("Error in ReadFile: " & _WinAPI_GetLastErrorMessage() & @CRLF)
		Return 0
	EndIf
	Local $ShadowDataTmp = DllStructGetData($tBuffer,1)
	$tBuffer=0
	_WinAPI_CloseHandle($hVol)
;	ConsoleWrite(_HexEncode(StringMid($ShadowDataTmp,1,514)) & @CRLF)
	If Not _DecodeBlockHeader($ShadowDataTmp) Then Return 0
	$ShadowDataTmp=""
	Return 1
EndFunc

Func _DecodeBlockHeader($InputData)
	Local $VssBhGuid,$VssBhVersion,$VssBhRecordType,$VssBhOffset1,$VssBhOffset2,$VssBhOffset3,$VssBhSizeOfStoreInformation
	;Store block header
	If StringLeft($InputData,2) = "0x" Then $InputData = StringTrimLeft($InputData,2)
;	ConsoleWrite(@CRLF & "Decode of Store block header" & @CRLF)
	$VssBhGuid = StringMid($InputData,1,32)
	If Not $VssBhGuid = "6b87083876c1484eb7ae04046e6cc752" Then
;		ConsoleWrite("Error the header Guid is not as expected: " & $VssBhGuid & @CRLF)
		Return 0
	EndIf
;	ConsoleWrite("Header GUID OK" & @CRLF)
	$VssBhVersion = StringMid($InputData,33,8)
	$VssBhVersion = Dec(_SwapEndian($VssBhVersion))
	$VssBhRecordType = StringMid($InputData,41,8)
	$VssBhRecordType = _SwapEndian($VssBhRecordType)
	$VssBhRecordType = _VssStoreBlockRecordTypesFlags(Dec($VssBhRecordType))
	$VssBhOffset1 = StringMid($InputData,49,16)
	$VssBhOffset1 = _SwapEndian($VssBhOffset1)
	$VssBhOffset2 = StringMid($InputData,65,16)
	$VssBhOffset2 = _SwapEndian($VssBhOffset2)
	$VssBhOffset3 = StringMid($InputData,81,16)
	$VssBhOffset3 = _SwapEndian($VssBhOffset3)
	$VssBhSizeOfStoreInformation = StringMid($InputData,97,16)
	$VssBhSizeOfStoreInformation = _SwapEndian($VssBhSizeOfStoreInformation)
	;$VssBhUnknown1 = StringMid($InputData,113,144) ;Irrelevant
;	ConsoleWrite("$VssBhVersion: " & $VssBhVersion & @CRLF)
;	ConsoleWrite("$VssBhRecordType: " & $VssBhRecordType & @CRLF)
;	ConsoleWrite("$VssBhOffset1: " & $VssBhOffset1 & @CRLF)
;	ConsoleWrite("$VssBhOffset2: " & $VssBhOffset2 & @CRLF)
;	ConsoleWrite("$VssBhOffset3: " & $VssBhOffset3 & @CRLF)
;	ConsoleWrite("$VssBhSizeOfStoreInformation: " & $VssBhSizeOfStoreInformation & @CRLF)
	_DecodeStoreInformation(StringMid($InputData,257))
	Return 1
EndFunc

Func _DecodeStoreInformation($InputData)
	Local $VssSiGuidUnknown,$VssSiGuidUnknownMod,$VssSiShadowCopyIdGuid,$VssSiShadowCopyIdGuidMod,$VssSiShadowCopySetIdGuid,$VssSiShadowCopySetIdGuidMod,$VssSiType,$VssSiProvider,$VssSiAttributeFlags,$VssSiUnknown,$VssSiOperatingMachineStringSize
	Local $VssSiOperatingMachineString,$VssSiServiceMachineStringSize,$VssSiServiceMachineString,$VssSiAttributeFlagsDecode
	;Store block header
	If StringLeft($InputData,2) = "0x" Then $InputData = StringTrimLeft($InputData,2)
;	ConsoleWrite(@CRLF & "Decode of Store Information" & @CRLF)
	$VssSiGuidUnknown = StringMid($InputData,1,32)
	$VssSiGuidUnknownMod = "{" & _SwapEndian(StringMid($VssSiGuidUnknown,1,8)) & "-" & _SwapEndian(StringMid($VssSiGuidUnknown,9,4)) & "-" & _SwapEndian(StringMid($VssSiGuidUnknown,13,4)) & "-" & StringMid($VssSiGuidUnknown,17,4) & "-" & StringMid($VssSiGuidUnknown,21,12) & "}"

	$VssSiShadowCopyIdGuid = StringMid($InputData,33,32)
	$VssSiShadowCopyIdGuidMod = "{" & _SwapEndian(StringMid($VssSiShadowCopyIdGuid,1,8)) & "-" & _SwapEndian(StringMid($VssSiShadowCopyIdGuid,9,4)) & "-" & _SwapEndian(StringMid($VssSiShadowCopyIdGuid,13,4)) & "-" & StringMid($VssSiShadowCopyIdGuid,17,4) & "-" & StringMid($VssSiShadowCopyIdGuid,21,12) & "}"

	$VssSiShadowCopySetIdGuid = StringMid($InputData,65,32)
	$VssSiShadowCopySetIdGuidMod = "{" & _SwapEndian(StringMid($VssSiShadowCopySetIdGuid,1,8)) & "-" & _SwapEndian(StringMid($VssSiShadowCopySetIdGuid,9,4)) & "-" & _SwapEndian(StringMid($VssSiShadowCopySetIdGuid,13,4)) & "-" & StringMid($VssSiShadowCopySetIdGuid,17,4) & "-" & StringMid($VssSiShadowCopySetIdGuid,21,12) & "}"

	$VssSiType = StringMid($InputData,97,8)
	$VssSiType = _SwapEndian($VssSiType)
	$VssSiType = _VssStoreTypes(Dec($VssSiType))

	$VssSiProvider = StringMid($InputData,105,8)
	$VssSiProvider = _SwapEndian($VssSiProvider)

	$VssSiAttributeFlags = StringMid($InputData,113,8)
	$VssSiAttributeFlags = _SwapEndian($VssSiAttributeFlags)
	$VssSiAttributeFlagsDecode = _VssStoreAttributeFlags("0x"&$VssSiAttributeFlags)

	$VssSiUnknown = StringMid($InputData,121,8)

	$VssSiOperatingMachineStringSize = StringMid($InputData,129,4)
	$VssSiOperatingMachineStringSize = Dec(_SwapEndian($VssSiOperatingMachineStringSize))

	$VssSiOperatingMachineString = StringMid($InputData,133,$VssSiOperatingMachineStringSize*2)
	$VssSiOperatingMachineString = _UnicodeHexToStr($VssSiOperatingMachineString)

	$VssSiServiceMachineStringSize = StringMid($InputData,133+($VssSiOperatingMachineStringSize*2),4)
	$VssSiServiceMachineStringSize = Dec(_SwapEndian($VssSiServiceMachineStringSize))

	$VssSiServiceMachineString = StringMid($InputData,133+($VssSiOperatingMachineStringSize*2)+4,$VssSiServiceMachineStringSize*2)
	$VssSiServiceMachineString = _UnicodeHexToStr($VssSiServiceMachineString)

	;$VssBhUnknown1 = StringMid($InputData,113,144) ;Irrelevant
;	ConsoleWrite("$VssSiGuidUnknownMod: " & $VssSiGuidUnknownMod & @CRLF)
;	ConsoleWrite("$VssSiShadowCopyIdGuidMod: " & $VssSiShadowCopyIdGuidMod & @CRLF)
;	ConsoleWrite("$VssSiShadowCopySetIdGuidMod: " & $VssSiShadowCopySetIdGuidMod & @CRLF)

;	ConsoleWrite("$VssSiType: " & $VssSiType & @CRLF)
;	ConsoleWrite("$VssSiProvider: " & $VssSiProvider & @CRLF)
;	ConsoleWrite("$VssSiAttributeFlags: " & $VssSiAttributeFlags & @CRLF)
;	ConsoleWrite("$VssSiAttributeFlagsDecode: " & $VssSiAttributeFlagsDecode & @CRLF)
;	ConsoleWrite("$VssSiUnknown: " & $VssSiUnknown & @CRLF)
;	ConsoleWrite("$VssSiOperatingMachineString: " & $VssSiOperatingMachineString & @CRLF)
;	ConsoleWrite("$VssSiServiceMachineString: " & $VssSiServiceMachineString & @CRLF)
	$GlobalShadowArray[$GlobalShadowFileCounter][6] = $VssSiShadowCopyIdGuidMod
	$GlobalShadowArray[$GlobalShadowFileCounter][7] = $VssSiShadowCopySetIdGuidMod
	Return 1
EndFunc

Func _DecodeBlockDescriptor($InputData)
	ConsoleWrite("Not implemenetd" & @CRLF)
	Return 0
EndFunc

Func _VssStoreTypes($VssStoreTypeInput)
	Select
		Case $VssStoreTypeInput = 0x00000009
			Return "ApplicationRollback"
		Case $VssStoreTypeInput = 0x0000000d
			Return "ClientAccessibleWriters"
	EndSelect
	Return "Unresolved"
EndFunc

Func _VssStoreBlockRecordTypesFlags($VssFlagInput)
	Select
		Case $VssFlagInput = 0x0000
			Return "Unknown"
		Case $VssFlagInput = 0x0001
			Return "Volume header"
		Case $VssFlagInput = 0x0002
			Return "Catalog block header"
		Case $VssFlagInput = 0x0003
			Return "Block descriptor list(Diff area table)"
		Case $VssFlagInput = 0x0004
			Return "Store header"
		Case $VssFlagInput = 0x0005
			Return "Store block ranges list"
		Case $VssFlagInput = 0x0006
			Return "Store bitmap"
	EndSelect
	Return "Unresolved"
EndFunc

Func _VssStoreAttributeFlags($VssFlagInput)
	Local $VssFlagOut = ""
	;VSS_VOLSNAP_ATTR_+
	If BitAND($VssFlagInput, 0x0001) Then $VssFlagOut &= 'PERSISTENT+'
	If BitAND($VssFlagInput, 0x0002) Then $VssFlagOut &= 'NO_AUTORECOVERY+'
	If BitAND($VssFlagInput, 0x0004) Then $VssFlagOut &= 'CLIENT_ACCESSIBLE+'
	If BitAND($VssFlagInput, 0x0008) Then $VssFlagOut &= 'NO_AUTO_RELEASE+'
	If BitAND($VssFlagInput, 0x0010) Then $VssFlagOut &= 'NO_WRITERS+'
	If BitAND($VssFlagInput, 0x0020) Then $VssFlagOut &= 'TRANSPORTABLE+'
	If BitAND($VssFlagInput, 0x0040) Then $VssFlagOut &= 'NOT_SURFACED+'
	If BitAND($VssFlagInput, 0x0080) Then $VssFlagOut &= 'NOT_TRANSACTED+'
	If BitAND($VssFlagInput, 0x010000) Then $VssFlagOut &= 'HARDWARE_ASSISTED+'
	If BitAND($VssFlagInput, 0x020000) Then $VssFlagOut &= 'DIFFERENTIAL+'
	If BitAND($VssFlagInput, 0x040000) Then $VssFlagOut &= 'PLEX+'
	If BitAND($VssFlagInput, 0x080000) Then $VssFlagOut &= 'IMPORTED+'
	If BitAND($VssFlagInput, 0x100000) Then $VssFlagOut &= 'EXPOSED_LOCALLY+'
	If BitAND($VssFlagInput, 0x200000) Then $VssFlagOut &= 'EXPOSED_REMOTELY+'
	If BitAND($VssFlagInput, 0x400000) Then $VssFlagOut &= 'AUTORECOVER+'
	If BitAND($VssFlagInput, 0x800000) Then $VssFlagOut &= 'ROLLBACK_RECOVERY+'
	If BitAND($VssFlagInput, 0x1000000) Then $VssFlagOut &= 'DELAYED_POSTSNAPSHOT+'
	If BitAND($VssFlagInput, 0x2000000) Then $VssFlagOut &= 'TXF_RECOVERY+'
	$VssFlagOut = StringTrimRight($VssFlagOut, 1)
	Return $VssFlagOut
EndFunc
#cs
Func _VssStoreAttributeFlags($VssFlagInput)
	Local $VssFlagOut = ""
	If BitAND($VssFlagInput, 0x0001) Then $VssFlagOut &= 'VSS_VOLSNAP_ATTR_PERSISTENT+'
	If BitAND($VssFlagInput, 0x0002) Then $VssFlagOut &= 'VSS_VOLSNAP_ATTR_NO_AUTORECOVERY+'
	If BitAND($VssFlagInput, 0x0004) Then $VssFlagOut &= 'VSS_VOLSNAP_ATTR_CLIENT_ACCESSIBLE+'
	If BitAND($VssFlagInput, 0x0008) Then $VssFlagOut &= 'VSS_VOLSNAP_ATTR_NO_AUTO_RELEASE+'
	If BitAND($VssFlagInput, 0x0010) Then $VssFlagOut &= 'VSS_VOLSNAP_ATTR_NO_WRITERS+'
	If BitAND($VssFlagInput, 0x0020) Then $VssFlagOut &= 'VSS_VOLSNAP_ATTR_TRANSPORTABLE+'
	If BitAND($VssFlagInput, 0x0040) Then $VssFlagOut &= 'VSS_VOLSNAP_ATTR_NOT_SURFACED+'
	If BitAND($VssFlagInput, 0x0080) Then $VssFlagOut &= 'VSS_VOLSNAP_ATTR_NOT_TRANSACTED+'
	If BitAND($VssFlagInput, 0x010000) Then $VssFlagOut &= 'VSS_VOLSNAP_ATTR_HARDWARE_ASSISTED+'
	If BitAND($VssFlagInput, 0x020000) Then $VssFlagOut &= 'VSS_VOLSNAP_ATTR_DIFFERENTIAL+'
	If BitAND($VssFlagInput, 0x040000) Then $VssFlagOut &= 'VSS_VOLSNAP_ATTR_PLEX+'
	If BitAND($VssFlagInput, 0x080000) Then $VssFlagOut &= 'VSS_VOLSNAP_ATTR_IMPORTED+'
	If BitAND($VssFlagInput, 0x100000) Then $VssFlagOut &= 'VSS_VOLSNAP_ATTR_EXPOSED_LOCALLY+'
	If BitAND($VssFlagInput, 0x200000) Then $VssFlagOut &= 'VSS_VOLSNAP_ATTR_EXPOSED_REMOTELY+'
	If BitAND($VssFlagInput, 0x400000) Then $VssFlagOut &= 'VSS_VOLSNAP_ATTR_AUTORECOVER+'
	If BitAND($VssFlagInput, 0x800000) Then $VssFlagOut &= 'VSS_VOLSNAP_ATTR_ROLLBACK_RECOVERY+'
	If BitAND($VssFlagInput, 0x1000000) Then $VssFlagOut &= 'VSS_VOLSNAP_ATTR_DELAYED_POSTSNAPSHOT+'
	If BitAND($VssFlagInput, 0x2000000) Then $VssFlagOut &= 'VSS_VOLSNAP_ATTR_TXF_RECOVERY+'
	$VssFlagOut = StringTrimRight($VssFlagOut, 1)
	Return $VssFlagOut
EndFunc
#ce

Func _Prep($TargetDevice,$IndexNumber,$TargetFileName)
	Local $RetRec[2],$PathTmp,$NewRecord,$TmpOffsetTarget

	If StringIsDigit($IndexNumber) Then ;Target specified by IndexNumber
		Global $DataQ[1]
		;Target
		$RetRec = _FindFileMFTRecord($TargetDevice,$IndexNumber)
		If Not IsArray($RetRec) Then Return SetError(1,0,0)
		$TmpOffsetTarget = $RetRec[0]
		$NewRecord = $RetRec[1]
		If _DecodeMFTRecord($TargetDevice,$NewRecord,1) < 1 Then
			ConsoleWrite("Could not verify MFT record at offset: 0x" & Hex($TmpOffsetTarget) & @CRLF)
			Return 0
		EndIf
		_DecodeNameQ($NameQ)
		$InfoArrShadowMainTarget[0] = $HEADER_MFTREcordNumber
		$InfoArrShadowMainTarget[1] = $FN_FileName
		$InfoArrShadowMainTarget[2] = $TmpOffsetTarget
		$InfoArrShadowParent[0] = $FN_ParentReferenceNo
		;If StringInStr($SIArrValue[8][1],"directory") Then
		If StringInStr($FNArrValue[9][1],"directory") Then
			$IsDirectory = 1
		Else
			$IsDirectory = 0
		EndIf

		If $HEADER_MFTREcordNumber = $FN_ParentReferenceNo = 5 Then
			$ParentMode=0
		Else
			$ParentMode=1
		EndIf
		;Parent of target
		$RetRec = _FindFileMFTRecord($TargetDevice,$FN_ParentReferenceNo)
		If Not IsArray($RetRec) Then Return SetError(1,0,0)
		$TmpOffsetTarget = $RetRec[0]
		$NewRecord = $RetRec[1]
		$DoIndxOffsetArray=1
		If _DecodeMFTRecord($TargetDevice,$NewRecord,1) < 1 Then
			ConsoleWrite("Could not verify MFT record at offset: 0x" & Hex($TmpOffsetTarget) & @CRLF)
			Return 0
		EndIf
		$DoIndxOffsetArray=0
		$IsCurrentIndxOfParent=0
		If $InfoArrShadowParent[0] <> $HEADER_MFTREcordNumber Then
			ConsoleWrite("Error: Validating ref of target record" & @CRLF)
			Return 0
		EndIf
		$InfoArrShadowParent[1] = $FN_FileName
		$InfoArrShadowParent[2] = $TmpOffsetTarget

		If Not _PopulateIndxTimestamps($InfoArrShadowMainTarget[1],$InfoArrShadowMainTarget[0]) Then
			ConsoleWrite("Error: Retrieving INDX timestamps failed" & @CRLF)
			Return 0
		EndIf
		;Redo Target
		$ParentMode=0
		$IsDirectory = 0
		$RetRec = _FindFileMFTRecord($TargetDevice,$InfoArrShadowMainTarget[0])
		If Not IsArray($RetRec) Then Return SetError(1,0,0)
		$TmpOffsetTarget = $RetRec[0]
		$NewRecord = $RetRec[1]
		If _DecodeMFTRecord($TargetDevice,$NewRecord,1) < 1 Then
			ConsoleWrite("Could not verify MFT record at offset: 0x" & Hex($TmpOffsetTarget) & @CRLF)
			Return 0
		EndIf
	Else

		;Target specified by full path
		$PathTmp = _SplitPath($TargetFileName)
		If @error Then
			ConsoleWrite("Error in _SplitPath() resolving path to: " & $TargetFileName & @CRLF)
			Return 0
		EndIf

		Select
			Case $PathTmp[2] = "" And $PathTmp[1] = "" ;Root directory
	;			ConsoleWrite("Case 1" & @CRLF)
				;Target
				$RetRec = _FindFileMFTRecord($TargetDevice,5)
				If Not IsArray($RetRec) Then Return SetError(1,0,0)
				$TmpOffsetTarget = $RetRec[0]
				$NewRecord = $RetRec[1]
				If _DecodeMFTRecord($TargetDevice,$NewRecord,1) < 1 Then
					ConsoleWrite("Could not verify MFT record at offset: 0x" & Hex($RetRec[0]) & @CRLF)
					Return 0
				EndIf
				If 5 <> $HEADER_MFTREcordNumber Then
					ConsoleWrite("Error: Validating ref of target record" & @CRLF)
					Return 0
				EndIf
				If StringInStr($FNArrValue[9][1],"directory") Then
					$IsDirectory = 1
				Else
					$IsDirectory = 0
				EndIf
				$InfoArrShadowMainTarget[0] = $HEADER_MFTREcordNumber
				$InfoArrShadowMainTarget[1] = $FN_FileName
				$InfoArrShadowMainTarget[2] = $TmpOffsetTarget
				$InfoArrShadowParent[0] = ""
				$ParentMode=0
			Case $PathTmp[2] = "" And $PathTmp[1] <> "" ;1 level down from root
	;			ConsoleWrite("Case 2" & @CRLF)
				;Parent of target
				$RetRec = _FindFileMFTRecord($TargetDevice,5)
				If Not IsArray($RetRec) Then Return SetError(1,0,0)
				$TmpOffsetTarget = $RetRec[0]
				$NewRecord = $RetRec[1]
				$DoIndxOffsetArray=1
				If _DecodeMFTRecord($TargetDevice,$NewRecord,1) < 1 Then
					ConsoleWrite("Could not verify MFT record at offset: 0x" & Hex($RetRec[0]) & @CRLF)
					Return 0
				EndIf
				$DoIndxOffsetArray=0
				$IsCurrentIndxOfParent=0
				If 5 <> $HEADER_MFTREcordNumber Then
					ConsoleWrite("Error: Validating ref of target record" & @CRLF)
					Return 0
				EndIf
				$InfoArrShadowParent[0] = $HEADER_MFTREcordNumber
				$InfoArrShadowParent[1] = $FN_FileName
				$InfoArrShadowParent[2] = $TmpOffsetTarget
	;			ConsoleWrite("$InfoArrShadowParent[0]: " & $InfoArrShadowParent[0] & @CRLF)
	;			ConsoleWrite("$InfoArrShadowParent[1]: " & $InfoArrShadowParent[1] & @CRLF)
	;			ConsoleWrite("$InfoArrShadowParent[2]: " & $InfoArrShadowParent[2] & @CRLF)
				;Target
				$TmpRef = _RawResolveRef($TargetDevice,$PathTmp[0], $PathTmp[1], 0)
				If $TmpRef Then
	;				ConsoleWrite("$TmpRef: " & $TmpRef & @CRLF)
				Else
					ConsoleWrite("Error resolving: " & $PathTmp[0] & "\" & $PathTmp[1] & @CRLF)
					Return 0
				EndIf
				$RetRec = _FindFileMFTRecord($TargetDevice,$TmpRef)
				If Not IsArray($RetRec) Then Return SetError(1,0,0)
				$TmpOffsetTarget = $RetRec[0]
				$NewRecord = $RetRec[1]
				If Not _PopulateIndxTimestamps($PathTmp[1],$TmpRef) Then
					ConsoleWrite("Error: Retrieving INDX timestamps failed" & @CRLF)
					Return 0
				EndIf
				If _DecodeMFTRecord($TargetDevice,$NewRecord,1) < 1 Then
					ConsoleWrite("Could not verify MFT record at offset: 0x" & Hex($RetRec[0]) & @CRLF)
					Return 0
				EndIf
				If $TmpRef <> $HEADER_MFTREcordNumber And 5 <> $FN_ParentReferenceNo Then
					ConsoleWrite("Error: Validating refs of target record" & @CRLF)
					Return 0
				EndIf
				If StringInStr($FNArrValue[9][1],"directory") Then
					$IsDirectory = 1
				Else
					$IsDirectory = 0
				EndIf
				$InfoArrShadowMainTarget[0] = $HEADER_MFTREcordNumber
				$InfoArrShadowMainTarget[1] = $FN_FileName
				$InfoArrShadowMainTarget[2] = $TmpOffsetTarget
	;			ConsoleWrite("$InfoArrShadowMainTarget[0]: " & $InfoArrShadowMainTarget[0] & @CRLF)
	;			ConsoleWrite("$InfoArrShadowMainTarget[1]: " & $InfoArrShadowMainTarget[1] & @CRLF)
	;			ConsoleWrite("$InfoArrShadowMainTarget[2]: " & $InfoArrShadowMainTarget[2] & @CRLF)
				$ParentMode=1
			Case $PathTmp[2] <> "" And $PathTmp[1] <> "" ;Anything from 2 or more levels down from root
	;			ConsoleWrite("Case 3" & @CRLF)
				;Parent of target
				$TmpRef = _RawResolveRef($TargetDevice,$PathTmp[0], $PathTmp[1], 0)
				If $TmpRef Then
	;				ConsoleWrite("$TmpRef: " & $TmpRef & @CRLF)
				Else
					ConsoleWrite("Error resolving: " & $PathTmp[0] & "\" & $PathTmp[1] & @CRLF)
					Return 0
				EndIf
				$RetRec = _FindFileMFTRecord($TargetDevice,$TmpRef)
				If Not IsArray($RetRec) Then Return SetError(1,0,0)
				$TmpOffsetTarget = $RetRec[0]
				$NewRecord = $RetRec[1]
				$DoIndxOffsetArray=1
				If _DecodeMFTRecord($TargetDevice,$NewRecord,1) < 1 Then
					ConsoleWrite("Could not verify MFT record at offset: 0x" & Hex($RetRec[0]) & @CRLF)
					Return 0
				EndIf
				$DoIndxOffsetArray=0
				$IsCurrentIndxOfParent=0
				If $TmpRef <> $HEADER_MFTREcordNumber Then
					ConsoleWrite("Error: Validating ref of target record" & @CRLF)
					return 0
				EndIf
				$InfoArrShadowParent[0] = $HEADER_MFTREcordNumber
				$InfoArrShadowParent[1] = $FN_FileName
				$InfoArrShadowParent[2] = $TmpOffsetTarget
				;Target
				$TmpRef = _RawResolveRef($TargetDevice,$PathTmp[0] & "\" & $PathTmp[1], $PathTmp[2], 0)
				If $TmpRef Then
	;				ConsoleWrite("$TmpRef: " & $TmpRef & @CRLF)
				Else
					ConsoleWrite("Error resolving: " & $PathTmp[0] & "\" & $PathTmp[1] & "\" & $PathTmp[2] & @CRLF)
					Return 0
				EndIf
				$RetRec = _FindFileMFTRecord($TargetDevice,$TmpRef)
				If Not IsArray($RetRec) Then Return SetError(1,0,0)
				$TmpOffsetTarget = $RetRec[0]
				$NewRecord = $RetRec[1]
				If Not _PopulateIndxTimestamps($PathTmp[2],$TmpRef) Then
					ConsoleWrite("Error: Retrieving INDX timestamps failed" & @CRLF)
					Return 0
				EndIf
				If _DecodeMFTRecord($TargetDevice,$NewRecord,1) < 1 Then
					ConsoleWrite("Could not verify MFT record at offset: 0x" & Hex($RetRec[0]) & @CRLF)
					Return 0
				EndIf
				If $TmpRef <> $HEADER_MFTREcordNumber And 5 <> $FN_ParentReferenceNo Then
					ConsoleWrite("Error: Validating refs of target record" & @CRLF)
					Return 0
				EndIf
				;If StringInStr($SIArrValue[8][1],"directory") Then
				If StringInStr($FNArrValue[9][1],"directory") Then
					$IsDirectory = 1
				Else
					$IsDirectory = 0
				EndIf
				$InfoArrShadowMainTarget[0] = $HEADER_MFTREcordNumber
				$InfoArrShadowMainTarget[1] = $FN_FileName
				$InfoArrShadowMainTarget[2] = $TmpOffsetTarget
				$ParentMode=1
		EndSelect
	EndIf
	ConsoleWrite("Target filename: " & $InfoArrShadowMainTarget[1] & @CRLF)
	ConsoleWrite("Target fileref: " & $InfoArrShadowMainTarget[0] & @CRLF)
	ConsoleWrite("Target MFT record offset: 0x" & Hex($InfoArrShadowMainTarget[2]) & @CRLF)
	ConsoleWrite("Parent filename: " & $InfoArrShadowParent[1] & @CRLF)
	ConsoleWrite("Parent fileref: " & $InfoArrShadowParent[0] & @CRLF)
	ConsoleWrite("Parent MFT record offset: 0x" & Hex($InfoArrShadowParent[2]) & @CRLF & @CRLF)
	Global $IndxFileNameFromParentCurrentArr = $IndxFileNameFromParentArr
	Global $IndxMFTReferenceFromParentCurrentArr = $IndxMFTReferenceFromParentArr
	Global $IndxMFTReferenceOfParentFromParentCurrentArr = $IndxMFTReferenceOfParentFromParentArr
	Global $IndxCTimeFromParentCurrentArr = $IndxCTimeFromParentArr
	Global $IndxATimeFromParentCurrentArr = $IndxATimeFromParentArr
	Global $IndxMTimeFromParentCurrentArr = $IndxMTimeFromParentArr
	Global $IndxRTimeFromParentCurrentArr = $IndxRTimeFromParentArr
	Return 1
EndFunc
#cs
Func _ExtractSystemfile($TargetFile)
	Global $DataQ[1], $RUN_VCN[1], $RUN_Clusters[1]
	If StringLen($TargetDrive)=1 Then $TargetDrive=$TargetDrive&":"
	_ReadBootSector($TargetDrive)
	$BytesPerCluster = $SectorsPerCluster*$BytesPerSector
	$MFTEntry = _FindMFT($TargetDrive,0)
	_DecodeMFTRecord($TargetDrive,$MFTEntry,0)
	_DecodeDataQEntry($DataQ[1])
	$MFTSize = $DATA_RealSize
	Global $RUN_VCN[1], $RUN_Clusters[1]
	_ExtractDataRuns()
	$MFT_RUN_VCN = $RUN_VCN
	$MFT_RUN_Clusters = $RUN_Clusters
	_ExtractSingleFile(Int($TargetFile,2))
	_WinAPI_CloseHandle($hDisk)
EndFunc
#ce
Func _ExtractSingleFile($MFTReferenceNumber)
	Global $DataQ[1]				;clear array
	$RetRec = _FindFileMFTRecord($TargetDrive,$MFTReferenceNumber)
	$MFTRecord = $RetRec[1]
	If $MFTRecord = "" Then
		ConsoleWrite("Target " & $MFTReferenceNumber & " not found" & @CRLF)
		Return SetError(1,0,0)
	ElseIf StringMid($MFTRecord,3,8) <> $RecordSignature AND StringMid($MFTRecord,3,8) <> $RecordSignatureBad Then
		ConsoleWrite("Found record is not valid:" & @CRLF)
		ConsoleWrite(_HexEncode($MFTRecord) & @crlf)
		Return SetError(1,0,0)
	EndIf
	_DecodeMFTRecord($TargetDrive,$MFTRecord,1)
	Return
EndFunc

Func _DecodeAttrList($TargetFile, $AttrList)
	Local $offset, $length, $nBytes, $hFile, $LocalAttribID, $LocalName, $ALRecordLength, $ALNameLength, $ALNameOffset
	If StringMid($AttrList, 17, 2) = "00" Then		;attribute list is in $AttrList
		$offset = Dec(_SwapEndian(StringMid($AttrList, 41, 4)))
		$List = StringMid($AttrList, $offset*2+1)
;		$IsolatedAttributeList = $list
	Else			;attribute list is found from data run in $AttrList
		$size = Dec(_SwapEndian(StringMid($AttrList, $offset*2 + 97, 16)))
		$offset = ($offset + Dec(_SwapEndian(StringMid($AttrList, $offset*2 + 65, 4))))*2
		$DataRun = StringMid($AttrList, $offset+1, StringLen($AttrList)-$offset)
;		ConsoleWrite("Attribute_List DataRun is " & $DataRun & @CRLF)
		Global $RUN_VCN[1], $RUN_Clusters[1]
		_ExtractDataRuns()
		$tBuffer = DllStructCreate("byte[" & $BytesPerCluster & "]")
		$hFile = _WinAPI_CreateFile("\\.\" & $TargetDrive, 2, 6, 6)
		If $hFile = 0 Then
			ConsoleWrite("Error in function CreateFile when trying to locate Attribute List." & @CRLF)
			_WinAPI_CloseHandle($hFile)
			Return SetError(1,0,0)
		EndIf
		$List = ""
		For $r = 1 To Ubound($RUN_VCN)-1
			_WinAPI_SetFilePointerEx($hFile, $RUN_VCN[$r]*$BytesPerCluster, $FILE_BEGIN)
			For $i = 1 To $RUN_Clusters[$r]
				_WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer), $BytesPerCluster, $nBytes)
				$List &= StringTrimLeft(DllStructGetData($tBuffer, 1),2)
			Next
		Next
;		_DebugOut("***AttrList New:",$List)
		_WinAPI_CloseHandle($hFile)
		$List = StringMid($List, 1, $size*2)
	EndIf
	$IsolatedAttributeList = $list
	$offset=0
	$str=""
	While StringLen($list) > $offset*2
		$type=StringMid($List, ($offset*2)+1, 8)
		$ALRecordLength = Dec(_SwapEndian(StringMid($List, $offset*2 + 9, 4)))
		$ALNameLength = Dec(_SwapEndian(StringMid($List, $offset*2 + 13, 2)))
		$ALNameOffset = Dec(_SwapEndian(StringMid($List, $offset*2 + 15, 2)))
		$TestVCN = Dec(_SwapEndian(StringMid($List, $offset*2 + 17, 16)))
		$ref=Dec(_SwapEndian(StringMid($List, $offset*2 + 33, 8)))
		$LocalAttribID = "0x" & StringMid($List, $offset*2 + 49, 2) & StringMid($List, $offset*2 + 51, 2)
		If $ALNameLength > 0 Then
			$LocalName = StringMid($List, $offset*2 + 53, $ALNameLength*2*2)
			$LocalName = _UnicodeHexToStr($LocalName)
		Else
			$LocalName = ""
		EndIf
		If $ref <> $TargetFile Then		;new attribute
			If Not StringInStr($str, $ref) Then $str &= $ref & "-"
		EndIf
		If $type=$DATA Then
			$DataInAttrlist=1
			$IsolatedData=StringMid($List, ($offset*2)+1, $ALRecordLength*2)
			If $TestVCN=0 Then $DataIsResident=1
		EndIf
		$offset += Dec(_SwapEndian(StringMid($List, $offset*2 + 9, 4)))
	WEnd
	If $str = "" Then
		ConsoleWrite("No extra MFT records found" & @CRLF)
	Else
		$AttrQ = StringSplit(StringTrimRight($str,1), "-")
;		ConsoleWrite("Decode of $ATTRIBUTE_LIST reveiled extra MFT Records to be examined = " & _ArrayToString($AttrQ, @CRLF) & @CRLF)
	EndIf
EndFunc

Func _StripMftRecord($MFTEntry)
	$UpdSeqArrOffset = Dec(_SwapEndian(StringMid($MFTEntry,11,4)))
	$UpdSeqArrSize = Dec(_SwapEndian(StringMid($MFTEntry,15,4)))
	$UpdSeqArr = StringMid($MFTEntry,3+($UpdSeqArrOffset*2),$UpdSeqArrSize*2*2)

	If $MFT_Record_Size = 1024 Then
		Local $UpdSeqArrPart0 = StringMid($UpdSeqArr,1,4)
		Local $UpdSeqArrPart1 = StringMid($UpdSeqArr,5,4)
		Local $UpdSeqArrPart2 = StringMid($UpdSeqArr,9,4)
		Local $RecordEnd1 = StringMid($MFTEntry,1023,4)
		Local $RecordEnd2 = StringMid($MFTEntry,2047,4)
		If $UpdSeqArrPart0 <> $RecordEnd1 OR $UpdSeqArrPart0 <> $RecordEnd2 Then
;			_DebugOut("The record failed Fixup", $MFTEntry)
			ConsoleWrite("The record failed Fixup:" & @CRLF)
			ConsoleWrite(_HexEncode($MFTEntry) & @CRLF)
			Return ""
		EndIf
		$MFTEntry = StringMid($MFTEntry,1,1022) & $UpdSeqArrPart1 & StringMid($MFTEntry,1027,1020) & $UpdSeqArrPart2
	ElseIf $MFT_Record_Size = 4096 Then
		Local $UpdSeqArrPart0 = StringMid($UpdSeqArr,1,4)
		Local $UpdSeqArrPart1 = StringMid($UpdSeqArr,5,4)
		Local $UpdSeqArrPart2 = StringMid($UpdSeqArr,9,4)
		Local $UpdSeqArrPart3 = StringMid($UpdSeqArr,13,4)
		Local $UpdSeqArrPart4 = StringMid($UpdSeqArr,17,4)
		Local $UpdSeqArrPart5 = StringMid($UpdSeqArr,21,4)
		Local $UpdSeqArrPart6 = StringMid($UpdSeqArr,25,4)
		Local $UpdSeqArrPart7 = StringMid($UpdSeqArr,29,4)
		Local $UpdSeqArrPart8 = StringMid($UpdSeqArr,33,4)
		Local $RecordEnd1 = StringMid($MFTEntry,1023,4)
		Local $RecordEnd2 = StringMid($MFTEntry,2047,4)
		Local $RecordEnd3 = StringMid($MFTEntry,3071,4)
		Local $RecordEnd4 = StringMid($MFTEntry,4095,4)
		Local $RecordEnd5 = StringMid($MFTEntry,5119,4)
		Local $RecordEnd6 = StringMid($MFTEntry,6143,4)
		Local $RecordEnd7 = StringMid($MFTEntry,7167,4)
		Local $RecordEnd8 = StringMid($MFTEntry,8191,4)
		If $UpdSeqArrPart0 <> $RecordEnd1 OR $UpdSeqArrPart0 <> $RecordEnd2 OR $UpdSeqArrPart0 <> $RecordEnd3 OR $UpdSeqArrPart0 <> $RecordEnd4 OR $UpdSeqArrPart0 <> $RecordEnd5 OR $UpdSeqArrPart0 <> $RecordEnd6 OR $UpdSeqArrPart0 <> $RecordEnd7 OR $UpdSeqArrPart0 <> $RecordEnd8 Then
;			_DebugOut("The record failed Fixup", $MFTEntry)
			ConsoleWrite("The record failed Fixup:" & @CRLF)
			ConsoleWrite(_HexEncode($MFTEntry) & @CRLF)
			Return ""
		Else
			$MFTEntry =  StringMid($MFTEntry,1,1022) & $UpdSeqArrPart1 & StringMid($MFTEntry,1027,1020) & $UpdSeqArrPart2 & StringMid($MFTEntry,2051,1020) & $UpdSeqArrPart3 & StringMid($MFTEntry,3075,1020) & $UpdSeqArrPart4 & StringMid($MFTEntry,4099,1020) & $UpdSeqArrPart5 & StringMid($MFTEntry,5123,1020) & $UpdSeqArrPart6 & StringMid($MFTEntry,6147,1020) & $UpdSeqArrPart7 & StringMid($MFTEntry,7171,1020) & $UpdSeqArrPart8
		EndIf
	EndIf

	$RecordSize = Dec(_SwapEndian(StringMid($MFTEntry,51,8)),2)
	$HeaderSize = Dec(_SwapEndian(StringMid($MFTEntry,43,4)),2)
	$MFTEntry = StringMid($MFTEntry,$HeaderSize*2+3,($RecordSize-$HeaderSize-8)*2)        ;strip "0x..." and "FFFFFFFF..."
	Return $MFTEntry
EndFunc

Func _DecodeDataQEntry($attr)		;processes data attribute
   $NonResidentFlag = StringMid($attr,17,2)
   $NameLength = Dec(StringMid($attr,19,2))
   $NameOffset = Dec(_SwapEndian(StringMid($attr,21,4)))
   If $NameLength > 0 Then		;must be ADS
	  $ADS_Name = _UnicodeHexToStr(StringMid($attr,$NameOffset*2 + 1,$NameLength*4))
	  $ADS_Name = $FN_FileName & "[ADS_" & $ADS_Name & "]"
   Else
	  $ADS_Name = $FN_FileName		;need to preserve $FN_FileName
   EndIf
   $Flags = StringMid($attr,25,4)
   If BitAND($Flags,"0100") Then $IsCompressed = 1
   If BitAND($Flags,"0080") Then $IsSparse = 1
   If $NonResidentFlag = '01' Then
	  $DATA_Clusters = Dec(_SwapEndian(StringMid($attr,49,16)),2) - Dec(_SwapEndian(StringMid($attr,33,16)),2) + 1
	  $DATA_RealSize = Dec(_SwapEndian(StringMid($attr,97,16)),2)
	  $DATA_InitSize = Dec(_SwapEndian(StringMid($attr,113,16)),2)
	  $Offset = Dec(_SwapEndian(StringMid($attr,65,4)))
	  $DataRun = StringMid($attr,$Offset*2+1,(StringLen($attr)-$Offset)*2)
   ElseIf $NonResidentFlag = '00' Then
	  $DATA_LengthOfAttribute = Dec(_SwapEndian(StringMid($attr,33,8)),2)
	  $Offset = Dec(_SwapEndian(StringMid($attr,41,4)))
	  $DataRun = StringMid($attr,$Offset*2+1,$DATA_LengthOfAttribute*2)
   EndIf
EndFunc

Func _DecodeMFTRecord0($record, $FileRef)      ;produces DataQ
	$MftAttrListString=","
;	ConsoleWrite(_HexEncode($record)&@CRLF)
	$record = _DoFixup($record, $FileRef)
	If $record = "" then Return ""  ;corrupt, failed fixup
	$RecordSize = Dec(_SwapEndian(StringMid($record,51,8)),2)
	$AttributeOffset = (Dec(StringMid($record,43,2))*2)+3
	While 1		;only want Attribute List and Data Attributes
		$Type = Dec(_SwapEndian(StringMid($record,$AttributeOffset,8)),2)
		If $Type > 256 Then ExitLoop		;attributes may not be in numerical order
		$AttributeSize = Dec(_SwapEndian(StringMid($record,$AttributeOffset+8,8)),2)
		If $Type = 32 Then
			$AttrList = StringMid($record,$AttributeOffset,$AttributeSize*2)	;whole attribute
			$AttrList = _DecodeAttrList2($FileRef, $AttrList)		;produces $AttrQ - extra record list
;			ConsoleWrite("$AttrList: " & $AttrList & @CRLF)
			If $AttrList = "" Then
				_DebugOut($FileRef & " Bad Attribute List signature", $record)
				Return ""
			Else
				If $AttrQ[0] = "" Then ContinueLoop		;no new records
				$str = ""
				For $i = 1 To $AttrQ[0]
					$MftAttrListString &= $AttrQ[$i] & ","
;					ConsoleWrite("$AttrQ[$i]: " & $AttrQ[$i] & @CRLF)
					If Not IsNumber(Int($AttrQ[$i])) Then
						_DebugOut($FileRef & " Overwritten extra record (" & $AttrQ[$i] & ")", $record)
						Return ""
					EndIf
;					ConsoleWrite("$AttrQ[$i]: " & $AttrQ[$i] & @CRLF)
					$rec = _GetAttrListMFTRecord(($AttrQ[$i]*$MFT_Record_Size)+($LogicalClusterNumberforthefileMFT*$BytesPerCluster))
					If StringMid($rec,3,8) <> $RecordSignature Then
						_DebugOut($FileRef & " Bad signature for extra record", $record)
						_DebugOut($FileRef & " Bad signature for extra record", $rec)
						Return ""
					EndIf
					If Dec(_SwapEndian(StringMid($rec,67,8)),2) <> $FileRef Then
						_DebugOut($FileRef & " Bad extra record", $record)
						Return ""
					EndIf
;					$rec = _StripMftRecord($rec, $FileRef)
					$rec = _StripMftRecord($rec)
					If $rec = "" Then
						_DebugOut($FileRef & " Extra record failed Fixup", $record)
						Return ""
					EndIf
					$str &= $rec		;no header or end marker
				Next
				$record = StringMid($record,1,($RecordSize-8)*2+2) & $str & "FFFFFFFF"       ;strip end first then add
			EndIf
		ElseIf $Type = 128 Then
			ReDim $DataQ[UBound($DataQ) + 1]
			$DataQ[UBound($DataQ) - 1] = StringMid($record,$AttributeOffset,$AttributeSize*2) 		;whole data attribute
		EndIf
		$AttributeOffset += $AttributeSize*2
	WEnd
	Return $record
EndFunc

Func _DecodeMFTRecord($TargetDevice,$MFTEntry,$MFTMode)
;Global $IndxEntryNumberArr[1],$IndxMFTReferenceArr[1],$IndxIndexFlagsArr[1],$IndxMFTReferenceOfParentArr[1],$IndxCTimeArr[1],$IndxATimeArr[1],$IndxMTimeArr[1],$IndxRTimeArr[1],$IndxAllocSizeArr[1],$IndxRealSizeArr[1],$IndxFileFlagsArr[1],$IndxFileNameArr[1],$IndxSubNodeVCNArr[1],$IndxNameSpaceArr[1]
Global $IndxEntryNumberArr[1],$IndxMFTReferenceArr[1],$IndxMFTReferenceOfParentArr[1],$IndxCTimeArr[1],$IndxATimeArr[1],$IndxMTimeArr[1],$IndxRTimeArr[1],$IndxFileNameArr[1]
Global $SIArrValue[13][1], $SIArrOffset[13][1], $SIArrSize[13][1], $FNArrValue[14][1], $FNArrOffset[14][1], $FN_Number=0, $Header_SequenceNo='', $Header_HardLinkCount=''
Local $MFTEntryOrig,$SI_Number,$DATA_Number,$ATTRIBLIST_Number,$OBJID_Number,$SECURITY_Number,$VOLNAME_Number,$VOLINFO_Number,$INDEXROOT_Number,$INDEXALLOC_Number,$BITMAP_Number,$REPARSEPOINT_Number,$EAINFO_Number,$EA_Number,$PROPERTYSET_Number,$LOGGEDUTILSTREAM_Number
Local $INDEX_ROOT_ON="FALSE",$INDEX_ALLOCATION_ON="FALSE",$CoreData[2],$CoreDataChunk,$CoreDataName,$CoreIndexAllocation,$CoreIndexAllocationChunk,$CoreIndexAllocationName
Global $DataQ[1],$Mode2Data=""
Global $IRArr[12][2],$IndxArr[20][2]

_SetArrays()
$HEADER_RecordRealSize = ""
$HEADER_MFTREcordNumber = ""
$UpdSeqArrOffset = Dec(_SwapEndian(StringMid($MFTEntry,11,4)))
$UpdSeqArrSize = Dec(_SwapEndian(StringMid($MFTEntry,15,4)))
$UpdSeqArr = StringMid($MFTEntry,3+($UpdSeqArrOffset*2),$UpdSeqArrSize*2*2)
If Not $SkipFixups Then
	If $MFT_Record_Size = 1024 Then
		Local $UpdSeqArrPart0 = StringMid($UpdSeqArr,1,4)
		Local $UpdSeqArrPart1 = StringMid($UpdSeqArr,5,4)
		Local $UpdSeqArrPart2 = StringMid($UpdSeqArr,9,4)
		Local $RecordEnd1 = StringMid($MFTEntry,1023,4)
		Local $RecordEnd2 = StringMid($MFTEntry,2047,4)
		If $UpdSeqArrPart0 <> $RecordEnd1 OR $UpdSeqArrPart0 <> $RecordEnd2 Then
;			_DebugOut("The record failed Fixup", $MFTEntry)
			ConsoleWrite("The record failed Fixup:" & @CRLF)
			ConsoleWrite(_HexEncode($MFTEntry) & @CRLF)
			Return -1
		EndIf
		$MFTEntry = StringMid($MFTEntry,1,1022) & $UpdSeqArrPart1 & StringMid($MFTEntry,1027,1020) & $UpdSeqArrPart2
	ElseIf $MFT_Record_Size = 4096 Then
		Local $UpdSeqArrPart0 = StringMid($UpdSeqArr,1,4)
		Local $UpdSeqArrPart1 = StringMid($UpdSeqArr,5,4)
		Local $UpdSeqArrPart2 = StringMid($UpdSeqArr,9,4)
		Local $UpdSeqArrPart3 = StringMid($UpdSeqArr,13,4)
		Local $UpdSeqArrPart4 = StringMid($UpdSeqArr,17,4)
		Local $UpdSeqArrPart5 = StringMid($UpdSeqArr,21,4)
		Local $UpdSeqArrPart6 = StringMid($UpdSeqArr,25,4)
		Local $UpdSeqArrPart7 = StringMid($UpdSeqArr,29,4)
		Local $UpdSeqArrPart8 = StringMid($UpdSeqArr,33,4)
		Local $RecordEnd1 = StringMid($MFTEntry,1023,4)
		Local $RecordEnd2 = StringMid($MFTEntry,2047,4)
		Local $RecordEnd3 = StringMid($MFTEntry,3071,4)
		Local $RecordEnd4 = StringMid($MFTEntry,4095,4)
		Local $RecordEnd5 = StringMid($MFTEntry,5119,4)
		Local $RecordEnd6 = StringMid($MFTEntry,6143,4)
		Local $RecordEnd7 = StringMid($MFTEntry,7167,4)
		Local $RecordEnd8 = StringMid($MFTEntry,8191,4)
		If $UpdSeqArrPart0 <> $RecordEnd1 OR $UpdSeqArrPart0 <> $RecordEnd2 OR $UpdSeqArrPart0 <> $RecordEnd3 OR $UpdSeqArrPart0 <> $RecordEnd4 OR $UpdSeqArrPart0 <> $RecordEnd5 OR $UpdSeqArrPart0 <> $RecordEnd6 OR $UpdSeqArrPart0 <> $RecordEnd7 OR $UpdSeqArrPart0 <> $RecordEnd8 Then
;			_DebugOut("The record failed Fixup", $MFTEntry)
			ConsoleWrite("The record failed Fixup:" & @CRLF)
			ConsoleWrite(_HexEncode($MFTEntry) & @CRLF)
			Return -1
		Else
			$MFTEntry =  StringMid($MFTEntry,1,1022) & $UpdSeqArrPart1 & StringMid($MFTEntry,1027,1020) & $UpdSeqArrPart2 & StringMid($MFTEntry,2051,1020) & $UpdSeqArrPart3 & StringMid($MFTEntry,3075,1020) & $UpdSeqArrPart4 & StringMid($MFTEntry,4099,1020) & $UpdSeqArrPart5 & StringMid($MFTEntry,5123,1020) & $UpdSeqArrPart6 & StringMid($MFTEntry,6147,1020) & $UpdSeqArrPart7 & StringMid($MFTEntry,7171,1020) & $UpdSeqArrPart8
		EndIf
	EndIf
EndIf
;If $SkipFixups Then
;	$record_tmp = _DoFixup($record, $FileRef)
;	If Not $record_tmp = "" Then $record = $record_tmp
;EndIf
;If $record = "" then Return ""  ;corrupt, failed fixup
;------------If Not $SkipFixups Then $record = _DoFixup($record, $ref)
$HEADER_RecordRealSize = Dec(_SwapEndian(StringMid($MFTEntry,51,8)),2)
If $UpdSeqArrOffset = 48 Then
	$HEADER_MFTREcordNumber = Dec(_SwapEndian(StringMid($MFTEntry,91,8)),2)
Else
	$HEADER_MFTREcordNumber = "NT style"
EndIf
$Header_SequenceNo = Dec(_SwapEndian(StringMid($MFTEntry,35,4)))
$Header_HardLinkCount = Dec(_SwapEndian(StringMid($MFTEntry,39,4)))

$AttributeOffset = (Dec(StringMid($MFTEntry,43,2))*2)+3

While 1
	$AttributeType = StringMid($MFTEntry,$AttributeOffset,8)
	$AttributeSize = StringMid($MFTEntry,$AttributeOffset+8,8)
	$AttributeSize = Dec(_SwapEndian($AttributeSize),2)
;	ConsoleWrite("$AttributeType: " & $AttributeType & @CRLF)
	Select
		Case $AttributeType = $STANDARD_INFORMATION
;			$STANDARD_INFORMATION_ON = "TRUE"
			$SI_Number += 1
			_Get_StandardInformation($MFTEntry,$AttributeOffset,$AttributeSize*2,$SI_Number)
		Case $AttributeType = $ATTRIBUTE_LIST
;			$ATTRIBUTE_LIST_ON = "TRUE"
			$ATTRIBLIST_Number += 1
;			ContinueLoop
;			If $MFTMode < 2 Then ContinueLoop
			$MFTEntryOrig = $MFTEntry
			$AttrList = StringMid($MFTEntry,$AttributeOffset,$AttributeSize*2)
			_DecodeAttrList($HEADER_MFTRecordNumber, $AttrList)		;produces $AttrQ - extra record list
			$str = ""
			For $i = 1 To $AttrQ[0]
				$RetRec = _FindFileMFTRecord($TargetDevice,$AttrQ[$i])
				$record = $RetRec[1]
				$str &= _StripMftRecord($record)		;no header or end marker
			Next
			$str &= "FFFFFFFF"		;add end marker
			$MFTEntry = StringMid($MFTEntry,1,($HEADER_RecordRealSize-8)*2+2) & $str       ;strip "FFFFFFFF..." first
   		Case $AttributeType = $FILE_NAME
;			$FILE_NAME_ON = "TRUE"
			$FN_Number += 1
			$attr = StringMid($MFTEntry,$AttributeOffset,$AttributeSize*2)
			$NameSpace = StringMid($attr,179,2)
			Select
				Case $NameSpace = "00"	;POSIX
					$NameQ[2] = $attr
				Case $NameSpace = "01"	;WIN32
					$NameQ[4] = $attr
				Case $NameSpace = "02"	;DOS
					$NameQ[1] = $attr
				Case $NameSpace = "03"	;DOS+WIN32
					$NameQ[3] = $attr
			EndSelect
			_Get_FileName($MFTEntry,$AttributeOffset,$AttributeSize*2,$FN_Number)
		Case $AttributeType = $OBJECT_ID
			If $IsRawShadowCopy Then Return 1 ;We are only interested in ref and name for comparison.
;			$OBJECT_ID_ON = "TRUE"
			$OBJID_Number += 1
		Case $AttributeType = $SECURITY_DESCRIPTOR
			If $IsRawShadowCopy Then Return 1 ;We are only interested in ref and name for comparison.
;			$SECURITY_DESCRIPTOR_ON = "TRUE"
			$SECURITY_Number += 1
		Case $AttributeType = $VOLUME_NAME
			If $IsRawShadowCopy Then Return 1 ;We are only interested in ref and name for comparison.
;			$VOLUME_NAME_ON = "TRUE"
			$VOLNAME_Number += 1
		Case $AttributeType = $VOLUME_INFORMATION
			If $IsRawShadowCopy Then Return 1 ;We are only interested in ref and name for comparison.
;			$VOLUME_INFORMATION_ON = "TRUE"
			$VOLINFO_Number += 1
		Case $AttributeType = $DATA
			If $IsRawShadowCopy Then Return 1 ;We are only interested in ref and name for comparison.
;			$DATA_ON = "TRUE"
			$DATA_Number += 1
			_ArrayAdd($DataQ, StringMid($MFTEntry,$AttributeOffset,$AttributeSize*2))
			If $MFTMode = 2 Then ;For files that we need the content of, like the shadow copy master file. It is a small file so load it to memory
				$CoreData = _GetAttributeEntry($TargetDevice,StringMid($MFTEntry,$AttributeOffset,$AttributeSize*2))
				$CoreDataChunk = $CoreData[0]
				$CoreDataName = $CoreData[1]
				;ConsoleWrite("Retrieved data:" & @CRLF)
				;ConsoleWrite(_HexEncode("0x"&$CoreDataChunk) & @CRLF)
				$Mode2Data = $CoreDataChunk
			ElseIf $MFTMode = 3 Then ;For the actual shadow copy files we only want to locate the clusters
				$CoreData = _GetAttributeEntryNoRead($TargetDevice,StringMid($MFTEntry,$AttributeOffset,$AttributeSize*2))
			EndIf
		Case $AttributeType = $INDEX_ROOT
			If $IsRawShadowCopy Then Return 1 ;We are only interested in ref and name for comparison.
			$INDEX_ROOT_ON = "TRUE"
			$INDEXROOT_Number += 1
			ReDim $IRArr[12][$INDEXROOT_Number+1]
			;INDEX_ROOT is ok to process for shadows copy data as it is resident
;			If Not $IsRawShadowCopy Then
				$CoreIndexRoot = _GetAttributeEntry($TargetDevice,StringMid($MFTEntry,$AttributeOffset,$AttributeSize*2))
				$CoreIndexRootChunk = $CoreIndexRoot[0]
				$CoreIndexRootName = $CoreIndexRoot[1]
				If $CoreIndexRootName = "$I30" Then _Get_IndexRoot($CoreIndexRootChunk,$INDEXROOT_Number,$CoreIndexRootName)
;			EndIf
		Case $AttributeType = $INDEX_ALLOCATION
			If $IsRawShadowCopy Then Return 1 ;We are only interested in ref and name for comparison.
			$INDEX_ALLOCATION_ON = "TRUE"
			$INDEXALLOC_Number += 1
			If $DoIndxOffsetArray Then $IsCurrentIndxOfParent=1
;			ConsoleWrite("IsShadowCopy: " & $IsRawShadowCopy & @CRLF)
;			If Not $IsRawShadowCopy Then ;INDX may point to somewhere on the volume, and not within the shadow copy file
			If $MFTMode = 1 Then ;Regular mode, only parse
				$CoreIndexAllocation = _GetAttributeEntry($TargetDevice,StringMid($MFTEntry,$AttributeOffset,$AttributeSize*2))
				$CoreIndexAllocationChunk = $CoreIndexAllocation[0]
				$CoreIndexAllocationName = $CoreIndexAllocation[1]
	;			_Arrayadd($HexDumpIndxRecord,$CoreIndexAllocationChunk)
				If $CoreIndexAllocationName = "$I30" Then _Get_IndexAllocation($CoreIndexAllocationChunk,$INDEXALLOC_Number,$CoreIndexAllocationName)
			EndIf
		Case $AttributeType = $BITMAP
			If $IsRawShadowCopy Then Return 1 ;We are only interested in ref and name for comparison.
;			$BITMAP_ON = "TRUE"
			$BITMAP_Number += 1
		Case $AttributeType = $REPARSE_POINT
			If $IsRawShadowCopy Then Return 1 ;We are only interested in ref and name for comparison.
;			$REPARSE_POINT_ON = "TRUE"
			$REPARSEPOINT_Number += 1
		Case $AttributeType = $EA_INFORMATION
			If $IsRawShadowCopy Then Return 1 ;We are only interested in ref and name for comparison.
;			$EA_INFORMATION_ON = "TRUE"
			$EAINFO_Number += 1
		Case $AttributeType = $EA
			If $IsRawShadowCopy Then Return 1 ;We are only interested in ref and name for comparison.
;			$EA_ON = "TRUE"
			$EA_Number += 1
		Case $AttributeType = $PROPERTY_SET
			If $IsRawShadowCopy Then Return 1 ;We are only interested in ref and name for comparison.
;			$PROPERTY_SET_ON = "TRUE"
			$PROPERTYSET_Number += 1
		Case $AttributeType = $LOGGED_UTILITY_STREAM
			If $IsRawShadowCopy Then Return 1 ;We are only interested in ref and name for comparison.
;			$LOGGED_UTILITY_STREAM_ON = "TRUE"
			$LOGGEDUTILSTREAM_Number += 1
		Case $AttributeType = $ATTRIBUTE_END_MARKER
			ExitLoop
	EndSelect
	$AttributeOffset += $AttributeSize*2
WEnd
$AttributesArr[9][2] = $INDEX_ROOT_ON
$AttributesArr[10][2] = $INDEX_ALLOCATION_ON
Return 2
EndFunc

Func _Get_StandardInformation($MFTEntry,$SI_Offset,$SI_Size,$SI_Number)
Redim $SIArrValue[13][$SI_Number+1]
Redim $SIArrOffset[13][$SI_Number+1]
Redim $SIArrSize[13][$SI_Number+1]
$SI_HEADER_Flags = StringMid($MFTEntry,$SI_Offset+24,4)
$SI_HEADER_Flags = _SwapEndian($SI_HEADER_Flags)
$SI_HEADER_Flags = _AttribHeaderFlags("0x" & $SI_HEADER_Flags)
;
$SI_CTime = StringMid($MFTEntry,$SI_Offset+48,16)
$SI_CTime = _SwapEndian($SI_CTime)
$SI_CTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $SI_CTime)
$SI_CTime = _WinTime_UTCFileTimeFormat(Dec($SI_CTime)-$tDelta,$DateTimeFormat,2)
$SI_CTime = $SI_CTime & ":" & _FillZero(StringRight($SI_CTime_tmp,4))
;
$SI_ATime = StringMid($MFTEntry,$SI_Offset+64,16)
$SI_ATime = _SwapEndian($SI_ATime)
$SI_ATime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $SI_ATime)
$SI_ATime = _WinTime_UTCFileTimeFormat(Dec($SI_ATime)-$tDelta,$DateTimeFormat,2)
$SI_ATime = $SI_ATime & ":" & _FillZero(StringRight($SI_ATime_tmp,4))
;
$SI_MTime = StringMid($MFTEntry,$SI_Offset+80,16)
$SI_MTime = _SwapEndian($SI_MTime)
$SI_MTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $SI_MTime)
$SI_MTime = _WinTime_UTCFileTimeFormat(Dec($SI_MTime)-$tDelta,$DateTimeFormat,2)
$SI_MTime = $SI_MTime & ":" & _FillZero(StringRight($SI_MTime_tmp,4))
;
$SI_RTime = StringMid($MFTEntry,$SI_Offset+96,16)
$SI_RTime = _SwapEndian($SI_RTime)
$SI_RTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $SI_RTime)
$SI_RTime = _WinTime_UTCFileTimeFormat(Dec($SI_RTime)-$tDelta,$DateTimeFormat,2)
$SI_RTime = $SI_RTime & ":" & _FillZero(StringRight($SI_RTime_tmp,4))
;
$SI_FilePermission = StringMid($MFTEntry,$SI_Offset+112,8)
;ConsoleWrite("$SI_FilePermission: " & $SI_FilePermission & @CRLF)
$SI_FilePermission = _SwapEndian($SI_FilePermission)
$SI_FilePermission = _File_Permissions("0x" & $SI_FilePermission)
;ConsoleWrite("$SI_FilePermission: " & $SI_FilePermission & @CRLF)
$SI_MaxVersions = StringMid($MFTEntry,$SI_Offset+120,8)
$SI_MaxVersions = Dec(_SwapEndian($SI_MaxVersions))
$SI_VersionNumber = StringMid($MFTEntry,$SI_Offset+128,8)
$SI_VersionNumber = Dec(_SwapEndian($SI_VersionNumber))
$SI_ClassID = StringMid($MFTEntry,$SI_Offset+136,8)
$SI_ClassID = Dec(_SwapEndian($SI_ClassID))
$SI_OwnerID = StringMid($MFTEntry,$SI_Offset+144,8)
$SI_OwnerID = Dec(_SwapEndian($SI_OwnerID))
$SI_SecurityID = StringMid($MFTEntry,$SI_Offset+152,8)
$SI_SecurityID = Dec(_SwapEndian($SI_SecurityID))
$SI_USN = StringMid($MFTEntry,$SI_Offset+176,16)
$SI_USN = Dec(_SwapEndian($SI_USN))
If Not $IsFirstRun Then
	$SIArrValue[1][$SI_Number] = $SI_HEADER_Flags
	$SIArrValue[2][$SI_Number] = $SI_CTime
	$SIArrValue[3][$SI_Number] = $SI_ATime
	$SIArrValue[4][$SI_Number] = $SI_MTime
	$SIArrValue[5][$SI_Number] = $SI_RTime
	$SIArrValue[6][$SI_Number] = $SI_FilePermission
	$SIArrValue[7][$SI_Number] = $SI_MaxVersions
	$SIArrValue[8][$SI_Number] = $SI_VersionNumber
	$SIArrValue[9][$SI_Number] = $SI_ClassID
	$SIArrValue[10][$SI_Number] = $SI_OwnerID
	$SIArrValue[11][$SI_Number] = $SI_SecurityID
	$SIArrValue[12][$SI_Number] = $SI_USN
;	_ArrayDisplay($SIArrValue,"$SIArrValue")
;
	$SIArrOffset[1][$SI_Number] = $SI_Offset+24
	$SIArrOffset[2][$SI_Number] = $SI_Offset+48
	$SIArrOffset[3][$SI_Number] = $SI_Offset+64
	$SIArrOffset[4][$SI_Number] = $SI_Offset+80
	$SIArrOffset[5][$SI_Number] = $SI_Offset+96
	$SIArrOffset[6][$SI_Number] = $SI_Offset+112
	$SIArrOffset[7][$SI_Number] = $SI_Offset+120
	$SIArrOffset[8][$SI_Number] = $SI_Offset+128
	$SIArrOffset[9][$SI_Number] = $SI_Offset+136
	$SIArrOffset[10][$SI_Number] = $SI_Offset+144
	$SIArrOffset[11][$SI_Number] = $SI_Offset+152
	$SIArrOffset[12][$SI_Number] = $SI_Offset+176
;
	$SIArrSize[1][$SI_Number] = 2
	$SIArrSize[2][$SI_Number] = 8
	$SIArrSize[3][$SI_Number] = 8
	$SIArrSize[4][$SI_Number] = 8
	$SIArrSize[5][$SI_Number] = 8
	$SIArrSize[6][$SI_Number] = 4
	$SIArrSize[7][$SI_Number] = 4
	$SIArrSize[8][$SI_Number] = 4
	$SIArrSize[9][$SI_Number] = 4
	$SIArrSize[10][$SI_Number] = 4
	$SIArrSize[11][$SI_Number] = 4
	$SIArrSize[12][$SI_Number] = 8
EndIf
EndFunc

Func _Get_FileName($MFTEntry,$FN_Offset,$FN_Size,$FN_Number)
Redim $FNArrValue[14][$FN_Number+1]
Redim $FNArrOffset[14][$FN_Number+1]
$FN_ParentReferenceNo = StringMid($MFTEntry,$FN_Offset+48,12)
$FN_ParentReferenceNo = Dec(_SwapEndian($FN_ParentReferenceNo))
$FN_ParentSequenceNo = StringMid($MFTEntry,$FN_Offset+60,4)
$FN_ParentSequenceNo = Dec(_SwapEndian($FN_ParentSequenceNo))
;
$FN_CTime = StringMid($MFTEntry,$FN_Offset+64,16)
$FN_CTime = _SwapEndian($FN_CTime)
$FN_CTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $FN_CTime)
$FN_CTime = _WinTime_UTCFileTimeFormat(Dec($FN_CTime)-$tDelta,$DateTimeFormat,2)
$FN_CTime = $FN_CTime & ":" & _FillZero(StringRight($FN_CTime_tmp,4))
;
$FN_ATime = StringMid($MFTEntry,$FN_Offset+80,16)
$FN_ATime = _SwapEndian($FN_ATime)
$FN_ATime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $FN_ATime)
$FN_ATime = _WinTime_UTCFileTimeFormat(Dec($FN_ATime)-$tDelta,$DateTimeFormat,2)
$FN_ATime = $FN_ATime & ":" & _FillZero(StringRight($FN_ATime_tmp,4))
;
$FN_MTime = StringMid($MFTEntry,$FN_Offset+96,16)
$FN_MTime = _SwapEndian($FN_MTime)
$FN_MTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $FN_MTime)
$FN_MTime = _WinTime_UTCFileTimeFormat(Dec($FN_MTime)-$tDelta,$DateTimeFormat,2)
$FN_MTime = $FN_MTime & ":" & _FillZero(StringRight($FN_MTime_tmp,4))
;
$FN_RTime = StringMid($MFTEntry,$FN_Offset+112,16)
$FN_RTime = _SwapEndian($FN_RTime)
$FN_RTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $FN_RTime)
$FN_RTime = _WinTime_UTCFileTimeFormat(Dec($FN_RTime)-$tDelta,$DateTimeFormat,2)
$FN_RTime = $FN_RTime & ":" & _FillZero(StringRight($FN_RTime_tmp,4))
;
$FN_AllocSize = StringMid($MFTEntry,$FN_Offset+128,16)
$FN_AllocSize = Dec(_SwapEndian($FN_AllocSize))
$FN_RealSize = StringMid($MFTEntry,$FN_Offset+144,16)
$FN_RealSize = Dec(_SwapEndian($FN_RealSize))
$FN_Flags = StringMid($MFTEntry,$FN_Offset+160,8)
;ConsoleWrite("$FN_Flags: " & $FN_Flags & @CRLF)
$FN_Flags = _SwapEndian($FN_Flags)
$FN_Flags = _File_Permissions("0x" & $FN_Flags)
;ConsoleWrite("$FN_Flags: " & $FN_Flags & @CRLF)
$FN_NameLength = StringMid($MFTEntry,$FN_Offset+176,2)
$FN_NameLength = Dec($FN_NameLength)
$FN_NameType = StringMid($MFTEntry,$FN_Offset+178,2)
Select
	Case $FN_NameType = '00'
		$FN_NameType = 'POSIX'
	Case $FN_NameType = '01'
		$FN_NameType = 'WIN32'
	Case $FN_NameType = '02'
		$FN_NameType = 'DOS'
	Case $FN_NameType = '03'
		$FN_NameType = 'DOS+WIN32'
	Case $FN_NameType <> '00' AND $FN_NameType <> '01' AND $FN_NameType <> '02' AND $FN_NameType <> '03'
		$FN_NameType = 'UNKNOWN'
EndSelect
$FN_NameSpace = $FN_NameLength-1
$FN_FileName = StringMid($MFTEntry,$FN_Offset+180,($FN_NameLength+$FN_NameSpace)*2)
$FN_FileName = _UnicodeHexToStr($FN_FileName)
If StringLen($FN_FileName) <> $FN_NameLength Then $INVALID_FILENAME = 1
If Not $IsFirstRun Then
	$FNArrValue[0][$FN_Number] = "FN Number " & $FN_Number
	$FNArrValue[1][$FN_Number] = $FN_ParentReferenceNo
	$FNArrValue[2][$FN_Number] = $FN_ParentSequenceNo
	$FNArrValue[3][$FN_Number] = $FN_CTime
	$FNArrValue[4][$FN_Number] = $FN_ATime
	$FNArrValue[5][$FN_Number] = $FN_MTime
	$FNArrValue[6][$FN_Number] = $FN_RTime
	$FNArrValue[7][$FN_Number] = $FN_AllocSize
	$FNArrValue[8][$FN_Number] = $FN_RealSize
	$FNArrValue[9][$FN_Number] = $FN_Flags
	$FNArrValue[10][$FN_Number] = $FN_NameLength
	$FNArrValue[11][$FN_Number] = $FN_NameType
	$FNArrValue[12][$FN_Number] = $FN_NameSpace
	$FNArrValue[13][$FN_Number] = $FN_FileName
;	_ArrayDisplay($FNArrValue,"$FNArrValue")

	$FNArrOffset[0][$FN_Number] = "Internal offset"
	$FNArrOffset[1][$FN_Number] = $FN_Offset+48
	$FNArrOffset[2][$FN_Number] = $FN_Offset+60
	$FNArrOffset[3][$FN_Number] = $FN_Offset+64
	$FNArrOffset[4][$FN_Number] = $FN_Offset+80
	$FNArrOffset[5][$FN_Number] = $FN_Offset+96
	$FNArrOffset[6][$FN_Number] = $FN_Offset+112
	$FNArrOffset[7][$FN_Number] = $FN_Offset+128
	$FNArrOffset[8][$FN_Number] = $FN_Offset+144
	$FNArrOffset[9][$FN_Number] = $FN_Offset+160
	$FNArrOffset[10][$FN_Number] = $FN_Offset+176
	$FNArrOffset[11][$FN_Number] = $FN_Offset+178
	$FNArrOffset[12][$FN_Number] = ""
	$FNArrOffset[13][$FN_Number] = $FN_Offset+180
EndIf
EndFunc

Func _ExtractDataRuns()
   $r=UBound($RUN_Clusters)
   ReDim $RUN_Clusters[$r + $MFT_Record_Size], $RUN_VCN[$r + $MFT_Record_Size]
   $i=1
   $RUN_VCN[0] = 0
   $BaseVCN = $RUN_VCN[0]
   If $DataRun = "" Then $DataRun = "00"
   Do
	  $RunListID = StringMid($DataRun,$i,2)
	  If $RunListID = "00" Then ExitLoop
	  $i += 2
	  $RunListClustersLength = Dec(StringMid($RunListID,2,1))
	  $RunListVCNLength = Dec(StringMid($RunListID,1,1))
	  $RunListClusters = Dec(_SwapEndian(StringMid($DataRun,$i,$RunListClustersLength*2)),2)
	  $i += $RunListClustersLength*2
	  $RunListVCN = _SwapEndian(StringMid($DataRun, $i, $RunListVCNLength*2))
	  ;next line handles positive or negative move
	  $BaseVCN += Dec($RunListVCN,2)-(($r>1) And (Dec(StringMid($RunListVCN,1,1))>7))*Dec(StringMid("10000000000000000",1,$RunListVCNLength*2+1),2)
	  If $RunListVCN <> "" Then
		 $RunListVCN = $BaseVCN
	  Else
		 $RunListVCN = 0
	  EndIf
	  If (($RunListVCN=0) And ($RunListClusters>16) And (Mod($RunListClusters,16)>0)) Then
		 ;may be sparse section at end of Compression Signature
		 $RUN_Clusters[$r] = Mod($RunListClusters,16)
		 $RUN_VCN[$r] = $RunListVCN
		 $RunListClusters -= Mod($RunListClusters,16)
		 $r += 1
	  ElseIf (($RunListClusters>16) And (Mod($RunListClusters,16)>0)) Then
		 ;may be compressed data section at start of Compression Signature
		 $RUN_Clusters[$r] = $RunListClusters-Mod($RunListClusters,16)
		 $RUN_VCN[$r] = $RunListVCN
		 $RunListVCN += $RUN_Clusters[$r]
		 $RunListClusters = Mod($RunListClusters,16)
		 $r += 1
	  EndIf
	  ;just normal or sparse data
	  $RUN_Clusters[$r] = $RunListClusters
	  $RUN_VCN[$r] = $RunListVCN
	  $r += 1
	  $i += $RunListVCNLength*2
   Until $i > StringLen($DataRun)
   ReDim $RUN_Clusters[$r], $RUN_VCN[$r]
EndFunc

Func _IsMftRecordSplit($MftRef)
	For $i = 1 To UBound($SplitMftRecArr)-1
		$SplitRecordPart2 = $SplitMftRecArr[$i]
		$SplitRecordTestRef = StringMid($SplitRecordPart2, 1, StringInStr($SplitRecordPart2, "?")-1)
		If $SplitRecordTestRef = $MftRef Then Return $i
	Next
	Return 0
EndFunc

Func _FindFileMFTRecord($TargetDevice,$MftRef)
	Local $nBytes, $TmpOffset, $Counter, $Counter2, $RecordJumper, $TargetFileDec, $RecordsTooMuch, $RetVal[2]
	$TargetFile = _DecToLittleEndian($MftRef)
	$TargetFileDec = Dec(_SwapEndian($TargetFile),2)
	$tBuffer = DllStructCreate("byte[" & $MFT_Record_Size & "]")
	$hFile = _WinAPI_CreateFile("\\.\" & $TargetDevice, 2, 6, 6)
	If $hFile = 0 Then
		ConsoleWrite("Error in function CreateFile: " & _WinAPI_GetLastErrorMessage() & @CRLF)
		_WinAPI_CloseHandle($hFile)
		Return SetError(1,0,0)
	EndIf
;	_ArrayDisplay($SplitMftRecArr,"$SplitMftRecArr")
	$RecordSplitIndex = _IsMftRecordSplit($MftRef)
	If $RecordSplitIndex Then
		ConsoleWrite("Error: Ref " & $MftRef & " has its record split across 2 dataruns" & @CRLF)
		_WinAPI_CloseHandle($hFile)
		Return ""
		;For now we don't attempt at split records, although its possible
		$SplitRecordPart2 = $SplitMftRecArr[$RecordSplitIndex]
		$SplitRecordTestRef = StringMid($SplitRecordPart2, 1, StringInStr($SplitRecordPart2, "?")-1)
		If $SplitRecordTestRef <> $MftRef Then ;then something is not quite right
			ConsoleWrite("Error: The ref in the array did not match target ref." & @CRLF)
			Return
		EndIf
		$SplitRecordPart3 = StringMid($SplitRecordPart2, StringInStr($SplitRecordPart2, "?")+1)
		$SplitRecordArr = StringSplit($SplitRecordPart3,"|")
		If UBound($SplitRecordArr) <> 3 Then
			ConsoleWrite("Error: Array contained more elements than expected: " & UBound($SplitRecordArr) & @CRLF)
			Return
		EndIf
		$record="0x"
		For $k = 1 To Ubound($SplitRecordArr)-1
			$SplitRecordOffset = StringMid($SplitRecordArr[$k], 1, StringInStr($SplitRecordArr[$k], ",")-1)
			$SplitRecordSize = StringMid($SplitRecordArr[$k], StringInStr($SplitRecordArr[$k], ",")+1)
			_WinAPI_SetFilePointerEx($hFile, $ImageOffset+$SplitRecordOffset, $FILE_BEGIN)
			$kBuffer = DllStructCreate("byte["&$SplitRecordSize&"]")
			_WinAPI_ReadFile($hFile, DllStructGetPtr($kBuffer), $SplitRecordSize, $nBytes)
			$record &= StringMid(DllStructGetData($kBuffer,1),3)
			ConsoleWrite("	part " & $k & " of record has " & $SplitRecordSize & " bytes at raw offset 0x" & Hex(Int($ImageOffset+$SplitRecordOffset)) & @CRLF)
			$kBuffer=0
		Next
;		ConsoleWrite(_HexEncode($record) & @CRLF)
	Else
		Local $RecordsDivisor = $MFT_Record_Size/512
		For $i = 1 To UBound($MFT_RUN_Clusters)-1
			$CurrentClusters = $MFT_RUN_Clusters[$i]
			$RecordsInCurrentRun = ($CurrentClusters*$SectorsPerCluster)/$RecordsDivisor
			$Counter+=$RecordsInCurrentRun
			If $Counter>$TargetFileDec Then
				ExitLoop
			EndIf
		Next
		$TryAt = $Counter-$RecordsInCurrentRun
		$TryAtArrIndex = $i
		$RecordsPerCluster = $SectorsPerCluster/$RecordsDivisor
		Do
			$RecordJumper+=$RecordsPerCluster
			$Counter2+=1
			$Final = $TryAt+$RecordJumper
		Until $Final>=$TargetFileDec
		$RecordsTooMuch = $Final-$TargetFileDec
		_WinAPI_SetFilePointerEx($hFile, $ImageOffset+$MFT_RUN_VCN[$i]*$BytesPerCluster+($Counter2*$BytesPerCluster)-($RecordsTooMuch*$MFT_Record_Size), $FILE_BEGIN)
		_WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer), $MFT_Record_Size, $nBytes)
		$record = DllStructGetData($tBuffer, 1)
		$TmpOffset = DllCall('kernel32.dll', 'int', 'SetFilePointerEx', 'ptr', $hFile, 'int64', 0, 'int64*', 0, 'dword', 1)
;		ConsoleWrite("Record number: " & $MftRef & " found at disk offset: " & $TmpOffset[3]-$MFT_Record_Size & " -> 0x" & Hex(Int($TmpOffset[3]-$MFT_Record_Size)) & @CRLF)
	EndIf
	If StringMid($record,91,8) = $TargetFile Then
		$TmpOffset = DllCall('kernel32.dll', 'int', 'SetFilePointerEx', 'ptr', $hFile, 'int64', 0, 'int64*', 0, 'dword', 1)
		_WinAPI_CloseHandle($hFile)
		$FoundOffset = Int($TmpOffset[3])-Int($MFT_Record_Size)
		$RetVal[0] = $FoundOffset
		$RetVal[1] = $record
		Return $RetVal
	Else
		If StringMid($record,11,2) = "2A" Then
			ConsoleWrite("Old style NT record not supported" & @CRLF)
		EndIf
		ConsoleWrite("Error wrong ref: " & StringMid($record,91,8) & @CRLF)
		_WinAPI_CloseHandle($hFile)
		Return ""
	EndIf
EndFunc

Func _FindMFT($TargetDevice,$TargetFile)
	Local $nBytes;, $MFT_Record_Size=1024
	$tBuffer = DllStructCreate("byte[" & $MFT_Record_Size & "]")
	$hFile = _WinAPI_CreateFile("\\.\" & $TargetDevice, 2, 2, 7)
	If $hFile = 0 Then
		ConsoleWrite("Error CreateFile in function _FindMFT(): " & _WinAPI_GetLastErrorMessage() & " for " & $TargetDevice & @CRLF)
		Return SetError(1,0,0)
	EndIf
	_WinAPI_SetFilePointerEx($hFile, $ImageOffset+$MFT_Offset, $FILE_BEGIN)
	_WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer), $MFT_Record_Size, $nBytes)
	_WinAPI_CloseHandle($hFile)
	$record = DllStructGetData($tBuffer, 1)
	If NOT StringMid($record,1,8) = '46494C45' Then
		ConsoleWrite("MFT record signature not found. "& @crlf)
		Return ""
	EndIf
	If StringMid($record,47,4) = "0100" AND Dec(_SwapEndian(StringMid($record,91,8))) = $TargetFile Then
;		ConsoleWrite("MFT record found" & @CRLF)
		Return $record		;returns record for MFT
	EndIf
	ConsoleWrite("MFT record not found" & @CRLF)
	Return ""
EndFunc

Func _DecToLittleEndian($DecimalInput)
	Return _SwapEndian(Hex($DecimalInput,8))
EndFunc


Func _UnicodeHexToStr($FileName)
	$str = ""
	For $i = 1 To StringLen($FileName) Step 4
		$str &= ChrW(Dec(_SwapEndian(StringMid($FileName, $i, 4))))
	Next
	Return $str
EndFunc

Func _DebugOut($text, $var)
	ConsoleWrite("Debug output for " & $text & @CRLF)
	For $i=1 To StringLen($var) Step 32
		$str=""
		For $n=0 To 15
			$str &= StringMid($var, $i+$n*2, 2) & " "
			if $n=7 then $str &= "- "
		Next
		ConsoleWrite($str & @CRLF)
	Next
EndFunc

Func _ReadBootSector($TargetDevice)
	Local $nbytes
	$tBuffer=DllStructCreate("byte[512]")
	$hFile = _WinAPI_CreateFile("\\.\" & $TargetDevice,2,2,7)
	If $hFile = 0 then
		ConsoleWrite("Error CreateFile in function _ReadBootSector(): " & _WinAPI_GetLastErrorMessage() & " for: " & "\\.\" & $TargetDevice & @crlf)
		Return SetError(1,0,0)
	EndIf
	_WinAPI_SetFilePointerEx($hFile, $ImageOffset, $FILE_BEGIN)
	$read = _WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer), 512, $nBytes)
	If $read = 0 then
		ConsoleWrite("Error in function ReadFile: " & _WinAPI_GetLastErrorMessage() & " for: " & "\\.\" & $TargetDevice & @crlf)
		Return SetError(1,0,0)
	EndIf
	_WinAPI_CloseHandle($hFile)
   ; Good starting point from KaFu & trancexx at the AutoIt forum
	$tBootSectorSections = DllStructCreate("align 1;" & _
								"byte Jump[3];" & _
								"char SystemName[8];" & _
								"ushort BytesPerSector;" & _
								"ubyte SectorsPerCluster;" & _
								"ushort ReservedSectors;" & _
								"ubyte[3];" & _
								"ushort;" & _
								"ubyte MediaDescriptor;" & _
								"ushort;" & _
								"ushort SectorsPerTrack;" & _
								"ushort NumberOfHeads;" & _
								"dword HiddenSectors;" & _
								"dword;" & _
								"dword;" & _
								"int64 TotalSectors;" & _
								"int64 LogicalClusterNumberforthefileMFT;" & _
								"int64 LogicalClusterNumberforthefileMFTMirr;" & _
								"dword ClustersPerFileRecordSegment;" & _
								"dword ClustersPerIndexBlock;" & _
								"int64 NTFSVolumeSerialNumber;" & _
								"dword Checksum", DllStructGetPtr($tBuffer))
	If Not DllStructGetData($tBootSectorSections, "SystemName") = "NTFS" Then Return SetError(1,0,0)
	$BytesPerSector = DllStructGetData($tBootSectorSections, "BytesPerSector")
	$SectorsPerCluster = DllStructGetData($tBootSectorSections, "SectorsPerCluster")
	$BytesPerCluster = $BytesPerSector * $SectorsPerCluster
	$ClustersPerFileRecordSegment = DllStructGetData($tBootSectorSections, "ClustersPerFileRecordSegment")
	$LogicalClusterNumberforthefileMFT = DllStructGetData($tBootSectorSections, "LogicalClusterNumberforthefileMFT")
	$MFT_Offset = $BytesPerCluster * $LogicalClusterNumberforthefileMFT
	If $ClustersPerFileRecordSegment > 127 Then
		$MFT_Record_Size = 2 ^ (256 - $ClustersPerFileRecordSegment)
	Else
		$MFT_Record_Size = $BytesPerCluster * $ClustersPerFileRecordSegment
	EndIf
	$MFT_Record_Size=Int($MFT_Record_Size)
	$ClustersPerFileRecordSegment = Ceiling($MFT_Record_Size/$BytesPerCluster)
EndFunc

Func _HexEncode($bInput)
    Local $tInput = DllStructCreate("byte[" & BinaryLen($bInput) & "]")
    DllStructSetData($tInput, 1, $bInput)
    Local $a_iCall = DllCall("crypt32.dll", "int", "CryptBinaryToString", _
            "ptr", DllStructGetPtr($tInput), _
            "dword", DllStructGetSize($tInput), _
            "dword", 11, _
            "ptr", 0, _
            "dword*", 0)

    If @error Or Not $a_iCall[0] Then
        Return SetError(1, 0, "")
    EndIf

    Local $iSize = $a_iCall[5]
    Local $tOut = DllStructCreate("char[" & $iSize & "]")

    $a_iCall = DllCall("crypt32.dll", "int", "CryptBinaryToString", _
            "ptr", DllStructGetPtr($tInput), _
            "dword", DllStructGetSize($tInput), _
            "dword", 11, _
            "ptr", DllStructGetPtr($tOut), _
            "dword*", $iSize)

    If @error Or Not $a_iCall[0] Then
        Return SetError(2, 0, "")
    EndIf

    Return SetError(0, 0, DllStructGetData($tOut, 1))

EndFunc  ;==>_HexEncode

Func _File_Attributes($FAInput)
	Local $FAOutput = ""
	If BitAND($FAInput, 0x0001) Then $FAOutput &= 'read_only+'
	If BitAND($FAInput, 0x0002) Then $FAOutput &= 'hidden+'
	If BitAND($FAInput, 0x0004) Then $FAOutput &= 'system+'
	If BitAND($FAInput, 0x0010) Then $FAOutput &= 'directory+'
	If BitAND($FAInput, 0x0020) Then $FAOutput &= 'archive+'
	If BitAND($FAInput, 0x0040) Then $FAOutput &= 'device+'
	If BitAND($FAInput, 0x0080) Then $FAOutput &= 'normal+'
	If BitAND($FAInput, 0x0100) Then $FAOutput &= 'temporary+'
	If BitAND($FAInput, 0x0200) Then $FAOutput &= 'sparse_file+'
	If BitAND($FAInput, 0x0400) Then $FAOutput &= 'reparse_point+'
	If BitAND($FAInput, 0x0800) Then $FAOutput &= 'compressed+'
	If BitAND($FAInput, 0x1000) Then $FAOutput &= 'offline+'
	If BitAND($FAInput, 0x2000) Then $FAOutput &= 'not_indexed+'
	If BitAND($FAInput, 0x4000) Then $FAOutput &= 'encrypted+'
	If BitAND($FAInput, 0x8000) Then $FAOutput &= 'integrity_stream+'
	If BitAND($FAInput, 0x10000) Then $FAOutput &= 'virtual+'
	If BitAND($FAInput, 0x20000) Then $FAOutput &= 'no_scrub_data+'
	If BitAND($FAInput, 0x10000000) Then $FAOutput &= 'directory+'
	If BitAND($FAInput, 0x20000000) Then $FAOutput &= 'index_view+'
	$FAOutput = StringTrimRight($FAOutput, 1)
	Return $FAOutput
EndFunc

Func _End($begin)
	Local $timerdiff = TimerDiff($begin)
	$timerdiff = Round(($timerdiff / 1000), 2)
	ConsoleWrite(@CRLF & "Job took " & $timerdiff & " seconds" & @CRLF)
EndFunc

Func _ExtractFile($record)
	$cBuffer = DllStructCreate("byte[" & $BytesPerCluster * 16 & "]")
    $zflag = 0
	$hFile = _WinAPI_CreateFile($AttributeOutFileName,3,6,7)
	If $hFile Then
		Select
			Case UBound($RUN_VCN) = 1		;no data, do nothing
			Case UBound($RUN_VCN) = 2 	;may be normal or sparse
				If $RUN_VCN[1] = 0 And $IsSparse Then		;sparse
					$FileSize = _DoSparse(1, $hFile, $DATA_InitSize)
				Else								;normal
					$FileSize = _DoNormal(1, $hFile, $cBuffer, $DATA_InitSize)
				EndIf
		    Case Else					;may be compressed
				_DoCompressed($hFile, $cBuffer, $record)
		EndSelect
		If $DATA_RealSize > $DATA_InitSize Then
		    $FileSize = _WriteZeros($hfile, $DATA_RealSize - $DATA_InitSize)
		EndIf
		_WinAPI_CloseHandle($hFile)
		Return
	Else
		ConsoleWrite("Error creating output file: " & _WinAPI_GetLastErrorMessage() & @CRLF)
	EndIf
EndFunc

Func _WriteZeros($hfile, $count)
   Local $nBytes
   If Not IsDllStruct($sBuffer) Then _CreateSparseBuffer()
   While $count > $BytesPerCluster * 16
	  _WinAPI_WriteFile($hFile, DllStructGetPtr($sBuffer), $BytesPerCluster * 16, $nBytes)
	  $count -= $BytesPerCluster * 16
	  $ProgressSize = $DATA_RealSize - $count
   WEnd
   If $count <> 0 Then _WinAPI_WriteFile($hFile, DllStructGetPtr($sBuffer), $count, $nBytes)
   $ProgressSize = $DATA_RealSize
   Return 0
EndFunc

Func _DoCompressed($hFile, $cBuffer, $record)
   Local $nBytes
   $r=1
   $FileSize = $DATA_InitSize
   $ProgressSize = $FileSize
   Do
	  _WinAPI_SetFilePointerEx($hDisk, $ImageOffset+$RUN_VCN[$r]*$BytesPerCluster, $FILE_BEGIN)
	  $i = $RUN_Clusters[$r]
	  If (($RUN_VCN[$r+1]=0) And ($i+$RUN_Clusters[$r+1]=16) And $IsCompressed) Then
		 _WinAPI_ReadFile($hDisk, DllStructGetPtr($cBuffer), $BytesPerCluster * $i, $nBytes)
		 $Decompressed = _LZNTDecompress($cBuffer, $BytesPerCluster * $i)
		 If IsString($Decompressed) Then
			If $r = 1 Then
			   _DebugOut("Decompression error for " & $ADS_Name, $record)
			Else
			   _DebugOut("Decompression error (partial write) for " & $ADS_Name, $record)
			EndIf
			Return
		 Else		;$Decompressed is an array
			Local $dBuffer = DllStructCreate("byte[" & $Decompressed[1] & "]")
			DllStructSetData($dBuffer, 1, $Decompressed[0])
		 EndIf
		 If $FileSize > $Decompressed[1] Then
			_WinAPI_WriteFile($hFile, DllStructGetPtr($dBuffer), $Decompressed[1], $nBytes)
			$FileSize -= $Decompressed[1]
			$ProgressSize = $FileSize
		 Else
			_WinAPI_WriteFile($hFile, DllStructGetPtr($dBuffer), $FileSize, $nBytes)
		 EndIf
		 $r += 1
	  ElseIf $RUN_VCN[$r]=0 Then
		 $FileSize = _DoSparse($r, $hFile, $FileSize)
		 $ProgressSize = 0
	  Else
		 $FileSize = _DoNormal($r, $hFile, $cBuffer, $FileSize)
		 $ProgressSize = 0
	  EndIf
	  $r += 1
   Until $r > UBound($RUN_VCN)-2
   If $r = UBound($RUN_VCN)-1 Then
	  If $RUN_VCN[$r]=0 Then
		 $FileSize = _DoSparse($r, $hFile, $FileSize)
		 $ProgressSize = 0
	  Else
		 $FileSize = _DoNormal($r, $hFile, $cBuffer, $FileSize)
		 $ProgressSize = 0
	  EndIf
   EndIf
EndFunc

Func _DoNormal($r, $hFile, $cBuffer, $FileSize)
   Local $nBytes
   _WinAPI_SetFilePointerEx($hDisk, $ImageOffset+$RUN_VCN[$r]*$BytesPerCluster, $FILE_BEGIN)
   $i = $RUN_Clusters[$r]
   While $i > 16 And $FileSize > $BytesPerCluster * 16
	  _WinAPI_ReadFile($hDisk, DllStructGetPtr($cBuffer), $BytesPerCluster * 16, $nBytes)
	  _WinAPI_WriteFile($hFile, DllStructGetPtr($cBuffer), $BytesPerCluster * 16, $nBytes)
	  $i -= 16
	  $FileSize -= $BytesPerCluster * 16
	  $ProgressSize = $FileSize
   WEnd
   If $i = 0 Or $FileSize = 0 Then Return $FileSize
   If $i > 16 Then $i = 16
   _WinAPI_ReadFile($hDisk, DllStructGetPtr($cBuffer), $BytesPerCluster * $i, $nBytes)
   If $FileSize > $BytesPerCluster * $i Then
	  _WinAPI_WriteFile($hFile, DllStructGetPtr($cBuffer), $BytesPerCluster * $i, $nBytes)
	  $FileSize -= $BytesPerCluster * $i
	  $ProgressSize = $FileSize
	  Return $FileSize
   Else
	  _WinAPI_WriteFile($hFile, DllStructGetPtr($cBuffer), $FileSize, $nBytes)
	  $ProgressSize = 0
	  Return 0
   EndIf
EndFunc

Func _DoSparse($r,$hFile,$FileSize)
   Local $nBytes
   If Not IsDllStruct($sBuffer) Then _CreateSparseBuffer()
   $i = $RUN_Clusters[$r]
   While $i > 16 And $FileSize > $BytesPerCluster * 16
	 _WinAPI_WriteFile($hFile, DllStructGetPtr($sBuffer), $BytesPerCluster * 16, $nBytes)
	 $i -= 16
	 $FileSize -= $BytesPerCluster * 16
	 $ProgressSize = $FileSize
   WEnd
   If $i <> 0 Then
 	 If $FileSize > $BytesPerCluster * $i Then
		_WinAPI_WriteFile($hFile, DllStructGetPtr($sBuffer), $BytesPerCluster * $i, $nBytes)
		$FileSize -= $BytesPerCluster * $i
		$ProgressSize = $FileSize
	 Else
		_WinAPI_WriteFile($hFile, DllStructGetPtr($sBuffer), $FileSize, $nBytes)
		$ProgressSize = 0
		Return 0
	 EndIf
   EndIf
   Return $FileSize
EndFunc

Func _CreateSparseBuffer()
   Global $sBuffer = DllStructCreate("byte[" & $BytesPerCluster * 16 & "]")
   For $i = 1 To $BytesPerCluster * 16
	  DllStructSetData ($sBuffer, $i, 0)
   Next
EndFunc

Func _LZNTDecompress($tInput, $Size)	;note function returns a null string if error, or an array if no error
	Local $tOutput[2]
	Local $cBuffer = DllStructCreate("byte[" & $BytesPerCluster*16 & "]")
    Local $a_Call = DllCall("ntdll.dll", "int", "RtlDecompressBuffer", _
            "ushort", 2, _
            "ptr", DllStructGetPtr($cBuffer), _
            "dword", DllStructGetSize($cBuffer), _
            "ptr", DllStructGetPtr($tInput), _
            "dword", $Size, _
            "dword*", 0)

    If @error Or $a_Call[0] Then	;if $a_Call[0]=0 then output size is in $a_Call[6], otherwise $a_Call[6] is invalid
        Return SetError(1, 0, "") ; error decompressing
    EndIf
    Local $Decompressed = DllStructCreate("byte[" & $a_Call[6] & "]", DllStructGetPtr($cBuffer))
	$tOutput[0] = DllStructGetData($Decompressed, 1)
	$tOutput[1] = $a_Call[6]
    Return SetError(0, 0, $tOutput)
EndFunc

Func _ExtractResidentFile($Name, $Size, $record)
	Local $nBytes
	$xBuffer = DllStructCreate("byte[" & $Size & "]")
    DllStructSetData($xBuffer, 1, '0x' & $DataRun)
	$hFile = _WinAPI_CreateFile($Name,3,6,7)
	If $hFile Then
		_WinAPI_SetFilePointer($hFile, 0,$FILE_BEGIN)
		_WinAPI_WriteFile($hFile, DllStructGetPtr($xBuffer), $Size, $nBytes)
		_WinAPI_CloseHandle($hFile)
		Return
	Else
		ConsoleWrite("Error" & @CRLF)
	EndIf
EndFunc

Func _TranslateAttributeType($input)
	Local $RetVal
	Select
		Case $input = $STANDARD_INFORMATION
			$RetVal = "$STANDARD_INFORMATION"
		Case $input = $ATTRIBUTE_LIST
			$RetVal = "$ATTRIBUTE_LIST"
		Case $input = $FILE_NAME
			$RetVal = "$FILE_NAME"
		Case $input = $OBJECT_ID
			$RetVal = "$OBJECT_ID"
		Case $input = $SECURITY_DESCRIPTOR
			$RetVal = "$SECURITY_DESCRIPTOR"
		Case $input = $VOLUME_NAME
			$RetVal = "$VOLUME_NAME"
		Case $input = $VOLUME_INFORMATION
			$RetVal = "$VOLUME_INFORMATION"
		Case $input = $DATA
			$RetVal = "$DATA"
		Case $input = $INDEX_ROOT
			$RetVal = "$INDEX_ROOT"
		Case $input = $INDEX_ALLOCATION
			$RetVal = "$INDEX_ALLOCATION"
		Case $input = $BITMAP
			$RetVal = "$BITMAP"
		Case $input = $REPARSE_POINT
			$RetVal = "$REPARSE_POINT"
		Case $input = $EA_INFORMATION
			$RetVal = "$EA_INFORMATION"
		Case $input = $EA
			$RetVal = "$EA"
		Case $input = $PROPERTY_SET
			$RetVal = "$PROPERTY_SET"
		Case $input = $LOGGED_UTILITY_STREAM
			$RetVal = "$LOGGED_UTILITY_STREAM"
		Case $input = $ATTRIBUTE_END_MARKER
			$RetVal = "$ATTRIBUTE_END_MARKER"
	EndSelect
	Return $RetVal
EndFunc

Func NT_SUCCESS($status)
    If 0 <= $status And $status <= 0x7FFFFFFF Then
        Return True
    Else
        Return False
    EndIf
EndFunc

Func _GetAttributeEntry($TargetDevice,$Entry)
	Local $CoreAttribute,$CoreAttributeTmp,$CoreAttributeArr[2],$TestArray,$Bytes
	Local $ATTRIBUTE_HEADER_Length,$ATTRIBUTE_HEADER_NonResidentFlag,$ATTRIBUTE_HEADER_NameLength,$ATTRIBUTE_HEADER_NameRelativeOffset,$ATTRIBUTE_HEADER_Name,$ATTRIBUTE_HEADER_Flags,$ATTRIBUTE_HEADER_AttributeID,$ATTRIBUTE_HEADER_StartVCN,$ATTRIBUTE_HEADER_LastVCN
	Local $ATTRIBUTE_HEADER_VCNs,$ATTRIBUTE_HEADER_OffsetToDataRuns,$ATTRIBUTE_HEADER_CompressionUnitSize,$ATTRIBUTE_HEADER_Padding,$ATTRIBUTE_HEADER_AllocatedSize,$ATTRIBUTE_HEADER_RealSize,$ATTRIBUTE_HEADER_InitializedStreamSize,$RunListOffset
	Local $ATTRIBUTE_HEADER_LengthOfAttribute,$ATTRIBUTE_HEADER_OffsetToAttribute,$ATTRIBUTE_HEADER_IndexedFlag
	If $IsCurrentIndxOfParent Then Global $RawOffsetIndxArray
	$ATTRIBUTE_HEADER_Length = StringMid($Entry,9,8)
	$ATTRIBUTE_HEADER_Length = Dec(StringMid($ATTRIBUTE_HEADER_Length,7,2) & StringMid($ATTRIBUTE_HEADER_Length,5,2) & StringMid($ATTRIBUTE_HEADER_Length,3,2) & StringMid($ATTRIBUTE_HEADER_Length,1,2))
	$ATTRIBUTE_HEADER_NonResidentFlag = StringMid($Entry,17,2)
;	ConsoleWrite("$ATTRIBUTE_HEADER_NonResidentFlag = " & $ATTRIBUTE_HEADER_NonResidentFlag & @crlf)
	$ATTRIBUTE_HEADER_NameLength = Dec(StringMid($Entry,19,2))
;	ConsoleWrite("$ATTRIBUTE_HEADER_NameLength = " & $ATTRIBUTE_HEADER_NameLength & @crlf)
	$ATTRIBUTE_HEADER_NameRelativeOffset = StringMid($Entry,21,4)
;	ConsoleWrite("$ATTRIBUTE_HEADER_NameRelativeOffset = " & $ATTRIBUTE_HEADER_NameRelativeOffset & @crlf)
	$ATTRIBUTE_HEADER_NameRelativeOffset = Dec(_SwapEndian($ATTRIBUTE_HEADER_NameRelativeOffset))
;	ConsoleWrite("$ATTRIBUTE_HEADER_NameRelativeOffset = " & $ATTRIBUTE_HEADER_NameRelativeOffset & @crlf)
	If $ATTRIBUTE_HEADER_NameLength > 0 Then
		$ATTRIBUTE_HEADER_Name = _UnicodeHexToStr(StringMid($Entry,$ATTRIBUTE_HEADER_NameRelativeOffset*2 + 1,$ATTRIBUTE_HEADER_NameLength*4))
	Else
		$ATTRIBUTE_HEADER_Name = ""
	EndIf
	$ATTRIBUTE_HEADER_Flags = _SwapEndian(StringMid($Entry,25,4))
;	ConsoleWrite("$ATTRIBUTE_HEADER_Flags = " & $ATTRIBUTE_HEADER_Flags & @crlf)
	$Flags = ""
	If $ATTRIBUTE_HEADER_Flags = "0000" Then
		$Flags = "NORMAL"
	Else
		If BitAND($ATTRIBUTE_HEADER_Flags,"0001") Then
			$IsCompressed = 1
			$Flags &= "COMPRESSED+"
		EndIf
		If BitAND($ATTRIBUTE_HEADER_Flags,"4000") Then
			$IsEncrypted = 1
			$Flags &= "ENCRYPTED+"
		EndIf
		If BitAND($ATTRIBUTE_HEADER_Flags,"8000") Then
			$IsSparse = 1
			$Flags &= "SPARSE+"
		EndIf
		$Flags = StringTrimRight($Flags,1)
	EndIf
;	ConsoleWrite("File is " & $Flags & @CRLF)
	$ATTRIBUTE_HEADER_AttributeID = StringMid($Entry,29,4)
	$ATTRIBUTE_HEADER_AttributeID = StringMid($ATTRIBUTE_HEADER_AttributeID,3,2) & StringMid($ATTRIBUTE_HEADER_AttributeID,1,2)
	If $ATTRIBUTE_HEADER_NonResidentFlag = '01' Then
		$ATTRIBUTE_HEADER_StartVCN = StringMid($Entry,33,16)
;		ConsoleWrite("$ATTRIBUTE_HEADER_StartVCN = " & $ATTRIBUTE_HEADER_StartVCN & @crlf)
		$ATTRIBUTE_HEADER_StartVCN = Dec(_SwapEndian($ATTRIBUTE_HEADER_StartVCN),2)
;		ConsoleWrite("$ATTRIBUTE_HEADER_StartVCN = " & $ATTRIBUTE_HEADER_StartVCN & @crlf)
		$ATTRIBUTE_HEADER_LastVCN = StringMid($Entry,49,16)
;		ConsoleWrite("$ATTRIBUTE_HEADER_LastVCN = " & $ATTRIBUTE_HEADER_LastVCN & @crlf)
		$ATTRIBUTE_HEADER_LastVCN = Dec(_SwapEndian($ATTRIBUTE_HEADER_LastVCN),2)
;		ConsoleWrite("$ATTRIBUTE_HEADER_LastVCN = " & $ATTRIBUTE_HEADER_LastVCN & @crlf)
		$ATTRIBUTE_HEADER_VCNs = $ATTRIBUTE_HEADER_LastVCN - $ATTRIBUTE_HEADER_StartVCN
;		ConsoleWrite("$ATTRIBUTE_HEADER_VCNs = " & $ATTRIBUTE_HEADER_VCNs & @crlf)
		$ATTRIBUTE_HEADER_OffsetToDataRuns = StringMid($Entry,65,4)
		$ATTRIBUTE_HEADER_OffsetToDataRuns = Dec(StringMid($ATTRIBUTE_HEADER_OffsetToDataRuns,3,1) & StringMid($ATTRIBUTE_HEADER_OffsetToDataRuns,3,1))
		$ATTRIBUTE_HEADER_CompressionUnitSize = Dec(_SwapEndian(StringMid($Entry,69,4)))
;		ConsoleWrite("$ATTRIBUTE_HEADER_CompressionUnitSize = " & $ATTRIBUTE_HEADER_CompressionUnitSize & @crlf)
		$IsCompressed = 0
		If $ATTRIBUTE_HEADER_CompressionUnitSize = 4 Then $IsCompressed = 1
		$ATTRIBUTE_HEADER_Padding = StringMid($Entry,73,8)
		$ATTRIBUTE_HEADER_Padding = StringMid($ATTRIBUTE_HEADER_Padding,7,2) & StringMid($ATTRIBUTE_HEADER_Padding,5,2) & StringMid($ATTRIBUTE_HEADER_Padding,3,2) & StringMid($ATTRIBUTE_HEADER_Padding,1,2)
		$ATTRIBUTE_HEADER_AllocatedSize = StringMid($Entry,81,16)
;		ConsoleWrite("$ATTRIBUTE_HEADER_AllocatedSize = " & $ATTRIBUTE_HEADER_AllocatedSize & @crlf)
		$ATTRIBUTE_HEADER_AllocatedSize = Dec(_SwapEndian($ATTRIBUTE_HEADER_AllocatedSize),2)
;		ConsoleWrite("$ATTRIBUTE_HEADER_AllocatedSize = " & $ATTRIBUTE_HEADER_AllocatedSize & @crlf)
		$ATTRIBUTE_HEADER_RealSize = StringMid($Entry,97,16)
;		ConsoleWrite("$ATTRIBUTE_HEADER_RealSize = " & $ATTRIBUTE_HEADER_RealSize & @crlf)
		$ATTRIBUTE_HEADER_RealSize = Dec(_SwapEndian($ATTRIBUTE_HEADER_RealSize),2)
;		ConsoleWrite("$ATTRIBUTE_HEADER_RealSize = " & $ATTRIBUTE_HEADER_RealSize & @crlf)
		$ATTRIBUTE_HEADER_InitializedStreamSize = StringMid($Entry,113,16)
;		ConsoleWrite("$ATTRIBUTE_HEADER_InitializedStreamSize = " & $ATTRIBUTE_HEADER_InitializedStreamSize & @crlf)
		$ATTRIBUTE_HEADER_InitializedStreamSize = Dec(_SwapEndian($ATTRIBUTE_HEADER_InitializedStreamSize),2)
;		ConsoleWrite("$ATTRIBUTE_HEADER_InitializedStreamSize = " & $ATTRIBUTE_HEADER_InitializedStreamSize & @crlf)
		$RunListOffset = StringMid($Entry,65,4)
;		ConsoleWrite("$RunListOffset = " & $RunListOffset & @crlf)
		$RunListOffset = Dec(_SwapEndian($RunListOffset))
;		ConsoleWrite("$RunListOffset = " & $RunListOffset & @crlf)
		If $IsCompressed AND $RunListOffset = 72 Then
			$ATTRIBUTE_HEADER_CompressedSize = StringMid($Entry,129,16)
			$ATTRIBUTE_HEADER_CompressedSize = Dec(_SwapEndian($ATTRIBUTE_HEADER_CompressedSize),2)
		EndIf
		$DataRun = StringMid($Entry,$RunListOffset*2+1,(StringLen($Entry)-$RunListOffset)*2)
;		ConsoleWrite("$DataRun = " & $DataRun & @crlf)
	ElseIf $ATTRIBUTE_HEADER_NonResidentFlag = '00' Then
		$ATTRIBUTE_HEADER_LengthOfAttribute = StringMid($Entry,33,8)
;		ConsoleWrite("$ATTRIBUTE_HEADER_LengthOfAttribute = " & $ATTRIBUTE_HEADER_LengthOfAttribute & @crlf)
		$ATTRIBUTE_HEADER_LengthOfAttribute = Dec(_SwapEndian($ATTRIBUTE_HEADER_LengthOfAttribute),2)
;		ConsoleWrite("$ATTRIBUTE_HEADER_LengthOfAttribute = " & $ATTRIBUTE_HEADER_LengthOfAttribute & @crlf)
;		$ATTRIBUTE_HEADER_OffsetToAttribute = StringMid($Entry,41,4)
;		$ATTRIBUTE_HEADER_OffsetToAttribute = Dec(StringMid($ATTRIBUTE_HEADER_OffsetToAttribute,3,2) & StringMid($ATTRIBUTE_HEADER_OffsetToAttribute,1,2))
		$ATTRIBUTE_HEADER_OffsetToAttribute = Dec(_SwapEndian(StringMid($Entry,41,4)))
;		ConsoleWrite("$ATTRIBUTE_HEADER_OffsetToAttribute = " & $ATTRIBUTE_HEADER_OffsetToAttribute & @crlf)
		$ATTRIBUTE_HEADER_IndexedFlag = Dec(StringMid($Entry,45,2))
		$ATTRIBUTE_HEADER_Padding = StringMid($Entry,47,2)
		$DataRun = StringMid($Entry,$ATTRIBUTE_HEADER_OffsetToAttribute*2+1,$ATTRIBUTE_HEADER_LengthOfAttribute*2)
;		ConsoleWrite("$DataRun = " & $DataRun & @crlf)
	EndIf
; Possible continuation
;	For $i = 1 To UBound($DataQ) - 1
	For $i = 1 To 1
;		_DecodeDataQEntry($DataQ[$i])
		If $ATTRIBUTE_HEADER_NonResidentFlag = '00' Then
;_ExtractResidentFile($DATA_Name, $DATA_LengthOfAttribute)
			$CoreAttribute = $DataRun
		Else
			Global $RUN_VCN[1], $RUN_Clusters[1]

			$TotalClusters = $ATTRIBUTE_HEADER_LastVCN - $ATTRIBUTE_HEADER_StartVCN + 1
			$Size = $ATTRIBUTE_HEADER_RealSize
;_ExtractDataRuns()
			$r=UBound($RUN_Clusters)
			$i=1
			$RUN_VCN[0] = 0
			$BaseVCN = $RUN_VCN[0]
			If $DataRun = "" Then $DataRun = "00"
			Do
				$RunListID = StringMid($DataRun,$i,2)
				If $RunListID = "00" Then ExitLoop
;				ConsoleWrite("$RunListID = " & $RunListID & @crlf)
				$i += 2
				$RunListClustersLength = Dec(StringMid($RunListID,2,1))
;				ConsoleWrite("$RunListClustersLength = " & $RunListClustersLength & @crlf)
				$RunListVCNLength = Dec(StringMid($RunListID,1,1))
;				ConsoleWrite("$RunListVCNLength = " & $RunListVCNLength & @crlf)
				$RunListClusters = Dec(_SwapEndian(StringMid($DataRun,$i,$RunListClustersLength*2)),2)
;				ConsoleWrite("$RunListClusters = " & $RunListClusters & @crlf)
				$i += $RunListClustersLength*2
				$RunListVCN = _SwapEndian(StringMid($DataRun, $i, $RunListVCNLength*2))
				;next line handles positive or negative move
				$BaseVCN += Dec($RunListVCN,2)-(($r>1) And (Dec(StringMid($RunListVCN,1,1))>7))*Dec(StringMid("10000000000000000",1,$RunListVCNLength*2+1),2)
				If $RunListVCN <> "" Then
					$RunListVCN = $BaseVCN
				Else
					$RunListVCN = 0			;$RUN_VCN[$r-1]		;0
				EndIf
;				ConsoleWrite("$RunListVCN = " & $RunListVCN & @crlf)
				If (($RunListVCN=0) And ($RunListClusters>16) And (Mod($RunListClusters,16)>0)) Then
				;If (($RunListVCN=$RUN_VCN[$r-1]) And ($RunListClusters>16) And (Mod($RunListClusters,16)>0)) Then
				;may be sparse section at end of Compression Signature
					_ArrayAdd($RUN_Clusters,Mod($RunListClusters,16))
					_ArrayAdd($RUN_VCN,$RunListVCN)
					$RunListClusters -= Mod($RunListClusters,16)
					$r += 1
				ElseIf (($RunListClusters>16) And (Mod($RunListClusters,16)>0)) Then
				;may be compressed data section at start of Compression Signature
					_ArrayAdd($RUN_Clusters,$RunListClusters-Mod($RunListClusters,16))
					_ArrayAdd($RUN_VCN,$RunListVCN)
					$RunListVCN += $RUN_Clusters[$r]
					$RunListClusters = Mod($RunListClusters,16)
					$r += 1
				EndIf
			;just normal or sparse data
				_ArrayAdd($RUN_Clusters,$RunListClusters)
				_ArrayAdd($RUN_VCN,$RunListVCN)
				$r += 1
				$i += $RunListVCNLength*2
			Until $i > StringLen($DataRun)
;--------------------------------_ExtractDataRuns()
;			_ArrayDisplay($RUN_Clusters,"$RUN_Clusters")
;			_ArrayDisplay($RUN_VCN,"$RUN_VCN")
			If $TotalClusters * $BytesPerCluster >= $Size Then
;				ConsoleWrite(_ArrayToString($RUN_VCN) & @CRLF)
;				ConsoleWrite(_ArrayToString($RUN_Clusters) & @CRLF)
;ExtractFile
				Local $nBytes
				$hFile = _WinAPI_CreateFile("\\.\" & $TargetDevice, 2, 6, 6)
				If $hFile = 0 Then
					ConsoleWrite("Error CreateFile in function _GetAttributeEntry()." & @CRLF)
					_WinAPI_CloseHandle($hFile)
					Return
				EndIf
				$tBuffer = DllStructCreate("byte[" & $BytesPerCluster * 16 & "]")
				Select
					Case UBound($RUN_VCN) = 1		;no data, do nothing
					Case (UBound($RUN_VCN) = 2) Or (Not $IsCompressed)	;may be normal or sparse
						If $RUN_VCN[1] = $RUN_VCN[0] And $DATA_Name <> "$Boot" Then		;sparse, unless $Boot
;							_DoSparse($htest)
							ConsoleWrite("Error: Sparse attributes not supported!!!" & @CRLF)
						Else								;normal
;							_DoNormalAttribute($hFile, $tBuffer)
;							Local $nBytes
							$FileSize = $ATTRIBUTE_HEADER_RealSize
							Local $TestArray[UBound($RUN_VCN)][4]
							$TestArray[0][0] = "Offset"
							$TestArray[0][1] = "Bytes Accumulated"
							$TestArray[0][2] = "Bytes per Run"
							$TestArray[0][3] = "Sectors per Run"
							For $s = 1 To UBound($RUN_VCN)-1
								;An attempt at preparing for INDX modification
								$TestArray[$s][0] = $RUN_VCN[$s]*$BytesPerCluster
								_WinAPI_SetFilePointerEx($hFile, $RUN_VCN[$s]*$BytesPerCluster, $FILE_BEGIN)
								$g = $RUN_Clusters[$s]
								While $g > 16 And $FileSize > $BytesPerCluster * 16
									$Bytes += $BytesPerCluster * 16 ;Did this impact negatively??
									_WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer), $BytesPerCluster * 16, $nBytes)
;									_WinAPI_WriteFile($htest, DllStructGetPtr($tBuffer), $BytesPerCluster * 16, $nBytes)
									$g -= 16
									$FileSize -= $BytesPerCluster * 16
									$CoreAttributeTmp = StringMid(DllStructGetData($tBuffer,1),3,$BytesPerCluster*16*2)
									$CoreAttribute &= $CoreAttributeTmp
								WEnd
								If $g <> 0 Then
									$Bytes += $BytesPerCluster * $g ;Did this impact negatively??
									_WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer), $BytesPerCluster * $g, $nBytes)
;									$CoreAttributeTmp = StringMid(DllStructGetData($tBuffer,1),3)
;									$CoreAttribute &= $CoreAttributeTmp
									If $FileSize > $BytesPerCluster * $g Then
;										_WinAPI_WriteFile($htest, DllStructGetPtr($tBuffer), $BytesPerCluster * $g, $nBytes)
										$FileSize -= $BytesPerCluster * $g
										$CoreAttributeTmp = StringMid(DllStructGetData($tBuffer,1),3,$BytesPerCluster*$g*2)
										$CoreAttribute &= $CoreAttributeTmp
									Else
;										_WinAPI_WriteFile($htest, DllStructGetPtr($tBuffer), $FileSize, $nBytes)
;										Return
										$CoreAttributeTmp = StringMid(DllStructGetData($tBuffer,1),3,$FileSize*2)
										$CoreAttribute &= $CoreAttributeTmp
									EndIf
								EndIf
								;An attempt at preparing for INDX modification
								$TestArray[$s][1] = $Bytes
							Next
;------------------_DoNormalAttribute()
						EndIf
					Case Else					;may be compressed
;						_DoCompressed($hFile, $htest, $tBuffer)
						ConsoleWrite("Error: Compressed attributes not supported!!!" & @CRLF)
				EndSelect
;------------------------ExtractFile
			EndIf
;-------------------------
		EndIf
	Next
	$CoreAttributeArr[0] = $CoreAttribute
	$CoreAttributeArr[1] = $ATTRIBUTE_HEADER_Name

	If $IsCurrentIndxOfParent And $ATTRIBUTE_HEADER_Name = "$I30" Then ;Generate the offset array for the INDX of the parent, if required
		$RawOffsetIndxArray = $TestArray
		For $i = 1 To UBound($RawOffsetIndxArray)-1
			If $i = 1 Then
				$RawOffsetIndxArray[$i][2] = $RawOffsetIndxArray[$i][1]
			Else
				$RawOffsetIndxArray[$i][2] = $RawOffsetIndxArray[$i][1] - $RawOffsetIndxArray[$i-1][1]
			EndIf
			$RawOffsetIndxArray[$i][3] = $RawOffsetIndxArray[$i][2]/512
		Next
;		_ArrayDisplay($RawOffsetIndxArray,"$RawOffsetIndxArray")
		$IsCurrentIndxOfParent=0
		$DoIndxOffsetArray=0
	EndIf
	Return $CoreAttributeArr
EndFunc

Func _GetAttributeEntryNoRead($TargetDevice,$Entry)
;	ConsoleWrite("_GetAttributeEntryNoRead()" & @crlf)
	Local $CoreAttribute,$CoreAttributeTmp,$CoreAttributeArr[2],$TestArray,$Bytes
	Local $ATTRIBUTE_HEADER_Length,$ATTRIBUTE_HEADER_NonResidentFlag,$ATTRIBUTE_HEADER_NameLength,$ATTRIBUTE_HEADER_NameRelativeOffset,$ATTRIBUTE_HEADER_Name,$ATTRIBUTE_HEADER_Flags,$ATTRIBUTE_HEADER_AttributeID,$ATTRIBUTE_HEADER_StartVCN,$ATTRIBUTE_HEADER_LastVCN
	Local $ATTRIBUTE_HEADER_VCNs,$ATTRIBUTE_HEADER_OffsetToDataRuns,$ATTRIBUTE_HEADER_CompressionUnitSize,$ATTRIBUTE_HEADER_Padding,$ATTRIBUTE_HEADER_AllocatedSize,$ATTRIBUTE_HEADER_RealSize,$ATTRIBUTE_HEADER_InitializedStreamSize,$RunListOffset
	Local $ATTRIBUTE_HEADER_LengthOfAttribute,$ATTRIBUTE_HEADER_OffsetToAttribute,$ATTRIBUTE_HEADER_IndexedFlag
	Global $RawTestOffsetArray

	$ATTRIBUTE_HEADER_Length = StringMid($Entry,9,8)
	$ATTRIBUTE_HEADER_Length = Dec(StringMid($ATTRIBUTE_HEADER_Length,7,2) & StringMid($ATTRIBUTE_HEADER_Length,5,2) & StringMid($ATTRIBUTE_HEADER_Length,3,2) & StringMid($ATTRIBUTE_HEADER_Length,1,2))
	$ATTRIBUTE_HEADER_NonResidentFlag = StringMid($Entry,17,2)
;	ConsoleWrite("$ATTRIBUTE_HEADER_NonResidentFlag = " & $ATTRIBUTE_HEADER_NonResidentFlag & @crlf)
	$ATTRIBUTE_HEADER_NameLength = Dec(StringMid($Entry,19,2))
;	ConsoleWrite("$ATTRIBUTE_HEADER_NameLength = " & $ATTRIBUTE_HEADER_NameLength & @crlf)
	$ATTRIBUTE_HEADER_NameRelativeOffset = StringMid($Entry,21,4)
;	ConsoleWrite("$ATTRIBUTE_HEADER_NameRelativeOffset = " & $ATTRIBUTE_HEADER_NameRelativeOffset & @crlf)
	$ATTRIBUTE_HEADER_NameRelativeOffset = Dec(_SwapEndian($ATTRIBUTE_HEADER_NameRelativeOffset))
;	ConsoleWrite("$ATTRIBUTE_HEADER_NameRelativeOffset = " & $ATTRIBUTE_HEADER_NameRelativeOffset & @crlf)
	If $ATTRIBUTE_HEADER_NameLength > 0 Then
		$ATTRIBUTE_HEADER_Name = _UnicodeHexToStr(StringMid($Entry,$ATTRIBUTE_HEADER_NameRelativeOffset*2 + 1,$ATTRIBUTE_HEADER_NameLength*4))
	Else
		$ATTRIBUTE_HEADER_Name = ""
	EndIf
	$ATTRIBUTE_HEADER_Flags = _SwapEndian(StringMid($Entry,25,4))
;	ConsoleWrite("$ATTRIBUTE_HEADER_Flags = " & $ATTRIBUTE_HEADER_Flags & @crlf)
	$Flags = ""
	If $ATTRIBUTE_HEADER_Flags = "0000" Then
		$Flags = "NORMAL"
	Else
		If BitAND($ATTRIBUTE_HEADER_Flags,"0001") Then
			$IsCompressed = 1
			$Flags &= "COMPRESSED+"
		EndIf
		If BitAND($ATTRIBUTE_HEADER_Flags,"4000") Then
			$IsEncrypted = 1
			$Flags &= "ENCRYPTED+"
		EndIf
		If BitAND($ATTRIBUTE_HEADER_Flags,"8000") Then
			$IsSparse = 1
			$Flags &= "SPARSE+"
		EndIf
		$Flags = StringTrimRight($Flags,1)
	EndIf
;	ConsoleWrite("File is " & $Flags & @CRLF)
	$ATTRIBUTE_HEADER_AttributeID = StringMid($Entry,29,4)
	$ATTRIBUTE_HEADER_AttributeID = StringMid($ATTRIBUTE_HEADER_AttributeID,3,2) & StringMid($ATTRIBUTE_HEADER_AttributeID,1,2)
	If $ATTRIBUTE_HEADER_NonResidentFlag = '01' Then
		$ATTRIBUTE_HEADER_StartVCN = StringMid($Entry,33,16)
;		ConsoleWrite("$ATTRIBUTE_HEADER_StartVCN = " & $ATTRIBUTE_HEADER_StartVCN & @crlf)
		$ATTRIBUTE_HEADER_StartVCN = Dec(_SwapEndian($ATTRIBUTE_HEADER_StartVCN),2)
;		ConsoleWrite("$ATTRIBUTE_HEADER_StartVCN = " & $ATTRIBUTE_HEADER_StartVCN & @crlf)
		$ATTRIBUTE_HEADER_LastVCN = StringMid($Entry,49,16)
;		ConsoleWrite("$ATTRIBUTE_HEADER_LastVCN = " & $ATTRIBUTE_HEADER_LastVCN & @crlf)
		$ATTRIBUTE_HEADER_LastVCN = Dec(_SwapEndian($ATTRIBUTE_HEADER_LastVCN),2)
;		ConsoleWrite("$ATTRIBUTE_HEADER_LastVCN = " & $ATTRIBUTE_HEADER_LastVCN & @crlf)
		$ATTRIBUTE_HEADER_VCNs = $ATTRIBUTE_HEADER_LastVCN - $ATTRIBUTE_HEADER_StartVCN
;		ConsoleWrite("$ATTRIBUTE_HEADER_VCNs = " & $ATTRIBUTE_HEADER_VCNs & @crlf)
		$ATTRIBUTE_HEADER_OffsetToDataRuns = StringMid($Entry,65,4)
		$ATTRIBUTE_HEADER_OffsetToDataRuns = Dec(StringMid($ATTRIBUTE_HEADER_OffsetToDataRuns,3,1) & StringMid($ATTRIBUTE_HEADER_OffsetToDataRuns,3,1))
		$ATTRIBUTE_HEADER_CompressionUnitSize = Dec(_SwapEndian(StringMid($Entry,69,4)))
;		ConsoleWrite("$ATTRIBUTE_HEADER_CompressionUnitSize = " & $ATTRIBUTE_HEADER_CompressionUnitSize & @crlf)
		$IsCompressed = 0
		If $ATTRIBUTE_HEADER_CompressionUnitSize = 4 Then $IsCompressed = 1
		$ATTRIBUTE_HEADER_Padding = StringMid($Entry,73,8)
		$ATTRIBUTE_HEADER_Padding = StringMid($ATTRIBUTE_HEADER_Padding,7,2) & StringMid($ATTRIBUTE_HEADER_Padding,5,2) & StringMid($ATTRIBUTE_HEADER_Padding,3,2) & StringMid($ATTRIBUTE_HEADER_Padding,1,2)
		$ATTRIBUTE_HEADER_AllocatedSize = StringMid($Entry,81,16)
;		ConsoleWrite("$ATTRIBUTE_HEADER_AllocatedSize = " & $ATTRIBUTE_HEADER_AllocatedSize & @crlf)
		$ATTRIBUTE_HEADER_AllocatedSize = Dec(_SwapEndian($ATTRIBUTE_HEADER_AllocatedSize),2)
;		ConsoleWrite("$ATTRIBUTE_HEADER_AllocatedSize = " & $ATTRIBUTE_HEADER_AllocatedSize & @crlf)
		$ATTRIBUTE_HEADER_RealSize = StringMid($Entry,97,16)
;		ConsoleWrite("$ATTRIBUTE_HEADER_RealSize = " & $ATTRIBUTE_HEADER_RealSize & @crlf)
		$ATTRIBUTE_HEADER_RealSize = Dec(_SwapEndian($ATTRIBUTE_HEADER_RealSize),2)
;		ConsoleWrite("$ATTRIBUTE_HEADER_RealSize = " & $ATTRIBUTE_HEADER_RealSize & @crlf)
		$ATTRIBUTE_HEADER_InitializedStreamSize = StringMid($Entry,113,16)
;		ConsoleWrite("$ATTRIBUTE_HEADER_InitializedStreamSize = " & $ATTRIBUTE_HEADER_InitializedStreamSize & @crlf)
		$ATTRIBUTE_HEADER_InitializedStreamSize = Dec(_SwapEndian($ATTRIBUTE_HEADER_InitializedStreamSize),2)
;		ConsoleWrite("$ATTRIBUTE_HEADER_InitializedStreamSize = " & $ATTRIBUTE_HEADER_InitializedStreamSize & @crlf)
		$RunListOffset = StringMid($Entry,65,4)
;		ConsoleWrite("$RunListOffset = " & $RunListOffset & @crlf)
		$RunListOffset = Dec(_SwapEndian($RunListOffset))
;		ConsoleWrite("$RunListOffset = " & $RunListOffset & @crlf)
		If $IsCompressed AND $RunListOffset = 72 Then
			$ATTRIBUTE_HEADER_CompressedSize = StringMid($Entry,129,16)
			$ATTRIBUTE_HEADER_CompressedSize = Dec(_SwapEndian($ATTRIBUTE_HEADER_CompressedSize),2)
		EndIf
		$DataRun = StringMid($Entry,$RunListOffset*2+1,(StringLen($Entry)-$RunListOffset)*2)
;		ConsoleWrite("$DataRun = " & $DataRun & @crlf)
	ElseIf $ATTRIBUTE_HEADER_NonResidentFlag = '00' Then
		$ATTRIBUTE_HEADER_LengthOfAttribute = StringMid($Entry,33,8)
;		ConsoleWrite("$ATTRIBUTE_HEADER_LengthOfAttribute = " & $ATTRIBUTE_HEADER_LengthOfAttribute & @crlf)
		$ATTRIBUTE_HEADER_LengthOfAttribute = Dec(_SwapEndian($ATTRIBUTE_HEADER_LengthOfAttribute),2)
;		ConsoleWrite("$ATTRIBUTE_HEADER_LengthOfAttribute = " & $ATTRIBUTE_HEADER_LengthOfAttribute & @crlf)
;		$ATTRIBUTE_HEADER_OffsetToAttribute = StringMid($Entry,41,4)
;		$ATTRIBUTE_HEADER_OffsetToAttribute = Dec(StringMid($ATTRIBUTE_HEADER_OffsetToAttribute,3,2) & StringMid($ATTRIBUTE_HEADER_OffsetToAttribute,1,2))
		$ATTRIBUTE_HEADER_OffsetToAttribute = Dec(_SwapEndian(StringMid($Entry,41,4)))
;		ConsoleWrite("$ATTRIBUTE_HEADER_OffsetToAttribute = " & $ATTRIBUTE_HEADER_OffsetToAttribute & @crlf)
		$ATTRIBUTE_HEADER_IndexedFlag = Dec(StringMid($Entry,45,2))
		$ATTRIBUTE_HEADER_Padding = StringMid($Entry,47,2)
		$DataRun = StringMid($Entry,$ATTRIBUTE_HEADER_OffsetToAttribute*2+1,$ATTRIBUTE_HEADER_LengthOfAttribute*2)
;		ConsoleWrite("$DataRun = " & $DataRun & @crlf)
	EndIf
; Possible continuation
;	For $i = 1 To UBound($DataQ) - 1
	For $i = 1 To 1
;		_DecodeDataQEntry($DataQ[$i])
		If $ATTRIBUTE_HEADER_NonResidentFlag = '00' Then
;_ExtractResidentFile($DATA_Name, $DATA_LengthOfAttribute)
			$CoreAttribute = $DataRun
		Else
			Global $RUN_VCN[1], $RUN_Clusters[1]

			$TotalClusters = $ATTRIBUTE_HEADER_LastVCN - $ATTRIBUTE_HEADER_StartVCN + 1
			$Size = $ATTRIBUTE_HEADER_RealSize
;_ExtractDataRuns()
			$r=UBound($RUN_Clusters)
			$i=1
			$RUN_VCN[0] = 0
			$BaseVCN = $RUN_VCN[0]
			If $DataRun = "" Then $DataRun = "00"
			Do
				$RunListID = StringMid($DataRun,$i,2)
				If $RunListID = "00" Then ExitLoop
;				ConsoleWrite("$RunListID = " & $RunListID & @crlf)
				$i += 2
				$RunListClustersLength = Dec(StringMid($RunListID,2,1))
;				ConsoleWrite("$RunListClustersLength = " & $RunListClustersLength & @crlf)
				$RunListVCNLength = Dec(StringMid($RunListID,1,1))
;				ConsoleWrite("$RunListVCNLength = " & $RunListVCNLength & @crlf)
				$RunListClusters = Dec(_SwapEndian(StringMid($DataRun,$i,$RunListClustersLength*2)),2)
;				ConsoleWrite("$RunListClusters = " & $RunListClusters & @crlf)
				$i += $RunListClustersLength*2
				$RunListVCN = _SwapEndian(StringMid($DataRun, $i, $RunListVCNLength*2))
				;next line handles positive or negative move
				$BaseVCN += Dec($RunListVCN,2)-(($r>1) And (Dec(StringMid($RunListVCN,1,1))>7))*Dec(StringMid("10000000000000000",1,$RunListVCNLength*2+1),2)
				If $RunListVCN <> "" Then
					$RunListVCN = $BaseVCN
				Else
					$RunListVCN = 0			;$RUN_VCN[$r-1]		;0
				EndIf
;				ConsoleWrite("$RunListVCN = " & $RunListVCN & @crlf)
				If (($RunListVCN=0) And ($RunListClusters>16) And (Mod($RunListClusters,16)>0)) Then
				;If (($RunListVCN=$RUN_VCN[$r-1]) And ($RunListClusters>16) And (Mod($RunListClusters,16)>0)) Then
				;may be sparse section at end of Compression Signature
					_ArrayAdd($RUN_Clusters,Mod($RunListClusters,16))
					_ArrayAdd($RUN_VCN,$RunListVCN)
					$RunListClusters -= Mod($RunListClusters,16)
					$r += 1
				ElseIf (($RunListClusters>16) And (Mod($RunListClusters,16)>0)) Then
				;may be compressed data section at start of Compression Signature
					_ArrayAdd($RUN_Clusters,$RunListClusters-Mod($RunListClusters,16))
					_ArrayAdd($RUN_VCN,$RunListVCN)
					$RunListVCN += $RUN_Clusters[$r]
					$RunListClusters = Mod($RunListClusters,16)
					$r += 1
				EndIf
			;just normal or sparse data
				_ArrayAdd($RUN_Clusters,$RunListClusters)
				_ArrayAdd($RUN_VCN,$RunListVCN)
				$r += 1
				$i += $RunListVCNLength*2
			Until $i > StringLen($DataRun)
;--------------------------------_ExtractDataRuns()
;			_ArrayDisplay($RUN_Clusters,"$RUN_Clusters")
;			_ArrayDisplay($RUN_VCN,"$RUN_VCN")
			If $TotalClusters * $BytesPerCluster >= $Size Then
;				ConsoleWrite(_ArrayToString($RUN_VCN) & @CRLF)
;				ConsoleWrite(_ArrayToString($RUN_Clusters) & @CRLF)
;ExtractFile
				Local $nBytes
				$hFile = _WinAPI_CreateFile("\\.\" & $TargetDevice, 2, 6, 6)
				If $hFile = 0 Then
					ConsoleWrite("Error CreateFile in function _GetAttributeEntryNoRead()" & @CRLF)
					_WinAPI_CloseHandle($hFile)
					Return
				EndIf
				$tBuffer = DllStructCreate("byte[" & $BytesPerCluster * 16 & "]")
				Select
					Case UBound($RUN_VCN) = 1		;no data, do nothing
					Case (UBound($RUN_VCN) = 2) Or (Not $IsCompressed)	;may be normal or sparse
						If $RUN_VCN[1] = $RUN_VCN[0] And $DATA_Name <> "$Boot" Then		;sparse, unless $Boot
;							_DoSparse($htest)
							ConsoleWrite("Error: Sparse attributes not supported!!!" & @CRLF)
						Else								;normal
;							_DoNormalAttribute($hFile, $tBuffer)
;							Local $nBytes
							$FileSize = $ATTRIBUTE_HEADER_RealSize
							;An attempt at preparing for INDX modification
							Local $TestArray[UBound($RUN_VCN)][4]
							$TestArray[0][0] = "Offset"
							$TestArray[0][1] = "Bytes Accumulated"
							$TestArray[0][2] = "Bytes per Run"
							$TestArray[0][3] = "Sectors per Run"
							For $s = 1 To UBound($RUN_VCN)-1
								;ConsoleWrite("$RUN_VCN["&$s&"]" & @CRLF)
								;An attempt at preparing for INDX modification
								$TestArray[$s][0] = $RUN_VCN[$s]*$BytesPerCluster
								;_WinAPI_SetFilePointerEx($hFile, $RUN_VCN[$s]*$BytesPerCluster, $FILE_BEGIN)
								$g = $RUN_Clusters[$s]
								While $g > 16 And $FileSize > $BytesPerCluster * 16
									$Bytes += $BytesPerCluster * 16
									;_WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer), $BytesPerCluster * 16, $nBytes)
;									_WinAPI_WriteFile($htest, DllStructGetPtr($tBuffer), $BytesPerCluster * 16, $nBytes)
									$g -= 16
									$FileSize -= $BytesPerCluster * 16
									;$CoreAttributeTmp = StringMid(DllStructGetData($tBuffer,1),3,$BytesPerCluster*16*2)
									;$CoreAttribute &= $CoreAttributeTmp
								WEnd
								If $g <> 0 Then
									$Bytes += $BytesPerCluster * $g
									;_WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer), $BytesPerCluster * $g, $nBytes)
;									$CoreAttributeTmp = StringMid(DllStructGetData($tBuffer,1),3)
;									$CoreAttribute &= $CoreAttributeTmp
									If $FileSize > $BytesPerCluster * $g Then
;										_WinAPI_WriteFile($htest, DllStructGetPtr($tBuffer), $BytesPerCluster * $g, $nBytes)
										$FileSize -= $BytesPerCluster * $g
										;$CoreAttributeTmp = StringMid(DllStructGetData($tBuffer,1),3,$BytesPerCluster*$g*2)
										;$CoreAttribute &= $CoreAttributeTmp
									Else
;										_WinAPI_WriteFile($htest, DllStructGetPtr($tBuffer), $FileSize, $nBytes)
;										Return
										;$CoreAttributeTmp = StringMid(DllStructGetData($tBuffer,1),3,$FileSize*2)
										;$CoreAttribute &= $CoreAttributeTmp
									EndIf
								EndIf
								;An attempt at preparing for INDX modification
								$TestArray[$s][1] = $Bytes
							Next
;------------------_DoNormalAttribute()
						EndIf
					Case Else					;may be compressed
;						_DoCompressed($hFile, $htest, $tBuffer)
						ConsoleWrite("Error: Compressed attributes not supported!!!" & @CRLF)
				EndSelect
;------------------------ExtractFile
			EndIf
;-------------------------
		EndIf
	Next
	$CoreAttributeArr[0] = $CoreAttribute
	$CoreAttributeArr[1] = $ATTRIBUTE_HEADER_Name
	;An attempt at preparing for INDX modification
	$RawTestOffsetArray = $TestArray
	;If $ATTRIBUTE_HEADER_Name = "$I30" Then $RawTestOffsetArray = $TestArray
	For $i = 1 To UBound($RawTestOffsetArray)-1
		If $i = 1 Then
			$RawTestOffsetArray[$i][2] = $RawTestOffsetArray[$i][1]
		Else
			$RawTestOffsetArray[$i][2] = $RawTestOffsetArray[$i][1] - $RawTestOffsetArray[$i-1][1]
		EndIf
		$RawTestOffsetArray[$i][3] = $RawTestOffsetArray[$i][2]/512
	Next
;	_ArrayDisplay($RawTestOffsetArray,"$RawTestOffsetArray")
	Return $CoreAttributeArr
EndFunc

Func _Get_IndexRoot($Entry,$Current_Attrib_Number,$CurrentAttributeName)
	Local $LocalAttributeOffset = 1,$AttributeType,$CollationRule,$SizeOfIndexAllocationEntry,$ClustersPerIndexRoot,$IRPadding
	$AttributeType = StringMid($Entry,$LocalAttributeOffset,8)
;	$AttributeType = _SwapEndian($AttributeType)
	$CollationRule = StringMid($Entry,$LocalAttributeOffset+8,8)
	$CollationRule = _SwapEndian($CollationRule)
	$SizeOfIndexAllocationEntry = StringMid($Entry,$LocalAttributeOffset+16,8)
	$SizeOfIndexAllocationEntry = Dec(_SwapEndian($SizeOfIndexAllocationEntry),2)
	$ClustersPerIndexRoot = Dec(StringMid($Entry,$LocalAttributeOffset+24,2))
;	$IRPadding = StringMid($Entry,$LocalAttributeOffset+26,6)
	$OffsetToFirstEntry = StringMid($Entry,$LocalAttributeOffset+32,8)
	$OffsetToFirstEntry = Dec(_SwapEndian($OffsetToFirstEntry),2)
	$TotalSizeOfEntries = StringMid($Entry,$LocalAttributeOffset+40,8)
	$TotalSizeOfEntries = Dec(_SwapEndian($TotalSizeOfEntries),2)
	$AllocatedSizeOfEntries = StringMid($Entry,$LocalAttributeOffset+48,8)
	$AllocatedSizeOfEntries = Dec(_SwapEndian($AllocatedSizeOfEntries),2)
	$Flags = StringMid($Entry,$LocalAttributeOffset+56,2)
	If $Flags = "01" Then
		$Flags = "01 (Index Allocation needed)"
		$ResidentIndx = 0
	Else
		$Flags = "00 (Fits in Index Root)"
		$ResidentIndx = 1
	EndIf
;	$IRPadding2 = StringMid($Entry,$LocalAttributeOffset+58,6)
	$IRArr[0][$Current_Attrib_Number] = "IndexRoot Number " & $Current_Attrib_Number
	$IRArr[1][$Current_Attrib_Number] = $CurrentAttributeName
	$IRArr[2][$Current_Attrib_Number] = $AttributeType
	$IRArr[3][$Current_Attrib_Number] = $CollationRule
	$IRArr[4][$Current_Attrib_Number] = $SizeOfIndexAllocationEntry
	$IRArr[5][$Current_Attrib_Number] = $ClustersPerIndexRoot
;	$IRArr[6][$Current_Attrib_Number] = $IRPadding
	$IRArr[7][$Current_Attrib_Number] = $OffsetToFirstEntry
	$IRArr[8][$Current_Attrib_Number] = $TotalSizeOfEntries
	$IRArr[9][$Current_Attrib_Number] = $AllocatedSizeOfEntries
	$IRArr[10][$Current_Attrib_Number] = $Flags
;	$IRArr[11][$Current_Attrib_Number] = $IRPadding2
	If $ResidentIndx And $AttributeType=$FILE_NAME Then
		$TheResidentIndexEntry = StringMid($Entry,$LocalAttributeOffset+64)
		_DecodeIndxEntries($TheResidentIndexEntry,$Current_Attrib_Number,$CurrentAttributeName)
	EndIf
EndFunc

Func _StripIndxRecord($Entry)
;	ConsoleWrite("Starting function _StripIndxRecord()" & @crlf)
	Local $LocalAttributeOffset = 1,$IndxHdrUpdateSeqArrOffset,$IndxHdrUpdateSeqArrSize,$IndxHdrUpdSeqArr,$IndxHdrUpdSeqArrPart0,$IndxHdrUpdSeqArrPart1,$IndxHdrUpdSeqArrPart2,$IndxHdrUpdSeqArrPart3,$IndxHdrUpdSeqArrPart4,$IndxHdrUpdSeqArrPart5,$IndxHdrUpdSeqArrPart6,$IndxHdrUpdSeqArrPart7,$IndxHdrUpdSeqArrPart8
	Local $IndxRecordEnd1,$IndxRecordEnd2,$IndxRecordEnd3,$IndxRecordEnd4,$IndxRecordEnd5,$IndxRecordEnd6,$IndxRecordEnd7,$IndxRecordEnd8,$IndxRecordSize,$IndxHeaderSize,$IsNotLeafNode
;	ConsoleWrite("Unfixed INDX record:" & @crlf)
;	ConsoleWrite(_HexEncode("0x"&$Entry) & @crlf)
;	ConsoleWrite(_HexEncode("0x" & StringMid($Entry,1,4096)) & @crlf)
	$IndxHdrUpdateSeqArrOffset = Dec(_SwapEndian(StringMid($Entry,$LocalAttributeOffset+8,4)))
;	ConsoleWrite("$IndxHdrUpdateSeqArrOffset = " & $IndxHdrUpdateSeqArrOffset & @crlf)
	$IndxHdrUpdateSeqArrSize = Dec(_SwapEndian(StringMid($Entry,$LocalAttributeOffset+12,4)))
;	ConsoleWrite("$IndxHdrUpdateSeqArrSize = " & $IndxHdrUpdateSeqArrSize & @crlf)
	$IndxHdrUpdSeqArr = StringMid($Entry,1+($IndxHdrUpdateSeqArrOffset*2),$IndxHdrUpdateSeqArrSize*2*2)
;	ConsoleWrite("$IndxHdrUpdSeqArr = " & $IndxHdrUpdSeqArr & @crlf)
	$IndxHdrUpdSeqArrPart0 = StringMid($IndxHdrUpdSeqArr,1,4)
	$IndxHdrUpdSeqArrPart1 = StringMid($IndxHdrUpdSeqArr,5,4)
	$IndxHdrUpdSeqArrPart2 = StringMid($IndxHdrUpdSeqArr,9,4)
	$IndxHdrUpdSeqArrPart3 = StringMid($IndxHdrUpdSeqArr,13,4)
	$IndxHdrUpdSeqArrPart4 = StringMid($IndxHdrUpdSeqArr,17,4)
	$IndxHdrUpdSeqArrPart5 = StringMid($IndxHdrUpdSeqArr,21,4)
	$IndxHdrUpdSeqArrPart6 = StringMid($IndxHdrUpdSeqArr,25,4)
	$IndxHdrUpdSeqArrPart7 = StringMid($IndxHdrUpdSeqArr,29,4)
	$IndxHdrUpdSeqArrPart8 = StringMid($IndxHdrUpdSeqArr,33,4)
	$IndxRecordEnd1 = StringMid($Entry,1021,4)
	$IndxRecordEnd2 = StringMid($Entry,2045,4)
	$IndxRecordEnd3 = StringMid($Entry,3069,4)
	$IndxRecordEnd4 = StringMid($Entry,4093,4)
	$IndxRecordEnd5 = StringMid($Entry,5117,4)
	$IndxRecordEnd6 = StringMid($Entry,6141,4)
	$IndxRecordEnd7 = StringMid($Entry,7165,4)
	$IndxRecordEnd8 = StringMid($Entry,8189,4)
	If $IndxHdrUpdSeqArrPart0 <> $IndxRecordEnd1 OR $IndxHdrUpdSeqArrPart0 <> $IndxRecordEnd2 OR $IndxHdrUpdSeqArrPart0 <> $IndxRecordEnd3 OR $IndxHdrUpdSeqArrPart0 <> $IndxRecordEnd4 OR $IndxHdrUpdSeqArrPart0 <> $IndxRecordEnd5 OR $IndxHdrUpdSeqArrPart0 <> $IndxRecordEnd6 OR $IndxHdrUpdSeqArrPart0 <> $IndxRecordEnd7 OR $IndxHdrUpdSeqArrPart0 <> $IndxRecordEnd8 Then
		ConsoleWrite("Error the INDX record is corrupt" & @CRLF)
		Return ; Not really correct because I think in theory chunks of 1024 bytes can be invalid and not just everything or nothing for the given INDX record.
	Else
		$Entry = StringMid($Entry,1,1020) & $IndxHdrUpdSeqArrPart1 & StringMid($Entry,1025,1020) & $IndxHdrUpdSeqArrPart2 & StringMid($Entry,2049,1020) & $IndxHdrUpdSeqArrPart3 & StringMid($Entry,3073,1020) & $IndxHdrUpdSeqArrPart4 & StringMid($Entry,4097,1020) & $IndxHdrUpdSeqArrPart5 & StringMid($Entry,5121,1020) & $IndxHdrUpdSeqArrPart6 & StringMid($Entry,6145,1020) & $IndxHdrUpdSeqArrPart7 & StringMid($Entry,7169,1020) & $IndxHdrUpdSeqArrPart8
	EndIf
	$IndxRecordSize = Dec(_SwapEndian(StringMid($Entry,$LocalAttributeOffset+56,8)),2)
;	ConsoleWrite("$IndxRecordSize = " & $IndxRecordSize & @crlf)
	$IndxHeaderSize = Dec(_SwapEndian(StringMid($Entry,$LocalAttributeOffset+48,8)),2)
;	ConsoleWrite("$IndxHeaderSize = " & $IndxHeaderSize & @crlf)
	$IsNotLeafNode = StringMid($Entry,$LocalAttributeOffset+72,2) ;1 if not leaf node
	$Entry = StringMid($Entry,$LocalAttributeOffset+48+($IndxHeaderSize*2),($IndxRecordSize-$IndxHeaderSize-16)*2)
	If $IsNotLeafNode = "01" Then  ; This flag leads to the entry being 8 bytes of 00's longer than the others. Can be stripped I think.
		$Entry = StringTrimRight($Entry,16)
;		ConsoleWrite("Is not leaf node..." & @crlf)
	EndIf
	Return $Entry
EndFunc

Func _Get_IndexAllocation($Entry,$Current_Attrib_Number,$CurrentAttributeName)
;	ConsoleWrite("Starting function _Get_IndexAllocation()" & @crlf)
	Local $NextPosition = 1,$IndxHdrMagic,$IndxEntries,$TotalIndxEntries
;	ConsoleWrite("INDX record:" & @crlf)
;	ConsoleWrite(_HexEncode("0x"& StringMid($Entry,1)) & @crlf)
;	ConsoleWrite("StringLen of chunk = " & StringLen($Entry) & @crlf)
;	ConsoleWrite("Expected records = " & StringLen($Entry)/8192 & @crlf)
	$NextPosition = 1
	Do
		$IndxHdrMagic = StringMid($Entry,$NextPosition,8)
;		ConsoleWrite("$IndxHdrMagic = " & $IndxHdrMagic & @crlf)
		$IndxHdrMagic = _HexToString($IndxHdrMagic)
;		ConsoleWrite("$IndxHdrMagic = " & $IndxHdrMagic & @crlf)
		If $IndxHdrMagic <> "INDX" Then
;			ConsoleWrite("$IndxHdrMagic: " & $IndxHdrMagic & @crlf)
;			ConsoleWrite("Error: Record is not of type INDX, and this was not expected.." & @crlf)
			$NextPosition += 8192
			ContinueLoop
		EndIf
		$IndxEntries = _StripIndxRecord(StringMid($Entry,$NextPosition,8192))
		$TotalIndxEntries &= $IndxEntries
		$NextPosition += 8192
	Until $NextPosition >= StringLen($Entry)+32
;	ConsoleWrite("INDX record:" & @crlf)
;	ConsoleWrite(_HexEncode("0x"& StringMid($Entry,1)) & @crlf)
;	ConsoleWrite("Total chunk of stripped INDX entries:" & @crlf)
;	ConsoleWrite(_HexEncode("0x"& StringMid($TotalIndxEntries,1)) & @crlf)
	_DecodeIndxEntries($TotalIndxEntries,$Current_Attrib_Number,$CurrentAttributeName)
EndFunc

Func _DecodeIndxEntries($Entry,$Current_Attrib_Number,$CurrentAttributeName)
;	ConsoleWrite("Starting function _DecodeIndxEntries()" & @crlf)
	Local $LocalAttributeOffset = 1,$NewLocalAttributeOffset,$IndxHdrMagic,$IndxHdrUpdateSeqArrOffset,$IndxHdrUpdateSeqArrSize,$IndxHdrLogFileSequenceNo,$IndxHdrVCNOfIndx,$IndxHdrOffsetToIndexEntries,$IndxHdrSizeOfIndexEntries,$IndxHdrAllocatedSizeOfIndexEntries
	Local $IndxHdrFlag,$IndxHdrPadding,$IndxHdrUpdateSequence,$IndxHdrUpdSeqArr,$IndxHdrUpdSeqArrPart0,$IndxHdrUpdSeqArrPart1,$IndxHdrUpdSeqArrPart2,$IndxHdrUpdSeqArrPart3,$IndxRecordEnd4,$IndxRecordEnd1,$IndxRecordEnd2,$IndxRecordEnd3,$IndxRecordEnd4
	Local $FileReference,$IndexEntryLength,$StreamLength,$Flags,$Stream,$SubNodeVCN,$tmp0=0,$tmp1=0,$tmp2=0,$tmp3=0,$EntryCounter=1,$Padding2,$EntryCounter=1,$NextEntryOffset
	$NewLocalAttributeOffset = 1
	$MFTReference = StringMid($Entry,$NewLocalAttributeOffset,12)
	$MFTReference = StringMid($MFTReference,7,2)&StringMid($MFTReference,5,2)&StringMid($MFTReference,3,2)&StringMid($MFTReference,1,2)
	$MFTReference = Dec($MFTReference)
	$MFTReferenceSeqNo = StringMid($Entry,$NewLocalAttributeOffset+12,4)
	$MFTReferenceSeqNo = Dec(StringMid($MFTReferenceSeqNo,3,2)&StringMid($MFTReferenceSeqNo,1,2))
	$IndexEntryLength = StringMid($Entry,$NewLocalAttributeOffset+16,4)
	$IndexEntryLength = Dec(StringMid($IndexEntryLength,3,2)&StringMid($IndexEntryLength,3,2))
	$OffsetToFileName = StringMid($Entry,$NewLocalAttributeOffset+20,4)
	$OffsetToFileName = Dec(StringMid($OffsetToFileName,3,2)&StringMid($OffsetToFileName,3,2))
	$IndexFlags = StringMid($Entry,$NewLocalAttributeOffset+24,4)
;	$Padding = StringMid($Entry,$NewLocalAttributeOffset+28,4)
	$MFTReferenceOfParent = StringMid($Entry,$NewLocalAttributeOffset+32,12)
	$MFTReferenceOfParent = StringMid($MFTReferenceOfParent,7,2)&StringMid($MFTReferenceOfParent,5,2)&StringMid($MFTReferenceOfParent,3,2)&StringMid($MFTReferenceOfParent,1,2)
	$MFTReferenceOfParent = Dec($MFTReferenceOfParent)
	$MFTReferenceOfParentSeqNo = StringMid($Entry,$NewLocalAttributeOffset+44,4)
	$MFTReferenceOfParentSeqNo = Dec(StringMid($MFTReferenceOfParentSeqNo,3,2) & StringMid($MFTReferenceOfParentSeqNo,3,2))
	$Indx_CTime = StringMid($Entry,$NewLocalAttributeOffset+48,16)
	$Indx_CTime = StringMid($Indx_CTime,15,2) & StringMid($Indx_CTime,13,2) & StringMid($Indx_CTime,11,2) & StringMid($Indx_CTime,9,2) & StringMid($Indx_CTime,7,2) & StringMid($Indx_CTime,5,2) & StringMid($Indx_CTime,3,2) & StringMid($Indx_CTime,1,2)
	$Indx_CTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_CTime)
	$Indx_CTime = _WinTime_UTCFileTimeFormat(Dec($Indx_CTime)-$tDelta,$DateTimeFormat,2)
	If @error Then
		$Indx_CTime = "-"
	Else
		$Indx_CTime = $Indx_CTime & ":" & _FillZero(StringRight($Indx_CTime_tmp,4))
	EndIf
	$Indx_ATime = StringMid($Entry,$NewLocalAttributeOffset+64,16)
	$Indx_ATime = StringMid($Indx_ATime,15,2) & StringMid($Indx_ATime,13,2) & StringMid($Indx_ATime,11,2) & StringMid($Indx_ATime,9,2) & StringMid($Indx_ATime,7,2) & StringMid($Indx_ATime,5,2) & StringMid($Indx_ATime,3,2) & StringMid($Indx_ATime,1,2)
	$Indx_ATime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_ATime)
	$Indx_ATime = _WinTime_UTCFileTimeFormat(Dec($Indx_ATime)-$tDelta,$DateTimeFormat,2)
	If @error Then
		$Indx_ATime = "-"
	Else
		$Indx_ATime = $Indx_ATime & ":" & _FillZero(StringRight($Indx_ATime_tmp,4))
	EndIf
	$Indx_MTime = StringMid($Entry,$NewLocalAttributeOffset+80,16)
	$Indx_MTime = StringMid($Indx_MTime,15,2) & StringMid($Indx_MTime,13,2) & StringMid($Indx_MTime,11,2) & StringMid($Indx_MTime,9,2) & StringMid($Indx_MTime,7,2) & StringMid($Indx_MTime,5,2) & StringMid($Indx_MTime,3,2) & StringMid($Indx_MTime,1,2)
	$Indx_MTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_MTime)
	$Indx_MTime = _WinTime_UTCFileTimeFormat(Dec($Indx_MTime)-$tDelta,$DateTimeFormat,2)
	If @error Then
		$Indx_MTime = "-"
	Else
		$Indx_MTime = $Indx_MTime & ":" & _FillZero(StringRight($Indx_MTime_tmp,4))
	EndIf
	$Indx_RTime = StringMid($Entry,$NewLocalAttributeOffset+96,16)
	$Indx_RTime = StringMid($Indx_RTime,15,2) & StringMid($Indx_RTime,13,2) & StringMid($Indx_RTime,11,2) & StringMid($Indx_RTime,9,2) & StringMid($Indx_RTime,7,2) & StringMid($Indx_RTime,5,2) & StringMid($Indx_RTime,3,2) & StringMid($Indx_RTime,1,2)
	$Indx_RTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_RTime)
	$Indx_RTime = _WinTime_UTCFileTimeFormat(Dec($Indx_RTime)-$tDelta,$DateTimeFormat,2)
	If @error Then
		$Indx_RTime = "-"
	Else
		$Indx_RTime = $Indx_RTime & ":" & _FillZero(StringRight($Indx_RTime_tmp,4))
	EndIf
	#cs
	$Indx_AllocSize = StringMid($Entry,$NewLocalAttributeOffset+112,16)
	$Indx_AllocSize = Dec(StringMid($Indx_AllocSize,15,2) & StringMid($Indx_AllocSize,13,2) & StringMid($Indx_AllocSize,11,2) & StringMid($Indx_AllocSize,9,2) & StringMid($Indx_AllocSize,7,2) & StringMid($Indx_AllocSize,5,2) & StringMid($Indx_AllocSize,3,2) & StringMid($Indx_AllocSize,1,2))
	$Indx_RealSize = StringMid($Entry,$NewLocalAttributeOffset+128,16)
	$Indx_RealSize = Dec(StringMid($Indx_RealSize,15,2) & StringMid($Indx_RealSize,13,2) & StringMid($Indx_RealSize,11,2) & StringMid($Indx_RealSize,9,2) & StringMid($Indx_RealSize,7,2) & StringMid($Indx_RealSize,5,2) & StringMid($Indx_RealSize,3,2) & StringMid($Indx_RealSize,1,2))
	$Indx_File_Flags = StringMid($Entry,$NewLocalAttributeOffset+144,16)
	$Indx_File_Flags = StringMid($Indx_File_Flags,15,2) & StringMid($Indx_File_Flags,13,2) & StringMid($Indx_File_Flags,11,2) & StringMid($Indx_File_Flags,9,2)&StringMid($Indx_File_Flags,7,2) & StringMid($Indx_File_Flags,5,2) & StringMid($Indx_File_Flags,3,2) & StringMid($Indx_File_Flags,1,2)
	$Indx_File_Flags = StringMid($Indx_File_Flags,13,8)
	$Indx_File_Flags = _File_Attributes("0x" & $Indx_File_Flags)
	#ce
	$Indx_NameLength = StringMid($Entry,$NewLocalAttributeOffset+160,2)
	$Indx_NameLength = Dec($Indx_NameLength)
	$Indx_NameSpace = StringMid($Entry,$NewLocalAttributeOffset+162,2)
	Select
		Case $Indx_NameSpace = "00"	;POSIX
			$Indx_NameSpace = "POSIX"
		Case $Indx_NameSpace = "01"	;WIN32
			$Indx_NameSpace = "WIN32"
		Case $Indx_NameSpace = "02"	;DOS
			$Indx_NameSpace = "DOS"
		Case $Indx_NameSpace = "03"	;DOS+WIN32
			$Indx_NameSpace = "DOS+WIN32"
	EndSelect
	$Indx_FileName = StringMid($Entry,$NewLocalAttributeOffset+164,$Indx_NameLength*2*2)
	$Indx_FileName = _UnicodeHexToStr($Indx_FileName)
	$tmp1 = 164+($Indx_NameLength*2*2)
	Do ; Calculate the length of the padding - 8 byte aligned
		$tmp2 = $tmp1/16
		If Not IsInt($tmp2) Then
			$tmp0 = 2
			$tmp1 += $tmp0
			$tmp3 += $tmp0
		EndIf
	Until IsInt($tmp2)
	$PaddingLength = $tmp3
;	$Padding2 = StringMid($Entry,$NewLocalAttributeOffset+164+($Indx_NameLength*2*2),$PaddingLength)
	If $IndexFlags <> "0000" Then
		$SubNodeVCN = StringMid($Entry,$NewLocalAttributeOffset+164+($Indx_NameLength*2*2)+$PaddingLength,16)
		$SubNodeVCNLength = 16
	Else
		$SubNodeVCN = ""
		$SubNodeVCNLength = 0
	EndIf
	ReDim $IndxEntryNumberArr[1+$EntryCounter]
	ReDim $IndxMFTReferenceArr[1+$EntryCounter]
	ReDim $IndxMFTRefSeqNoArr[1+$EntryCounter]
;	ReDim $IndxIndexFlagsArr[1+$EntryCounter]
	ReDim $IndxMFTReferenceOfParentArr[1+$EntryCounter]
	ReDim $IndxMFTParentRefSeqNoArr[1+$EntryCounter]
	ReDim $IndxCTimeArr[1+$EntryCounter]
	ReDim $IndxATimeArr[1+$EntryCounter]
	ReDim $IndxMTimeArr[1+$EntryCounter]
	ReDim $IndxRTimeArr[1+$EntryCounter]
;	ReDim $IndxAllocSizeArr[1+$EntryCounter]
;	ReDim $IndxRealSizeArr[1+$EntryCounter]
;	ReDim $IndxFileFlagsArr[1+$EntryCounter]
	ReDim $IndxFileNameArr[1+$EntryCounter]
;	ReDim $IndxNameSpaceArr[1+$EntryCounter]
;	ReDim $IndxSubNodeVCNArr[1+$EntryCounter]
	$IndxEntryNumberArr[$EntryCounter] = $EntryCounter
	$IndxMFTReferenceArr[$EntryCounter] = $MFTReference
	$IndxMFTRefSeqNoArr[$EntryCounter] = $MFTReferenceSeqNo
;	$IndxIndexFlagsArr[$EntryCounter] = $IndexFlags
	$IndxMFTReferenceOfParentArr[$EntryCounter] = $MFTReferenceOfParent
	$IndxMFTParentRefSeqNoArr[$EntryCounter] = $MFTReferenceOfParentSeqNo
	$IndxCTimeArr[$EntryCounter] = $Indx_CTime
	$IndxATimeArr[$EntryCounter] = $Indx_ATime
	$IndxMTimeArr[$EntryCounter] = $Indx_MTime
	$IndxRTimeArr[$EntryCounter] = $Indx_RTime
;	$IndxAllocSizeArr[$EntryCounter] = $Indx_AllocSize
;	$IndxRealSizeArr[$EntryCounter] = $Indx_RealSize
;	$IndxFileFlagsArr[$EntryCounter] = $Indx_File_Flags
	$IndxFileNameArr[$EntryCounter] = $Indx_FileName
;	$IndxNameSpaceArr[$EntryCounter] = $Indx_NameSpace
;	$IndxSubNodeVCNArr[$EntryCounter] = $SubNodeVCN
; Work through the rest of the index entries
	$NextEntryOffset = $NewLocalAttributeOffset+164+($Indx_NameLength*2*2)+$PaddingLength+$SubNodeVCNLength
	If $NextEntryOffset+64 >= StringLen($Entry) Then Return
	Do
		$EntryCounter += 1
;		ConsoleWrite("$EntryCounter = " & $EntryCounter & @crlf)
		$MFTReference = StringMid($Entry,$NextEntryOffset,12)
;		ConsoleWrite("$MFTReference = " & $MFTReference & @crlf)
		$MFTReference = StringMid($MFTReference,7,2)&StringMid($MFTReference,5,2)&StringMid($MFTReference,3,2)&StringMid($MFTReference,1,2)
;		$MFTReference = StringMid($MFTReference,15,2)&StringMid($MFTReference,13,2)&StringMid($MFTReference,11,2)&StringMid($MFTReference,9,2)&StringMid($MFTReference,7,2)&StringMid($MFTReference,5,2)&StringMid($MFTReference,3,2)&StringMid($MFTReference,1,2)
;		ConsoleWrite("$MFTReference = " & $MFTReference & @crlf)
		$MFTReference = Dec($MFTReference)
		$MFTReferenceSeqNo = StringMid($Entry,$NextEntryOffset+12,4)
		$MFTReferenceSeqNo = Dec(StringMid($MFTReferenceSeqNo,3,2)&StringMid($MFTReferenceSeqNo,1,2))
		$IndexEntryLength = StringMid($Entry,$NextEntryOffset+16,4)
;		ConsoleWrite("$IndexEntryLength = " & $IndexEntryLength & @crlf)
		$IndexEntryLength = Dec(StringMid($IndexEntryLength,3,2)&StringMid($IndexEntryLength,3,2))
;		ConsoleWrite("$IndexEntryLength = " & $IndexEntryLength & @crlf)
		$OffsetToFileName = StringMid($Entry,$NextEntryOffset+20,4)
;		ConsoleWrite("$OffsetToFileName = " & $OffsetToFileName & @crlf)
		$OffsetToFileName = Dec(StringMid($OffsetToFileName,3,2)&StringMid($OffsetToFileName,3,2))
;		ConsoleWrite("$OffsetToFileName = " & $OffsetToFileName & @crlf)
		$IndexFlags = StringMid($Entry,$NextEntryOffset+24,4)
;		ConsoleWrite("$IndexFlags = " & $IndexFlags & @crlf)
;		$Padding = StringMid($Entry,$NextEntryOffset+28,4)
;		ConsoleWrite("$Padding = " & $Padding & @crlf)
		$MFTReferenceOfParent = StringMid($Entry,$NextEntryOffset+32,12)
;		ConsoleWrite("$MFTReferenceOfParent = " & $MFTReferenceOfParent & @crlf)
		$MFTReferenceOfParent = StringMid($MFTReferenceOfParent,7,2)&StringMid($MFTReferenceOfParent,5,2)&StringMid($MFTReferenceOfParent,3,2)&StringMid($MFTReferenceOfParent,1,2)
;		$MFTReferenceOfParent = StringMid($MFTReferenceOfParent,15,2)&StringMid($MFTReferenceOfParent,13,2)&StringMid($MFTReferenceOfParent,11,2)&StringMid($MFTReferenceOfParent,9,2)&StringMid($MFTReferenceOfParent,7,2)&StringMid($MFTReferenceOfParent,5,2)&StringMid($MFTReferenceOfParent,3,2)&StringMid($MFTReferenceOfParent,1,2)
;		ConsoleWrite("$MFTReferenceOfParent = " & $MFTReferenceOfParent & @crlf)
		$MFTReferenceOfParent = Dec($MFTReferenceOfParent)
		$MFTReferenceOfParentSeqNo = StringMid($Entry,$NextEntryOffset+44,4)
		$MFTReferenceOfParentSeqNo = Dec(StringMid($MFTReferenceOfParentSeqNo,3,2) & StringMid($MFTReferenceOfParentSeqNo,3,2))

		$Indx_CTime = StringMid($Entry,$NextEntryOffset+48,16)
		$Indx_CTime = StringMid($Indx_CTime,15,2) & StringMid($Indx_CTime,13,2) & StringMid($Indx_CTime,11,2) & StringMid($Indx_CTime,9,2) & StringMid($Indx_CTime,7,2) & StringMid($Indx_CTime,5,2) & StringMid($Indx_CTime,3,2) & StringMid($Indx_CTime,1,2)
		$Indx_CTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_CTime)
		$Indx_CTime = _WinTime_UTCFileTimeFormat(Dec($Indx_CTime)-$tDelta,$DateTimeFormat,2)
		$Indx_CTime = $Indx_CTime & ":" & _FillZero(StringRight($Indx_CTime_tmp,4))
;		ConsoleWrite("$Indx_CTime = " & $Indx_CTime & @crlf)
;
		$Indx_ATime = StringMid($Entry,$NextEntryOffset+64,16)
		$Indx_ATime = StringMid($Indx_ATime,15,2) & StringMid($Indx_ATime,13,2) & StringMid($Indx_ATime,11,2) & StringMid($Indx_ATime,9,2) & StringMid($Indx_ATime,7,2) & StringMid($Indx_ATime,5,2) & StringMid($Indx_ATime,3,2) & StringMid($Indx_ATime,1,2)
		$Indx_ATime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_ATime)
		$Indx_ATime = _WinTime_UTCFileTimeFormat(Dec($Indx_ATime)-$tDelta,$DateTimeFormat,2)
		$Indx_ATime = $Indx_ATime & ":" & _FillZero(StringRight($Indx_ATime_tmp,4))
;		ConsoleWrite("$Indx_ATime = " & $Indx_ATime & @crlf)
;
		$Indx_MTime = StringMid($Entry,$NextEntryOffset+80,16)
		$Indx_MTime = StringMid($Indx_MTime,15,2) & StringMid($Indx_MTime,13,2) & StringMid($Indx_MTime,11,2) & StringMid($Indx_MTime,9,2) & StringMid($Indx_MTime,7,2) & StringMid($Indx_MTime,5,2) & StringMid($Indx_MTime,3,2) & StringMid($Indx_MTime,1,2)
		$Indx_MTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_MTime)
		$Indx_MTime = _WinTime_UTCFileTimeFormat(Dec($Indx_MTime)-$tDelta,$DateTimeFormat,2)
		$Indx_MTime = $Indx_MTime & ":" & _FillZero(StringRight($Indx_MTime_tmp,4))
;		ConsoleWrite("$Indx_MTime = " & $Indx_MTime & @crlf)
;
		$Indx_RTime = StringMid($Entry,$NextEntryOffset+96,16)
		$Indx_RTime = StringMid($Indx_RTime,15,2) & StringMid($Indx_RTime,13,2) & StringMid($Indx_RTime,11,2) & StringMid($Indx_RTime,9,2) & StringMid($Indx_RTime,7,2) & StringMid($Indx_RTime,5,2) & StringMid($Indx_RTime,3,2) & StringMid($Indx_RTime,1,2)
		$Indx_RTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_RTime)
		$Indx_RTime = _WinTime_UTCFileTimeFormat(Dec($Indx_RTime)-$tDelta,$DateTimeFormat,2)
		$Indx_RTime = $Indx_RTime & ":" & _FillZero(StringRight($Indx_RTime_tmp,4))
;		ConsoleWrite("$Indx_RTime = " & $Indx_RTime & @crlf)
;
#cs
		$Indx_AllocSize = StringMid($Entry,$NextEntryOffset+112,16)
		$Indx_AllocSize = Dec(StringMid($Indx_AllocSize,15,2) & StringMid($Indx_AllocSize,13,2) & StringMid($Indx_AllocSize,11,2) & StringMid($Indx_AllocSize,9,2) & StringMid($Indx_AllocSize,7,2) & StringMid($Indx_AllocSize,5,2) & StringMid($Indx_AllocSize,3,2) & StringMid($Indx_AllocSize,1,2))
;		ConsoleWrite("$Indx_AllocSize = " & $Indx_AllocSize & @crlf)
		$Indx_RealSize = StringMid($Entry,$NextEntryOffset+128,16)
		$Indx_RealSize = Dec(StringMid($Indx_RealSize,15,2) & StringMid($Indx_RealSize,13,2) & StringMid($Indx_RealSize,11,2) & StringMid($Indx_RealSize,9,2) & StringMid($Indx_RealSize,7,2) & StringMid($Indx_RealSize,5,2) & StringMid($Indx_RealSize,3,2) & StringMid($Indx_RealSize,1,2))
;		ConsoleWrite("$Indx_RealSize = " & $Indx_RealSize & @crlf)
		$Indx_File_Flags = StringMid($Entry,$NextEntryOffset+144,16)
;		ConsoleWrite("$Indx_File_Flags = " & $Indx_File_Flags & @crlf)
		$Indx_File_Flags = StringMid($Indx_File_Flags,15,2) & StringMid($Indx_File_Flags,13,2) & StringMid($Indx_File_Flags,11,2) & StringMid($Indx_File_Flags,9,2)&StringMid($Indx_File_Flags,7,2) & StringMid($Indx_File_Flags,5,2) & StringMid($Indx_File_Flags,3,2) & StringMid($Indx_File_Flags,1,2)
;		ConsoleWrite("$Indx_File_Flags = " & $Indx_File_Flags & @crlf)
		$Indx_File_Flags = StringMid($Indx_File_Flags,13,8)
		$Indx_File_Flags = _File_Attributes("0x" & $Indx_File_Flags)
;		ConsoleWrite("$Indx_File_Flags = " & $Indx_File_Flags & @crlf)
#ce
		$Indx_NameLength = StringMid($Entry,$NextEntryOffset+160,2)
		$Indx_NameLength = Dec($Indx_NameLength)
;		ConsoleWrite("$Indx_NameLength = " & $Indx_NameLength & @crlf)
		$Indx_NameSpace = StringMid($Entry,$NextEntryOffset+162,2)
;		ConsoleWrite("$Indx_NameSpace = " & $Indx_NameSpace & @crlf)
		Select
			Case $Indx_NameSpace = "00"	;POSIX
				$Indx_NameSpace = "POSIX"
			Case $Indx_NameSpace = "01"	;WIN32
				$Indx_NameSpace = "WIN32"
			Case $Indx_NameSpace = "02"	;DOS
				$Indx_NameSpace = "DOS"
			Case $Indx_NameSpace = "03"	;DOS+WIN32
				$Indx_NameSpace = "DOS+WIN32"
		EndSelect
		$Indx_FileName = StringMid($Entry,$NextEntryOffset+164,$Indx_NameLength*2*2)
;		ConsoleWrite("$Indx_FileName = " & $Indx_FileName & @crlf)
		$Indx_FileName = _UnicodeHexToStr($Indx_FileName)
		;ConsoleWrite("$Indx_FileName = " & $Indx_FileName & @crlf)
		$tmp0 = 0
		$tmp2 = 0
		$tmp3 = 0
		$tmp1 = 164+($Indx_NameLength*2*2)
		Do ; Calculate the length of the padding - 8 byte aligned
			$tmp2 = $tmp1/16
			If Not IsInt($tmp2) Then
				$tmp0 = 2
				$tmp1 += $tmp0
				$tmp3 += $tmp0
			EndIf
		Until IsInt($tmp2)
		$PaddingLength = $tmp3
;		ConsoleWrite("$PaddingLength = " & $PaddingLength & @crlf)
		$Padding = StringMid($Entry,$NextEntryOffset+164+($Indx_NameLength*2*2),$PaddingLength)
;		ConsoleWrite("$Padding = " & $Padding & @crlf)
		If $IndexFlags <> "0000" Then
			$SubNodeVCN = StringMid($Entry,$NextEntryOffset+164+($Indx_NameLength*2*2)+$PaddingLength,16)
			$SubNodeVCNLength = 16
		Else
			$SubNodeVCN = ""
			$SubNodeVCNLength = 0
		EndIf
;		ConsoleWrite("$SubNodeVCN = " & $SubNodeVCN & @crlf)
		$NextEntryOffset = $NextEntryOffset+164+($Indx_NameLength*2*2)+$PaddingLength+$SubNodeVCNLength
		ReDim $IndxEntryNumberArr[1+$EntryCounter]
		ReDim $IndxMFTReferenceArr[1+$EntryCounter]
		Redim $IndxMFTRefSeqNoArr[1+$EntryCounter]
;		ReDim $IndxIndexFlagsArr[1+$EntryCounter]
		ReDim $IndxMFTReferenceOfParentArr[1+$EntryCounter]
		ReDim $IndxMFTParentRefSeqNoArr[1+$EntryCounter]
		ReDim $IndxCTimeArr[1+$EntryCounter]
		ReDim $IndxATimeArr[1+$EntryCounter]
		ReDim $IndxMTimeArr[1+$EntryCounter]
		ReDim $IndxRTimeArr[1+$EntryCounter]
;		ReDim $IndxAllocSizeArr[1+$EntryCounter]
;		ReDim $IndxRealSizeArr[1+$EntryCounter]
;		ReDim $IndxFileFlagsArr[1+$EntryCounter]
		ReDim $IndxFileNameArr[1+$EntryCounter]
;		ReDim $IndxNameSpaceArr[1+$EntryCounter]
;		ReDim $IndxSubNodeVCNArr[1+$EntryCounter]
		$IndxEntryNumberArr[$EntryCounter] = $EntryCounter
		$IndxMFTReferenceArr[$EntryCounter] = $MFTReference
		$IndxMFTRefSeqNoArr[$EntryCounter] = $MFTReferenceSeqNo
;		$IndxIndexFlagsArr[$EntryCounter] = $IndexFlags
		$IndxMFTReferenceOfParentArr[$EntryCounter] = $MFTReferenceOfParent
		$IndxMFTParentRefSeqNoArr[$EntryCounter] = $MFTReferenceOfParentSeqNo
		$IndxCTimeArr[$EntryCounter] = $Indx_CTime
		$IndxATimeArr[$EntryCounter] = $Indx_ATime
		$IndxMTimeArr[$EntryCounter] = $Indx_MTime
		$IndxRTimeArr[$EntryCounter] = $Indx_RTime
;		$IndxAllocSizeArr[$EntryCounter] = $Indx_AllocSize
;		$IndxRealSizeArr[$EntryCounter] = $Indx_RealSize
;		$IndxFileFlagsArr[$EntryCounter] = $Indx_File_Flags
		$IndxFileNameArr[$EntryCounter] = $Indx_FileName
;		$IndxNameSpaceArr[$EntryCounter] = $Indx_NameSpace
;		$IndxSubNodeVCNArr[$EntryCounter] = $SubNodeVCN
;		_ArrayDisplay($IndxFileNameArr,"$IndxFileNameArr")
	Until $NextEntryOffset+32 >= StringLen($Entry)
;	If $DummyVar Then _ArrayDisplay($IndxFileNameArr,"$IndxFileNameArr")
EndFunc

Func _DecodeIndxEntriesExpress($Entry)
;	ConsoleWrite("Starting function _DecodeIndxEntries()" & @crlf)
	Local $LocalAttributeOffset = 1,$NewLocalAttributeOffset,$IndxHdrMagic,$IndxHdrUpdateSeqArrOffset,$IndxHdrUpdateSeqArrSize,$IndxHdrLogFileSequenceNo,$IndxHdrVCNOfIndx,$IndxHdrOffsetToIndexEntries,$IndxHdrSizeOfIndexEntries,$IndxHdrAllocatedSizeOfIndexEntries
	Local $IndxHdrFlag,$IndxHdrPadding,$IndxHdrUpdateSequence,$IndxHdrUpdSeqArr,$IndxHdrUpdSeqArrPart0,$IndxHdrUpdSeqArrPart1,$IndxHdrUpdSeqArrPart2,$IndxHdrUpdSeqArrPart3,$IndxRecordEnd4,$IndxRecordEnd1,$IndxRecordEnd2,$IndxRecordEnd3,$IndxRecordEnd4
	Local $FileReference,$IndexEntryLength,$StreamLength,$Flags,$Stream,$SubNodeVCN,$tmp0=0,$tmp1=0,$tmp2=0,$tmp3=0,$EntryCounter=1,$Padding2,$EntryCounter=1,$NextEntryOffset
	$NewLocalAttributeOffset = 1
	$MFTReference = StringMid($Entry,$NewLocalAttributeOffset,12)
	$MFTReference = StringMid($MFTReference,7,2)&StringMid($MFTReference,5,2)&StringMid($MFTReference,3,2)&StringMid($MFTReference,1,2)
	$MFTReference = Dec($MFTReference)
	#cs
	$MFTReferenceSeqNo = StringMid($Entry,$NewLocalAttributeOffset+12,4)
	$MFTReferenceSeqNo = Dec(StringMid($MFTReferenceSeqNo,3,2)&StringMid($MFTReferenceSeqNo,1,2))
	$IndexEntryLength = StringMid($Entry,$NewLocalAttributeOffset+16,4)
	$IndexEntryLength = Dec(StringMid($IndexEntryLength,3,2)&StringMid($IndexEntryLength,3,2))
	$OffsetToFileName = StringMid($Entry,$NewLocalAttributeOffset+20,4)
	$OffsetToFileName = Dec(StringMid($OffsetToFileName,3,2)&StringMid($OffsetToFileName,3,2))
	#ce
	$IndexFlags = StringMid($Entry,$NewLocalAttributeOffset+24,4)
	#cs
;	$Padding = StringMid($Entry,$NewLocalAttributeOffset+28,4)
	$MFTReferenceOfParent = StringMid($Entry,$NewLocalAttributeOffset+32,12)
	$MFTReferenceOfParent = StringMid($MFTReferenceOfParent,7,2)&StringMid($MFTReferenceOfParent,5,2)&StringMid($MFTReferenceOfParent,3,2)&StringMid($MFTReferenceOfParent,1,2)
	$MFTReferenceOfParent = Dec($MFTReferenceOfParent)
	$MFTReferenceOfParentSeqNo = StringMid($Entry,$NewLocalAttributeOffset+44,4)
	$MFTReferenceOfParentSeqNo = Dec(StringMid($MFTReferenceOfParentSeqNo,3,2) & StringMid($MFTReferenceOfParentSeqNo,3,2))
	$Indx_CTime = StringMid($Entry,$NewLocalAttributeOffset+48,16)
	$Indx_CTime = StringMid($Indx_CTime,15,2) & StringMid($Indx_CTime,13,2) & StringMid($Indx_CTime,11,2) & StringMid($Indx_CTime,9,2) & StringMid($Indx_CTime,7,2) & StringMid($Indx_CTime,5,2) & StringMid($Indx_CTime,3,2) & StringMid($Indx_CTime,1,2)
	$Indx_CTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_CTime)
	$Indx_CTime = _WinTime_UTCFileTimeFormat(Dec($Indx_CTime)-$tDelta,$DateTimeFormat,2)
	If @error Then
		$Indx_CTime = "-"
	Else
		$Indx_CTime = $Indx_CTime & ":" & _FillZero(StringRight($Indx_CTime_tmp,4))
	EndIf
	$Indx_ATime = StringMid($Entry,$NewLocalAttributeOffset+64,16)
	$Indx_ATime = StringMid($Indx_ATime,15,2) & StringMid($Indx_ATime,13,2) & StringMid($Indx_ATime,11,2) & StringMid($Indx_ATime,9,2) & StringMid($Indx_ATime,7,2) & StringMid($Indx_ATime,5,2) & StringMid($Indx_ATime,3,2) & StringMid($Indx_ATime,1,2)
	$Indx_ATime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_ATime)
	$Indx_ATime = _WinTime_UTCFileTimeFormat(Dec($Indx_ATime)-$tDelta,$DateTimeFormat,2)
	If @error Then
		$Indx_ATime = "-"
	Else
		$Indx_ATime = $Indx_ATime & ":" & _FillZero(StringRight($Indx_ATime_tmp,4))
	EndIf
	$Indx_MTime = StringMid($Entry,$NewLocalAttributeOffset+80,16)
	$Indx_MTime = StringMid($Indx_MTime,15,2) & StringMid($Indx_MTime,13,2) & StringMid($Indx_MTime,11,2) & StringMid($Indx_MTime,9,2) & StringMid($Indx_MTime,7,2) & StringMid($Indx_MTime,5,2) & StringMid($Indx_MTime,3,2) & StringMid($Indx_MTime,1,2)
	$Indx_MTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_MTime)
	$Indx_MTime = _WinTime_UTCFileTimeFormat(Dec($Indx_MTime)-$tDelta,$DateTimeFormat,2)
	If @error Then
		$Indx_MTime = "-"
	Else
		$Indx_MTime = $Indx_MTime & ":" & _FillZero(StringRight($Indx_MTime_tmp,4))
	EndIf
	$Indx_RTime = StringMid($Entry,$NewLocalAttributeOffset+96,16)
	$Indx_RTime = StringMid($Indx_RTime,15,2) & StringMid($Indx_RTime,13,2) & StringMid($Indx_RTime,11,2) & StringMid($Indx_RTime,9,2) & StringMid($Indx_RTime,7,2) & StringMid($Indx_RTime,5,2) & StringMid($Indx_RTime,3,2) & StringMid($Indx_RTime,1,2)
	$Indx_RTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_RTime)
	$Indx_RTime = _WinTime_UTCFileTimeFormat(Dec($Indx_RTime)-$tDelta,$DateTimeFormat,2)
	If @error Then
		$Indx_RTime = "-"
	Else
		$Indx_RTime = $Indx_RTime & ":" & _FillZero(StringRight($Indx_RTime_tmp,4))
	EndIf
	$Indx_AllocSize = StringMid($Entry,$NewLocalAttributeOffset+112,16)
	$Indx_AllocSize = Dec(StringMid($Indx_AllocSize,15,2) & StringMid($Indx_AllocSize,13,2) & StringMid($Indx_AllocSize,11,2) & StringMid($Indx_AllocSize,9,2) & StringMid($Indx_AllocSize,7,2) & StringMid($Indx_AllocSize,5,2) & StringMid($Indx_AllocSize,3,2) & StringMid($Indx_AllocSize,1,2))
	$Indx_RealSize = StringMid($Entry,$NewLocalAttributeOffset+128,16)
	$Indx_RealSize = Dec(StringMid($Indx_RealSize,15,2) & StringMid($Indx_RealSize,13,2) & StringMid($Indx_RealSize,11,2) & StringMid($Indx_RealSize,9,2) & StringMid($Indx_RealSize,7,2) & StringMid($Indx_RealSize,5,2) & StringMid($Indx_RealSize,3,2) & StringMid($Indx_RealSize,1,2))

	$Indx_File_Flags = StringMid($Entry,$NewLocalAttributeOffset+144,16)
	$Indx_File_Flags = StringMid($Indx_File_Flags,15,2) & StringMid($Indx_File_Flags,13,2) & StringMid($Indx_File_Flags,11,2) & StringMid($Indx_File_Flags,9,2)&StringMid($Indx_File_Flags,7,2) & StringMid($Indx_File_Flags,5,2) & StringMid($Indx_File_Flags,3,2) & StringMid($Indx_File_Flags,1,2)
	$Indx_File_Flags = StringMid($Indx_File_Flags,13,8)
	$Indx_File_Flags = _File_Attributes("0x" & $Indx_File_Flags)
#ce
	$Indx_NameLength = StringMid($Entry,$NewLocalAttributeOffset+160,2)
	$Indx_NameLength = Dec($Indx_NameLength)
	$Indx_NameSpace = StringMid($Entry,$NewLocalAttributeOffset+162,2)
	Select
		Case $Indx_NameSpace = "00"	;POSIX
			$Indx_NameSpace = "POSIX"
		Case $Indx_NameSpace = "01"	;WIN32
			$Indx_NameSpace = "WIN32"
		Case $Indx_NameSpace = "02"	;DOS
			$Indx_NameSpace = "DOS"
		Case $Indx_NameSpace = "03"	;DOS+WIN32
			$Indx_NameSpace = "DOS+WIN32"
	EndSelect
	$Indx_FileName = StringMid($Entry,$NewLocalAttributeOffset+164,$Indx_NameLength*2*2)
	$Indx_FileName = _UnicodeHexToStr($Indx_FileName)

	If $MFTReference = $InfoArrShadowMainTarget[0] And $Indx_FileName = $InfoArrShadowMainTarget[1] Then Return 1
	$tmp1 = 164+($Indx_NameLength*2*2)
	Do ; Calculate the length of the padding - 8 byte aligned
		$tmp2 = $tmp1/16
		If Not IsInt($tmp2) Then
			$tmp0 = 2
			$tmp1 += $tmp0
			$tmp3 += $tmp0
		EndIf
	Until IsInt($tmp2)
	$PaddingLength = $tmp3
;	$Padding2 = StringMid($Entry,$NewLocalAttributeOffset+164+($Indx_NameLength*2*2),$PaddingLength)
	If $IndexFlags <> "0000" Then
		$SubNodeVCN = StringMid($Entry,$NewLocalAttributeOffset+164+($Indx_NameLength*2*2)+$PaddingLength,16)
		$SubNodeVCNLength = 16
	Else
		$SubNodeVCN = ""
		$SubNodeVCNLength = 0
	EndIf
;;;	ReDim $IndxEntryNumberArr2[1+$EntryCounter]
;;;	ReDim $IndxMFTReferenceArr2[1+$EntryCounter]
	#cs
	ReDim $IndxMFTRefSeqNoArr[1+$EntryCounter]
	ReDim $IndxIndexFlagsArr[1+$EntryCounter]
	ReDim $IndxMFTReferenceOfParentArr[1+$EntryCounter]
	ReDim $IndxMFTParentRefSeqNoArr[1+$EntryCounter]
	ReDim $IndxCTimeArr[1+$EntryCounter]
	ReDim $IndxATimeArr[1+$EntryCounter]
	ReDim $IndxMTimeArr[1+$EntryCounter]
	ReDim $IndxRTimeArr[1+$EntryCounter]
	ReDim $IndxAllocSizeArr[1+$EntryCounter]
	ReDim $IndxRealSizeArr[1+$EntryCounter]
	ReDim $IndxFileFlagsArr[1+$EntryCounter]
	#ce
;;;	ReDim $IndxFileNameArr2[1+$EntryCounter]
;	ReDim $IndxNameSpaceArr[1+$EntryCounter]
;	ReDim $IndxSubNodeVCNArr[1+$EntryCounter]
;;;	$IndxEntryNumberArr2[$EntryCounter] = $EntryCounter
;;;	$IndxMFTReferenceArr2[$EntryCounter] = $MFTReference
	#cs
	$IndxMFTRefSeqNoArr[$EntryCounter] = $MFTReferenceSeqNo
	$IndxIndexFlagsArr[$EntryCounter] = $IndexFlags
	$IndxMFTReferenceOfParentArr[$EntryCounter] = $MFTReferenceOfParent
	$IndxMFTParentRefSeqNoArr[$EntryCounter] = $MFTReferenceOfParentSeqNo
	$IndxCTimeArr[$EntryCounter] = $Indx_CTime
	$IndxATimeArr[$EntryCounter] = $Indx_ATime
	$IndxMTimeArr[$EntryCounter] = $Indx_MTime
	$IndxRTimeArr[$EntryCounter] = $Indx_RTime
	$IndxAllocSizeArr[$EntryCounter] = $Indx_AllocSize
	$IndxRealSizeArr[$EntryCounter] = $Indx_RealSize
	$IndxFileFlagsArr[$EntryCounter] = $Indx_File_Flags
	#ce
;;;	$IndxFileNameArr2[$EntryCounter] = $Indx_FileName
;	$IndxNameSpaceArr[$EntryCounter] = $Indx_NameSpace
;	$IndxSubNodeVCNArr[$EntryCounter] = $SubNodeVCN
; Work through the rest of the index entries
	$NextEntryOffset = $NewLocalAttributeOffset+164+($Indx_NameLength*2*2)+$PaddingLength+$SubNodeVCNLength
	If $NextEntryOffset+64 >= StringLen($Entry) Then Return 0
	Do
		$EntryCounter += 1
;		ConsoleWrite("$EntryCounter = " & $EntryCounter & @crlf)
		$MFTReference = StringMid($Entry,$NextEntryOffset,12)
;		ConsoleWrite("$MFTReference = " & $MFTReference & @crlf)
		$MFTReference = StringMid($MFTReference,7,2)&StringMid($MFTReference,5,2)&StringMid($MFTReference,3,2)&StringMid($MFTReference,1,2)
;		$MFTReference = StringMid($MFTReference,15,2)&StringMid($MFTReference,13,2)&StringMid($MFTReference,11,2)&StringMid($MFTReference,9,2)&StringMid($MFTReference,7,2)&StringMid($MFTReference,5,2)&StringMid($MFTReference,3,2)&StringMid($MFTReference,1,2)
;		ConsoleWrite("$MFTReference = " & $MFTReference & @crlf)
		$MFTReference = Dec($MFTReference)
#cs
		$MFTReferenceSeqNo = StringMid($Entry,$NextEntryOffset+12,4)
		$MFTReferenceSeqNo = Dec(StringMid($MFTReferenceSeqNo,3,2)&StringMid($MFTReferenceSeqNo,1,2))
		$IndexEntryLength = StringMid($Entry,$NextEntryOffset+16,4)
;		ConsoleWrite("$IndexEntryLength = " & $IndexEntryLength & @crlf)
		$IndexEntryLength = Dec(StringMid($IndexEntryLength,3,2)&StringMid($IndexEntryLength,3,2))
;		ConsoleWrite("$IndexEntryLength = " & $IndexEntryLength & @crlf)
		$OffsetToFileName = StringMid($Entry,$NextEntryOffset+20,4)
;		ConsoleWrite("$OffsetToFileName = " & $OffsetToFileName & @crlf)
		$OffsetToFileName = Dec(StringMid($OffsetToFileName,3,2)&StringMid($OffsetToFileName,3,2))
;		ConsoleWrite("$OffsetToFileName = " & $OffsetToFileName & @crlf)
#ce
		$IndexFlags = StringMid($Entry,$NextEntryOffset+24,4)
;		ConsoleWrite("$IndexFlags = " & $IndexFlags & @crlf)
#cs
		$Padding = StringMid($Entry,$NextEntryOffset+28,4)
;		ConsoleWrite("$Padding = " & $Padding & @crlf)
		$MFTReferenceOfParent = StringMid($Entry,$NextEntryOffset+32,12)
;		ConsoleWrite("$MFTReferenceOfParent = " & $MFTReferenceOfParent & @crlf)
		$MFTReferenceOfParent = StringMid($MFTReferenceOfParent,7,2)&StringMid($MFTReferenceOfParent,5,2)&StringMid($MFTReferenceOfParent,3,2)&StringMid($MFTReferenceOfParent,1,2)
;		$MFTReferenceOfParent = StringMid($MFTReferenceOfParent,15,2)&StringMid($MFTReferenceOfParent,13,2)&StringMid($MFTReferenceOfParent,11,2)&StringMid($MFTReferenceOfParent,9,2)&StringMid($MFTReferenceOfParent,7,2)&StringMid($MFTReferenceOfParent,5,2)&StringMid($MFTReferenceOfParent,3,2)&StringMid($MFTReferenceOfParent,1,2)
;		ConsoleWrite("$MFTReferenceOfParent = " & $MFTReferenceOfParent & @crlf)
		$MFTReferenceOfParent = Dec($MFTReferenceOfParent)
		$MFTReferenceOfParentSeqNo = StringMid($Entry,$NextEntryOffset+44,4)
		$MFTReferenceOfParentSeqNo = Dec(StringMid($MFTReferenceOfParentSeqNo,3,2) & StringMid($MFTReferenceOfParentSeqNo,3,2))

		$Indx_CTime = StringMid($Entry,$NextEntryOffset+48,16)
		$Indx_CTime = StringMid($Indx_CTime,15,2) & StringMid($Indx_CTime,13,2) & StringMid($Indx_CTime,11,2) & StringMid($Indx_CTime,9,2) & StringMid($Indx_CTime,7,2) & StringMid($Indx_CTime,5,2) & StringMid($Indx_CTime,3,2) & StringMid($Indx_CTime,1,2)
		$Indx_CTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_CTime)
		$Indx_CTime = _WinTime_UTCFileTimeFormat(Dec($Indx_CTime)-$tDelta,$DateTimeFormat,2)
		$Indx_CTime = $Indx_CTime & ":" & _FillZero(StringRight($Indx_CTime_tmp,4))
;		ConsoleWrite("$Indx_CTime = " & $Indx_CTime & @crlf)
;
		$Indx_ATime = StringMid($Entry,$NextEntryOffset+64,16)
		$Indx_ATime = StringMid($Indx_ATime,15,2) & StringMid($Indx_ATime,13,2) & StringMid($Indx_ATime,11,2) & StringMid($Indx_ATime,9,2) & StringMid($Indx_ATime,7,2) & StringMid($Indx_ATime,5,2) & StringMid($Indx_ATime,3,2) & StringMid($Indx_ATime,1,2)
		$Indx_ATime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_ATime)
		$Indx_ATime = _WinTime_UTCFileTimeFormat(Dec($Indx_ATime)-$tDelta,$DateTimeFormat,2)
		$Indx_ATime = $Indx_ATime & ":" & _FillZero(StringRight($Indx_ATime_tmp,4))
;		ConsoleWrite("$Indx_ATime = " & $Indx_ATime & @crlf)
;
		$Indx_MTime = StringMid($Entry,$NextEntryOffset+80,16)
		$Indx_MTime = StringMid($Indx_MTime,15,2) & StringMid($Indx_MTime,13,2) & StringMid($Indx_MTime,11,2) & StringMid($Indx_MTime,9,2) & StringMid($Indx_MTime,7,2) & StringMid($Indx_MTime,5,2) & StringMid($Indx_MTime,3,2) & StringMid($Indx_MTime,1,2)
		$Indx_MTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_MTime)
		$Indx_MTime = _WinTime_UTCFileTimeFormat(Dec($Indx_MTime)-$tDelta,$DateTimeFormat,2)
		$Indx_MTime = $Indx_MTime & ":" & _FillZero(StringRight($Indx_MTime_tmp,4))
;		ConsoleWrite("$Indx_MTime = " & $Indx_MTime & @crlf)
;
		$Indx_RTime = StringMid($Entry,$NextEntryOffset+96,16)
		$Indx_RTime = StringMid($Indx_RTime,15,2) & StringMid($Indx_RTime,13,2) & StringMid($Indx_RTime,11,2) & StringMid($Indx_RTime,9,2) & StringMid($Indx_RTime,7,2) & StringMid($Indx_RTime,5,2) & StringMid($Indx_RTime,3,2) & StringMid($Indx_RTime,1,2)
		$Indx_RTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_RTime)
		$Indx_RTime = _WinTime_UTCFileTimeFormat(Dec($Indx_RTime)-$tDelta,$DateTimeFormat,2)
		$Indx_RTime = $Indx_RTime & ":" & _FillZero(StringRight($Indx_RTime_tmp,4))
;		ConsoleWrite("$Indx_RTime = " & $Indx_RTime & @crlf)
;
		$Indx_AllocSize = StringMid($Entry,$NextEntryOffset+112,16)
		$Indx_AllocSize = Dec(StringMid($Indx_AllocSize,15,2) & StringMid($Indx_AllocSize,13,2) & StringMid($Indx_AllocSize,11,2) & StringMid($Indx_AllocSize,9,2) & StringMid($Indx_AllocSize,7,2) & StringMid($Indx_AllocSize,5,2) & StringMid($Indx_AllocSize,3,2) & StringMid($Indx_AllocSize,1,2))
;		ConsoleWrite("$Indx_AllocSize = " & $Indx_AllocSize & @crlf)
		$Indx_RealSize = StringMid($Entry,$NextEntryOffset+128,16)
		$Indx_RealSize = Dec(StringMid($Indx_RealSize,15,2) & StringMid($Indx_RealSize,13,2) & StringMid($Indx_RealSize,11,2) & StringMid($Indx_RealSize,9,2) & StringMid($Indx_RealSize,7,2) & StringMid($Indx_RealSize,5,2) & StringMid($Indx_RealSize,3,2) & StringMid($Indx_RealSize,1,2))
;		ConsoleWrite("$Indx_RealSize = " & $Indx_RealSize & @crlf)

		$Indx_File_Flags = StringMid($Entry,$NextEntryOffset+144,16)
;		ConsoleWrite("$Indx_File_Flags = " & $Indx_File_Flags & @crlf)
		$Indx_File_Flags = StringMid($Indx_File_Flags,15,2) & StringMid($Indx_File_Flags,13,2) & StringMid($Indx_File_Flags,11,2) & StringMid($Indx_File_Flags,9,2)&StringMid($Indx_File_Flags,7,2) & StringMid($Indx_File_Flags,5,2) & StringMid($Indx_File_Flags,3,2) & StringMid($Indx_File_Flags,1,2)
;		ConsoleWrite("$Indx_File_Flags = " & $Indx_File_Flags & @crlf)
		$Indx_File_Flags = StringMid($Indx_File_Flags,13,8)
		$Indx_File_Flags = _File_Attributes("0x" & $Indx_File_Flags)
;		ConsoleWrite("$Indx_File_Flags = " & $Indx_File_Flags & @crlf)
#ce
		$Indx_NameLength = StringMid($Entry,$NextEntryOffset+160,2)
		$Indx_NameLength = Dec($Indx_NameLength)
;		ConsoleWrite("$Indx_NameLength = " & $Indx_NameLength & @crlf)
		$Indx_NameSpace = StringMid($Entry,$NextEntryOffset+162,2)
;		ConsoleWrite("$Indx_NameSpace = " & $Indx_NameSpace & @crlf)
		Select
			Case $Indx_NameSpace = "00"	;POSIX
				$Indx_NameSpace = "POSIX"
			Case $Indx_NameSpace = "01"	;WIN32
				$Indx_NameSpace = "WIN32"
			Case $Indx_NameSpace = "02"	;DOS
				$Indx_NameSpace = "DOS"
			Case $Indx_NameSpace = "03"	;DOS+WIN32
				$Indx_NameSpace = "DOS+WIN32"
		EndSelect
		$Indx_FileName = StringMid($Entry,$NextEntryOffset+164,$Indx_NameLength*2*2)
;		ConsoleWrite("$Indx_FileName = " & $Indx_FileName & @crlf)
		$Indx_FileName = _UnicodeHexToStr($Indx_FileName)
		If $MFTReference = $InfoArrShadowMainTarget[0] And $Indx_FileName = $InfoArrShadowMainTarget[1] Then Return 1
		;ConsoleWrite("$Indx_FileName = " & $Indx_FileName & @crlf)
		$tmp0 = 0
		$tmp2 = 0
		$tmp3 = 0
		$tmp1 = 164+($Indx_NameLength*2*2)
		Do ; Calculate the length of the padding - 8 byte aligned
			$tmp2 = $tmp1/16
			If Not IsInt($tmp2) Then
				$tmp0 = 2
				$tmp1 += $tmp0
				$tmp3 += $tmp0
			EndIf
		Until IsInt($tmp2)
		$PaddingLength = $tmp3
;		ConsoleWrite("$PaddingLength = " & $PaddingLength & @crlf)
		$Padding = StringMid($Entry,$NextEntryOffset+164+($Indx_NameLength*2*2),$PaddingLength)
;		ConsoleWrite("$Padding = " & $Padding & @crlf)
		If $IndexFlags <> "0000" Then
			$SubNodeVCN = StringMid($Entry,$NextEntryOffset+164+($Indx_NameLength*2*2)+$PaddingLength,16)
			$SubNodeVCNLength = 16
		Else
			$SubNodeVCN = ""
			$SubNodeVCNLength = 0
		EndIf
;		ConsoleWrite("$SubNodeVCN = " & $SubNodeVCN & @crlf)
		$NextEntryOffset = $NextEntryOffset+164+($Indx_NameLength*2*2)+$PaddingLength+$SubNodeVCNLength
;;;		ReDim $IndxEntryNumberArr2[1+$EntryCounter]
;;;		ReDim $IndxMFTReferenceArr2[1+$EntryCounter]
		#cs
		Redim $IndxMFTRefSeqNoArr[1+$EntryCounter]
		ReDim $IndxIndexFlagsArr[1+$EntryCounter]
		ReDim $IndxMFTReferenceOfParentArr[1+$EntryCounter]
		ReDim $IndxMFTParentRefSeqNoArr[1+$EntryCounter]
		ReDim $IndxCTimeArr[1+$EntryCounter]
		ReDim $IndxATimeArr[1+$EntryCounter]
		ReDim $IndxMTimeArr[1+$EntryCounter]
		ReDim $IndxRTimeArr[1+$EntryCounter]
		ReDim $IndxAllocSizeArr[1+$EntryCounter]
		ReDim $IndxRealSizeArr[1+$EntryCounter]
		ReDim $IndxFileFlagsArr[1+$EntryCounter]
		#ce
;;;		ReDim $IndxFileNameArr2[1+$EntryCounter]
;		ReDim $IndxNameSpaceArr[1+$EntryCounter]
;		ReDim $IndxSubNodeVCNArr[1+$EntryCounter]
;;;		$IndxEntryNumberArr2[$EntryCounter] = $EntryCounter
;;;		$IndxMFTReferenceArr2[$EntryCounter] = $MFTReference
		#cs
		$IndxMFTRefSeqNoArr[$EntryCounter] = $MFTReferenceSeqNo
		$IndxIndexFlagsArr[$EntryCounter] = $IndexFlags
		$IndxMFTReferenceOfParentArr[$EntryCounter] = $MFTReferenceOfParent
		$IndxMFTParentRefSeqNoArr[$EntryCounter] = $MFTReferenceOfParentSeqNo
		$IndxCTimeArr[$EntryCounter] = $Indx_CTime
		$IndxATimeArr[$EntryCounter] = $Indx_ATime
		$IndxMTimeArr[$EntryCounter] = $Indx_MTime
		$IndxRTimeArr[$EntryCounter] = $Indx_RTime
		$IndxAllocSizeArr[$EntryCounter] = $Indx_AllocSize
		$IndxRealSizeArr[$EntryCounter] = $Indx_RealSize
		$IndxFileFlagsArr[$EntryCounter] = $Indx_File_Flags
		#ce
;;;		$IndxFileNameArr2[$EntryCounter] = $Indx_FileName
;		$IndxNameSpaceArr[$EntryCounter] = $Indx_NameSpace
;		$IndxSubNodeVCNArr[$EntryCounter] = $SubNodeVCN
;		_ArrayDisplay($IndxFileNameArr,"$IndxFileNameArr")
	Until $NextEntryOffset+32 >= StringLen($Entry)
	Return 0
EndFunc

Func _SetArrays()
	$SIArrValue[0][0] = "Field name:"
	$SIArrValue[1][0] = "HEADER_Flags"
	$SIArrValue[2][0] = "CTime"
	$SIArrValue[3][0] = "ATime"
	$SIArrValue[4][0] = "MTime"
	$SIArrValue[5][0] = "RTime"
	$SIArrValue[6][0] = "DOS File Permissions"
	$SIArrValue[7][0] = "Max Versions"
	$SIArrValue[8][0] = "Version Number"
	$SIArrValue[9][0] = "Class ID"
	$SIArrValue[10][0] = "Owner ID"
	$SIArrValue[11][0] = "Security ID"
	$SIArrValue[12][0] = "USN"


	$FNArrValue[0][0] = "Field name"
	$FNArrValue[1][0] = "ParentReferenceNo"
	$FNArrValue[2][0] = "ParentSequenceNo"
	$FNArrValue[3][0] = "CTime"
	$FNArrValue[4][0] = "ATime"
	$FNArrValue[5][0] = "MTime"
	$FNArrValue[6][0] = "RTime"
	$FNArrValue[7][0] = "AllocSize"
	$FNArrValue[8][0] = "RealSize"
	$FNArrValue[9][0] = "Flags"
	$FNArrValue[10][0] = "NameLength"
	$FNArrValue[11][0] = "NameType"
	$FNArrValue[12][0] = "NameSpace"
	$FNArrValue[13][0] = "FileName"

	$IndxEntryNumberArr[0] = "Entry number"
	$IndxMFTReferenceArr[0] = "MFTReference"
	$IndxMFTRefSeqNoArr[0] = "MFTReference SeqNo"
;	$IndxIndexFlagsArr[0] = "IndexFlags"
	$IndxMFTReferenceOfParentArr[0] = "Parent MFTReference"
	$IndxMFTParentRefSeqNoArr[0] = "Parent MFTReference SeqNo"
	$IndxCTimeArr[0] = "CTime"
	$IndxATimeArr[0] = "ATime"
	$IndxMTimeArr[0] = "MTime"
	$IndxRTimeArr[0] = "RTime"
;	$IndxAllocSizeArr[0] = "AllocSize"
;	$IndxRealSizeArr[0] = "RealSize"
;	$IndxFileFlagsArr[0] = "File flags"
	$IndxFileNameArr[0] = "FileName"
;	$IndxNameSpaceArr[0] = "NameSpace"
;	$IndxSubNodeVCNArr[0] = "SubNodeVCN"
EndFunc

Func _FillZero($inp)
	Local $inplen, $out, $tmp = ""
	$inplen = StringLen($inp)
	For $i = 1 To 4-$inplen
		$tmp &= "0"
	Next
	$out = $tmp & $inp
	Return $out
EndFunc

; start: by Ascend4nt -----------------------------
Func _WinTime_GetUTCToLocalFileTimeDelta()
	Local $iUTCFileTime=864000000000		; exactly 24 hours from the origin (although 12 hours would be more appropriate (max variance = 12))
	$iLocalFileTime=_WinTime_UTCFileTimeToLocalFileTime($iUTCFileTime)
	If @error Then Return SetError(@error,@extended,-1)
	Return $iLocalFileTime-$iUTCFileTime	; /36000000000 = # hours delta (effectively giving the offset in hours from UTC/GMT)
EndFunc

Func _WinTime_UTCFileTimeToLocalFileTime($iUTCFileTime)
	If $iUTCFileTime<0 Then Return SetError(1,0,-1)
	Local $aRet=DllCall($_COMMON_KERNEL32DLL,"bool","FileTimeToLocalFileTime","uint64*",$iUTCFileTime,"uint64*",0)
	If @error Then Return SetError(2,@error,-1)
	If Not $aRet[0] Then Return SetError(3,0,-1)
	Return $aRet[2]
EndFunc

Func _WinTime_UTCFileTimeFormat($iUTCFileTime,$iFormat=4,$iPrecision=0,$bAMPMConversion=False)
;~ 	If $iUTCFileTime<0 Then Return SetError(1,0,"")	; checked in below call

	; First convert file time (UTC-based file time) to 'local file time'
	Local $iLocalFileTime=_WinTime_UTCFileTimeToLocalFileTime($iUTCFileTime)
	If @error Then Return SetError(@error,@extended,"")
	; Rare occassion: a filetime near the origin (January 1, 1601!!) is used,
	;	causing a negative result (for some timezones). Return as invalid param.
	If $iLocalFileTime<0 Then Return SetError(1,0,"")

	; Then convert file time to a system time array & format & return it
	Local $vReturn=_WinTime_LocalFileTimeFormat($iLocalFileTime,$iFormat,$iPrecision,$bAMPMConversion)
	Return SetError(@error,@extended,$vReturn)
EndFunc

Func _WinTime_LocalFileTimeFormat($iLocalFileTime,$iFormat=4,$iPrecision=0,$bAMPMConversion=False)
;~ 	If $iLocalFileTime<0 Then Return SetError(1,0,"")	; checked in below call

	; Convert file time to a system time array & return result
	Local $aSysTime=_WinTime_LocalFileTimeToSystemTime($iLocalFileTime)
	If @error Then Return SetError(@error,@extended,"")

	; Return only the SystemTime array?
	If $iFormat=0 Then Return $aSysTime

	Local $vReturn=_WinTime_FormatTime($aSysTime[0],$aSysTime[1],$aSysTime[2],$aSysTime[3], _
		$aSysTime[4],$aSysTime[5],$aSysTime[6],$aSysTime[7],$iFormat,$iPrecision,$bAMPMConversion)
	Return SetError(@error,@extended,$vReturn)
EndFunc

Func _WinTime_LocalFileTimeToSystemTime($iLocalFileTime)
	Local $aRet,$stSysTime,$aSysTime[8]=[-1,-1,-1,-1,-1,-1,-1,-1]

	; Negative values unacceptable
	If $iLocalFileTime<0 Then Return SetError(1,0,$aSysTime)

	; SYSTEMTIME structure [Year,Month,DayOfWeek,Day,Hour,Min,Sec,Milliseconds]
	$stSysTime=DllStructCreate("ushort[8]")

	$aRet=DllCall($_COMMON_KERNEL32DLL,"bool","FileTimeToSystemTime","uint64*",$iLocalFileTime,"ptr",DllStructGetPtr($stSysTime))
	If @error Then Return SetError(2,@error,$aSysTime)
	If Not $aRet[0] Then Return SetError(3,0,$aSysTime)
	Dim $aSysTime[8]=[DllStructGetData($stSysTime,1,1),DllStructGetData($stSysTime,1,2),DllStructGetData($stSysTime,1,4),DllStructGetData($stSysTime,1,5), _
		DllStructGetData($stSysTime,1,6),DllStructGetData($stSysTime,1,7),DllStructGetData($stSysTime,1,8),DllStructGetData($stSysTime,1,3)]
	Return $aSysTime
EndFunc

Func _WinTime_FormatTime($iYear,$iMonth,$iDay,$iHour,$iMin,$iSec,$iMilSec,$iDayOfWeek,$iFormat=4,$iPrecision=0,$bAMPMConversion=False)
	Local Static $_WT_aMonths[12]=["January","February","March","April","May","June","July","August","September","October","November","December"]
	Local Static $_WT_aDays[7]=["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]

	If Not $iFormat Or $iMonth<1 Or $iMonth>12 Or $iDayOfWeek>6 Then Return SetError(1,0,"")

	; Pad MM,DD,HH,MM,SS,MSMSMSMS as necessary
	Local $sMM=StringRight(0&$iMonth,2),$sDD=StringRight(0&$iDay,2),$sMin=StringRight(0&$iMin,2)
	; $sYY = $iYear	; (no padding)
	;	[technically Year can be 1-x chars - but this is generally used for 4-digit years. And SystemTime only goes up to 30827/30828]
	Local $sHH,$sSS,$sMS,$sAMPM

	; 'Extra precision 1': +SS (Seconds)
	If $iPrecision Then
		$sSS=StringRight(0&$iSec,2)
		; 'Extra precision 2': +MSMSMSMS (Milliseconds)
		If $iPrecision>1 Then
;			$sMS=StringRight('000'&$iMilSec,4)
			$sMS=StringRight('000'&$iMilSec,3);Fixed an erronous 0 in front of the milliseconds
		Else
			$sMS=""
		EndIf
	Else
		$sSS=""
		$sMS=""
	EndIf
	If $bAMPMConversion Then
		If $iHour>11 Then
			$sAMPM=" PM"
			; 12 PM will cause 12-12 to equal 0, so avoid the calculation:
			If $iHour=12 Then
				$sHH="12"
			Else
				$sHH=StringRight(0&($iHour-12),2)
			EndIf
		Else
			$sAMPM=" AM"
			If $iHour Then
				$sHH=StringRight(0&$iHour,2)
			Else
			; 00 military = 12 AM
				$sHH="12"
			EndIf
		EndIf
	Else
		$sAMPM=""
		$sHH=StringRight(0 & $iHour,2)
	EndIf

	Local $sDateTimeStr,$aReturnArray[3]

	; Return an array? [formatted string + "Month" + "DayOfWeek"]
	If BitAND($iFormat,0x10) Then
		$aReturnArray[1]=$_WT_aMonths[$iMonth-1]
		If $iDayOfWeek>=0 Then
			$aReturnArray[2]=$_WT_aDays[$iDayOfWeek]
		Else
			$aReturnArray[2]=""
		EndIf
		; Strip the 'array' bit off (array[1] will now indicate if an array is to be returned)
		$iFormat=BitAND($iFormat,0xF)
	Else
		; Signal to below that the array isn't to be returned
		$aReturnArray[1]=""
	EndIf

	; Prefix with "DayOfWeek "?
	If BitAND($iFormat,8) Then
		If $iDayOfWeek<0 Then Return SetError(1,0,"")	; invalid
		$sDateTimeStr=$_WT_aDays[$iDayOfWeek]&', '
		; Strip the 'DayOfWeek' bit off
		$iFormat=BitAND($iFormat,0x7)
	Else
		$sDateTimeStr=""
	EndIf

	If $iFormat<2 Then
		; Basic String format: YYYYMMDDHHMM[SS[MSMSMSMS[ AM/PM]]]
		$sDateTimeStr&=$iYear&$sMM&$sDD&$sHH&$sMin&$sSS&$sMS&$sAMPM
	Else
		; one of 4 formats which ends with " HH:MM[:SS[:MSMSMSMS[ AM/PM]]]"
		Switch $iFormat
			; /, : Format - MM/DD/YYYY
			Case 2
				$sDateTimeStr&=$sMM&'/'&$sDD&'/'
			; /, : alt. Format - DD/MM/YYYY
			Case 3
				$sDateTimeStr&=$sDD&'/'&$sMM&'/'
			; "Month DD, YYYY" format
			Case 4
				$sDateTimeStr&=$_WT_aMonths[$iMonth-1]&' '&$sDD&', '
			; "DD Month YYYY" format
			Case 5
				$sDateTimeStr&=$sDD&' '&$_WT_aMonths[$iMonth-1]&' '
			Case 6
				$sDateTimeStr&=$iYear&'-'&$sMM&'-'&$sDD
				$iYear=''
			Case Else
				Return SetError(1,0,"")
		EndSwitch
		$sDateTimeStr&=$iYear&' '&$sHH&':'&$sMin
		If $iPrecision Then
			$sDateTimeStr&=':'&$sSS
			If $iPrecision>1 Then $sDateTimeStr&=':'&$sMS
		EndIf
		$sDateTimeStr&=$sAMPM
	EndIf
	If $aReturnArray[1]<>"" Then
		$aReturnArray[0]=$sDateTimeStr
		Return $aReturnArray
	EndIf
	Return $sDateTimeStr
EndFunc

Func _WinTime_SystemTimeToLocalFileTime($iYear,$iMonth,$iDay,$iHour,$iMin,$iSec,$iMilSec,$iDayOfWeek=-1)
	; Least\Greatest year check
	If $iYear<1601 Or $iYear>30827 Then Return SetError(1,0,-1)
	; SYSTEMTIME structure [Year,Month,DayOfWeek,Day,Hour,Min,Sec,Milliseconds]
	Local $stSysTime=DllStructCreate("ushort[8]")
	DllStructSetData($stSysTime,1,$iYear,1)
	DllStructSetData($stSysTime,1,$iMonth,2)
	DllStructSetData($stSysTime,1,$iDayOfWeek,3)
	DllStructSetData($stSysTime,1,$iDay,4)
	DllStructSetData($stSysTime,1,$iHour,5)
	DllStructSetData($stSysTime,1,$iMin,6)
	DllStructSetData($stSysTime,1,$iSec,7)
	DllStructSetData($stSysTime,1,$iMilSec,8)
	Local $aRet=DllCall($_COMMON_KERNEL32DLL,"bool","SystemTimeToFileTime","ptr",DllStructGetPtr($stSysTime),"int64*",0)
	If @error Then Return SetError(2,@error,-1)
	If Not $aRet[0] Then Return SetError(3,0,-1)
	Return $aRet[2]
EndFunc
; end: by Ascend4nt ----------------------------

Func _DecodeNameQ($NameQ)
	For $name = 1 To UBound($NameQ) - 1
		$NameString = $NameQ[$name]
		If $NameString = "" Then ContinueLoop
		$FN_AllocSize = Dec(_SwapEndian(StringMid($NameString,129,16)),2)
		$FN_RealSize = Dec(_SwapEndian(StringMid($NameString,145,16)),2)
		$FN_NameLength = Dec(StringMid($NameString,177,2))
		$FN_NameSpace = StringMid($NameString,179,2)
		Select
			Case $FN_NameSpace = '00'
				$FN_NameSpace = 'POSIX'
			Case $FN_NameSpace = '01'
				$FN_NameSpace = 'WIN32'
			Case $FN_NameSpace = '02'
				$FN_NameSpace = 'DOS'
			Case $FN_NameSpace = '03'
				$FN_NameSpace = 'DOS+WIN32'
			Case Else
				$FN_NameSpace = 'UNKNOWN'
		EndSelect
		$FN_FileName = StringMid($NameString,181,$FN_NameLength*4)
		$FN_FileName = _UnicodeHexToStr($FN_FileName)
		If StringLen($FN_FileName) <> $FN_NameLength Then $INVALID_FILENAME = 1
	Next
	Return
EndFunc

Func _WinAPI_LockVolume($iVolume)
	$hFile = _WinAPI_CreateFileEx('\\.\' & $iVolume, 3, BitOR($GENERIC_READ,$GENERIC_WRITE), 0x7)
	If Not $hFile Then
		Return SetError(1, 0, 0)
	EndIf
	Local $Ret = DllCall('kernel32.dll', 'int', 'DeviceIoControl', 'ptr', $hFile, 'dword', $FSCTL_LOCK_VOLUME, 'ptr', 0, 'dword', 0, 'ptr', 0, 'dword', 0, 'dword*', 0, 'ptr', 0)
	If (@error) Or (Not $Ret[0]) Then
		$Ret = 0
	EndIf
	If Not IsArray($Ret) Then
		Return SetError(2, 0, 0)
	EndIf
;	Return $Ret[0]
;	Return $Ret
	Return $hFile
EndFunc   ;==>_WinAPI_LockVolume

Func _WinAPI_UnLockVolume($hFile)
	If Not $hFile Then
		ConsoleWrite("Error in _WinAPI_CreateFileEx when unlocking." & @CRLF)
		Return SetError(1, 0, 0)
	EndIf
	Local $Ret = DllCall('kernel32.dll', 'int', 'DeviceIoControl', 'ptr', $hFile, 'dword', $FSCTL_UNLOCK_VOLUME, 'ptr', 0, 'dword', 0, 'ptr', 0, 'dword', 0, 'dword*', 0, 'ptr', 0)
	If (@error) Or (Not $Ret[0]) Then
		$Ret = 0
	EndIf
	If Not IsArray($Ret) Then
		Return SetError(2, 0, 0)
	EndIf
	Return $Ret[0]
EndFunc   ;==>_WinAPI_UnLockVolume

Func _WinAPI_DismountVolume($hFile)
	If Not $hFile Then
		ConsoleWrite("Error in _WinAPI_CreateFileEx when dismounting." & @CRLF)
		Return SetError(1, 0, 0)
	EndIf
	Local $Ret = DllCall('kernel32.dll', 'int', 'DeviceIoControl', 'ptr', $hFile, 'dword', $FSCTL_DISMOUNT_VOLUME, 'ptr', 0, 'dword', 0, 'ptr', 0, 'dword', 0, 'dword*', 0, 'ptr', 0)
	If (@error) Or (Not $Ret[0]) Then
		$Ret = 0
	EndIf
	If Not IsArray($Ret) Then
		Return SetError(2, 0, 0)
	EndIf
	Return $Ret[0]
EndFunc   ;==>_WinAPI_DismountVolume

Func _WinAPI_DismountVolumeMod($iVolume)
	$hFile = _WinAPI_CreateFileEx('\\.\' & $iVolume, 3, BitOR($GENERIC_READ,$GENERIC_WRITE), 0x7)
	If Not $hFile Then
		ConsoleWrite("Error in _WinAPI_CreateFileEx when dismounting." & @CRLF)
		Return SetError(1, 0, 0)
	EndIf
	Local $Ret = DllCall('kernel32.dll', 'int', 'DeviceIoControl', 'ptr', $hFile, 'dword', $FSCTL_DISMOUNT_VOLUME, 'ptr', 0, 'dword', 0, 'ptr', 0, 'dword', 0, 'dword*', 0, 'ptr', 0)
	If (@error) Or (Not $Ret[0]) Then
		Return SetError(3, 0, 0)
;		$Ret = 0
	EndIf
	If Not IsArray($Ret) Then
		Return SetError(2, 0, 0)
	EndIf
;	Return $Ret[0]
	Return $hFile
EndFunc   ;==>_WinAPI_DismountVolumeMod

Func _PopulateShadowTimestampsArray($Counter)
	$FromHarddiskVolumeShadowCopyXArr[2][$Counter] = $HEADER_MFTREcordNumber
	$FromHarddiskVolumeShadowCopyXArr[3][$Counter] = $SIArrValue[2][1]
	$FromHarddiskVolumeShadowCopyXArr[4][$Counter] = $SIArrValue[3][1]
	$FromHarddiskVolumeShadowCopyXArr[5][$Counter] = $SIArrValue[4][1]
	$FromHarddiskVolumeShadowCopyXArr[6][$Counter] = $SIArrValue[5][1]
	For $testno = 1 To $FN_Number
		$FromHarddiskVolumeShadowCopyXArr[1][$Counter] = $FNArrValue[13][$testno]
		$FromHarddiskVolumeShadowCopyXArr[7][$Counter] = $FNArrValue[3][$testno]
		$FromHarddiskVolumeShadowCopyXArr[8][$Counter] = $FNArrValue[4][$testno]
		$FromHarddiskVolumeShadowCopyXArr[9][$Counter] = $FNArrValue[5][$testno]
		$FromHarddiskVolumeShadowCopyXArr[10][$Counter] = $FNArrValue[6][$testno]
	Next
	If $ParentMode=1 Or $IsRawShadowCopy=0 Then
		For $i = 0 To Ubound($IndxCTimeFromParentArr)-1
;			ConsoleWrite("Timestamps from INDX of parent (indexed $STANDARD_INFORMATION):" & @CRLF)
			$FromHarddiskVolumeShadowCopyXArr[11][$Counter] = $IndxCTimeFromParentArr[$i]
			$FromHarddiskVolumeShadowCopyXArr[12][$Counter] = $IndxATimeFromParentArr[$i]
			$FromHarddiskVolumeShadowCopyXArr[13][$Counter] = $IndxMTimeFromParentArr[$i]
			$FromHarddiskVolumeShadowCopyXArr[14][$Counter] = $IndxRTimeFromParentArr[$i]
		Next
	Else
;		ConsoleWrite("Timestamp dump from INDX of parent is not possible when target is Root Directory (.) or not yet when Shadows Copy read mode is raw" & @CRLF)
	EndIf
;	Global $IndxEntryNumberArr[1],$IndxMFTReferenceArr[1],$IndxIndexFlagsArr[1],$IndxMFTReferenceOfParentArr[1],$IndxCTimeArr[1],$IndxATimeArr[1],$IndxMTimeArr[1],$IndxRTimeArr[1],$IndxAllocSizeArr[1],$IndxRealSizeArr[1],$IndxFileFlagsArr[1],$IndxFileNameArr[1],$IndxSubNodeVCNArr[1],$IndxNameSpaceArr[1]
	Global $IndxEntryNumberArr[1],$IndxMFTReferenceArr[1],$IndxMFTReferenceOfParentArr[1],$IndxCTimeArr[1],$IndxATimeArr[1],$IndxMTimeArr[1],$IndxRTimeArr[1],$IndxFileNameArr[1]
EndFunc

Func _DumpTimestampsToConsole()
	ConsoleWrite(@CRLF)
	ConsoleWrite("Header SequenceNo: " & $Header_SequenceNo & @CRLF)
	ConsoleWrite("Header HardLinkCount: "  & $Header_HardLinkCount & @CRLF & @CRLF)
	ConsoleWrite("$STANDARD_INFORMATION" & @CRLF)
	ConsoleWrite("CreationTime: " & $SIArrValue[2][1] & @CRLF)
	ConsoleWrite("LastWriteTime: " & $SIArrValue[3][1] & @CRLF)
	ConsoleWrite("ChangeTime(MFT): " & $SIArrValue[4][1] & @CRLF)
	ConsoleWrite("LastAccessTime: " & $SIArrValue[5][1] & @CRLF & @CRLF)
	For $testno = 1 To $FN_Number
		ConsoleWrite("$FILE_NAME " & $testno & @CRLF)
		ConsoleWrite("FileName: " & $FNArrValue[13][$testno] & @CRLF)
		ConsoleWrite("ParentReferenceNo: " & $FNArrValue[1][$testno] & @CRLF)
		ConsoleWrite("CreationTime: " & $FNArrValue[3][$testno] & @CRLF)
		ConsoleWrite("LastWriteTime: " & $FNArrValue[4][$testno] & @CRLF)
		ConsoleWrite("ChangeTime(MFT): " & $FNArrValue[5][$testno] & @CRLF)
		ConsoleWrite("LastAccessTime: " & $FNArrValue[6][$testno] & @CRLF & @CRLF)
	Next
	If $ParentMode=1 Or $IsRawShadowCopy=0 Then
		ConsoleWrite("Timestamps from INDX of parent (indexed $STANDARD_INFORMATION):" & @CRLF)
		For $i = 0 To Ubound($IndxCTimeFromParentArr)-1
			ConsoleWrite("FileName: " & $IndxFileNameFromParentArr[$i] & @CRLF)
			ConsoleWrite("Header ReferenceNo: " & $IndxMFTReferenceFromParentArr[$i] & @CRLF)
			ConsoleWrite("Header ParentReferenceNo: " & $IndxMFTReferenceOfParentFromParentArr[$i] & @CRLF)
			ConsoleWrite("CreationTime: " & $IndxCTimeFromParentArr[$i] & @CRLF)
			ConsoleWrite("LastWriteTime: " & $IndxATimeFromParentArr[$i] & @CRLF)
			ConsoleWrite("ChangeTime(MFT): " & $IndxMTimeFromParentArr[$i] & @CRLF)
			ConsoleWrite("LastAccessTime: " & $IndxRTimeFromParentArr[$i] & @CRLF & @CRLF)
		Next
	Else
		If $InfoArrShadowMainTarget[0] = 5 Then
			ConsoleWrite("Timestamp dump from INDX of parent is not possible when target is Root Directory (.)" & @CRLF)
		ElseIf $IsRawShadowCopy Then
			ConsoleWrite("Timestamp dump from INDX of parent is not possible when Shadows Copy read mode is raw" & @CRLF)
		EndIf
	EndIf
;	_ArrayDisplay($SIArrValue,"$SIArrValue")
EndFunc

Func _RawModIndx($DiskOffset,$NumberOfRecords,$CurrentRef,$TargetRef)
	Local $nBytes,$CorrectIndx=1,$NextEntryOffset,$CurrentRecord,$Success=0,$hFile,$Counter2=0

	For $CurrentRecord = 0 To $NumberOfRecords-1
		Local $IndxHdrUpdateSeqArrOffset,$IndxHdrUpdateSeqArrSize,$IndxHdrUpdSeqArr,$IndxHdrUpdSeqArrPart0,$IndxHdrUpdSeqArrPart1,$IndxHdrUpdSeqArrPart2,$IndxHdrUpdSeqArrPart3,$IndxHdrUpdSeqArrPart4,$IndxHdrUpdSeqArrPart5,$IndxHdrUpdSeqArrPart6,$IndxHdrUpdSeqArrPart7,$IndxHdrUpdSeqArrPart8
		Local $IndxRecordEnd1,$IndxRecordEnd2,$IndxRecordEnd3,$IndxRecordEnd4,$IndxRecordEnd5,$IndxRecordEnd6,$IndxRecordEnd7,$IndxRecordEnd8,$IndxRecordSize,$IndxHeaderSize,$IsNotLeafNode,$SizeofIndxRecord
		Local $NewLocalAttributeOffset,$MFTReference,$MFTReferenceSeqNo,$OffsetToFileName,$IndexFlags,$MFTReferenceOfParent,$MFTReferenceOfParentSeqNo,$Indx_CTime,$Indx_CTime_tmp,$Indx_ATime,$Indx_ATime_tmp
		Local $Indx_MTime,$Indx_MTime_tmp,$Indx_RTime,$Indx_RTime_tmp,$Indx_AllocSize,$Indx_RealSize,$Indx_File_Flags,$Indx_NameLength,$Indx_NameSpace,$Indx_FileName
		Local $IndexEntryLength,$SubNodeVCN,$SubNodeVCNLength,$tmp0=0,$tmp1=0,$tmp2=0,$tmp3=0,$Padding2,$PaddingLength
		Local $LocalIndxEntryNumberArr[1][2],$LocalIndxEntryNumberArr[1][2],$LocalIndxMFTReferenceArr[1][2],$LocalIndxMFTRefSeqNoArr[1][2],$LocalIndxIndexFlagsArr[1][2],$LocalIndxMFTReferenceOfParentArr[1][2],$LocalIndxMFTParentRefSeqNoArr[1][2]
		Local $LocalIndxCTimeArr[1][2],$LocalIndxATimeArr[1][2],$LocalIndxMTimeArr[1][2],$LocalIndxRTimeArr[1][2],$LocalIndxAllocSizeArr[1][2],$LocalIndxRealSizeArr[1][2],$LocalIndxFileFlagsArr[1][2],$LocalIndxFileNameArr[1][2],$LocalIndxNameSpaceArr[1][2],$LocalIndxSubNodeVCNArr[1][2]
		Local $EntryCounter=1,$LocalAttributeOffset=1

		If Not $hFile Then $hFile = _WinAPI_CreateFile("\\.\" & $TargetDrive,2,6,7)
		If Not $hFile then
			ConsoleWrite("Error in CreateFile in function _RawModIndx(): " & _WinAPI_GetLastErrorMessage() & " for: " & "\\.\" & $TargetDrive & @crlf)
			Return 0
		EndIf
		_WinAPI_SetFilePointerEx($hFile, $DiskOffset+($CurrentRecord*4096))
		Local $TmpOffset = DllCall('kernel32.dll', 'int', 'SetFilePointerEx', 'ptr', $hFile, 'int64', 0, 'int64*', 0, 'dword', 1)
;		ConsoleWrite("Current offset before writing: " & $TmpOffset[3] & @CRLF)
		Local $tBuffer1 = DllStructCreate("byte[" & $INDX_Record_Size & "]")
;		$read = _WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer1), $INDX_Record_Size, $nBytes)
;		If $read = 0 then
;			ConsoleWrite("Error in ReadFile in function _RawModIndx(): Code: " & _WinAPI_GetLastError() & " Message: " & _WinAPI_GetLastErrorMessage() & " for: " & "\\.\" & $TargetDrive & @crlf)
;			_WinAPI_CloseHandle($hFile)
;			Return 0
;		EndIf
		Do
			$read = _WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer1), $INDX_Record_Size, $nBytes)
			If $read = 0 And _WinAPI_GetLastError() = 21 Then
				ConsoleWrite("The device seems busy. Sleeping 500 MS before next attempt" & @CRLF)
			EndIf
			Sleep(500)
		Until _WinAPI_GetLastError() <> 21

		Local $Entry = DllStructGetData($tBuffer1,1)
		If StringMid($Entry,3,8) <> '494e4458' Then
;			ConsoleWrite("Found no INDX signature" & @crlf)
			ContinueLoop
		EndIf
		If StringLeft($Entry,2) = "0x" Then $Entry = StringTrimLeft($Entry,2)
;		_WinAPI_CloseHandle($hFile)
	;	ConsoleWrite("Starting function _StripIndxRecord()" & @crlf)
	;	ConsoleWrite("Unfixed INDX record:" & @crlf)
	;	ConsoleWrite(_HexEncode("0x"&$Entry) & @crlf)
	;	ConsoleWrite(_HexEncode("0x" & StringMid($Entry,1,4096)) & @crlf)
		$IndxHdrUpdateSeqArrOffset = Dec(_SwapEndian(StringMid($Entry,$LocalAttributeOffset+8,4)))
	;	ConsoleWrite("$IndxHdrUpdateSeqArrOffset = " & $IndxHdrUpdateSeqArrOffset & @crlf)
		$IndxHdrUpdateSeqArrSize = Dec(_SwapEndian(StringMid($Entry,$LocalAttributeOffset+12,4)))
	;	ConsoleWrite("$IndxHdrUpdateSeqArrSize = " & $IndxHdrUpdateSeqArrSize & @crlf)
		$IndxHdrUpdSeqArr = StringMid($Entry,1+($IndxHdrUpdateSeqArrOffset*2),$IndxHdrUpdateSeqArrSize*2*2)
	;	ConsoleWrite("$IndxHdrUpdSeqArr = " & $IndxHdrUpdSeqArr & @crlf)
		$IndxHdrUpdSeqArrPart0 = StringMid($IndxHdrUpdSeqArr,1,4)
		$IndxHdrUpdSeqArrPart1 = StringMid($IndxHdrUpdSeqArr,5,4)
		$IndxHdrUpdSeqArrPart2 = StringMid($IndxHdrUpdSeqArr,9,4)
		$IndxHdrUpdSeqArrPart3 = StringMid($IndxHdrUpdSeqArr,13,4)
		$IndxHdrUpdSeqArrPart4 = StringMid($IndxHdrUpdSeqArr,17,4)
		$IndxHdrUpdSeqArrPart5 = StringMid($IndxHdrUpdSeqArr,21,4)
		$IndxHdrUpdSeqArrPart6 = StringMid($IndxHdrUpdSeqArr,25,4)
		$IndxHdrUpdSeqArrPart7 = StringMid($IndxHdrUpdSeqArr,29,4)
		$IndxHdrUpdSeqArrPart8 = StringMid($IndxHdrUpdSeqArr,33,4)
		$IndxRecordEnd1 = StringMid($Entry,1021,4)
		$IndxRecordEnd2 = StringMid($Entry,2045,4)
		$IndxRecordEnd3 = StringMid($Entry,3069,4)
		$IndxRecordEnd4 = StringMid($Entry,4093,4)
		$IndxRecordEnd5 = StringMid($Entry,5117,4)
		$IndxRecordEnd6 = StringMid($Entry,6141,4)
		$IndxRecordEnd7 = StringMid($Entry,7165,4)
		$IndxRecordEnd8 = StringMid($Entry,8189,4)
		If $IndxHdrUpdSeqArrPart0 <> $IndxRecordEnd1 OR $IndxHdrUpdSeqArrPart0 <> $IndxRecordEnd2 OR $IndxHdrUpdSeqArrPart0 <> $IndxRecordEnd3 OR $IndxHdrUpdSeqArrPart0 <> $IndxRecordEnd4 OR $IndxHdrUpdSeqArrPart0 <> $IndxRecordEnd5 OR $IndxHdrUpdSeqArrPart0 <> $IndxRecordEnd6 OR $IndxHdrUpdSeqArrPart0 <> $IndxRecordEnd7 OR $IndxHdrUpdSeqArrPart0 <> $IndxRecordEnd8 Then
			ConsoleWrite("Error the INDX record is corrupt" & @CRLF)
			_WinAPI_CloseHandle($hFile)
			Return 0; Not really correct because I think in theory chunks of 1024 bytes can be invalid and not just everything or nothing for the given INDX record.
;			If $EntryCounter<2 Then $CorrectIndx=0
;			ExitLoop
		Else
			$Entry = StringMid($Entry,1,1020) & $IndxHdrUpdSeqArrPart1 & StringMid($Entry,1025,1020) & $IndxHdrUpdSeqArrPart2 & StringMid($Entry,2049,1020) & $IndxHdrUpdSeqArrPart3 & StringMid($Entry,3073,1020) & $IndxHdrUpdSeqArrPart4 & StringMid($Entry,4097,1020) & $IndxHdrUpdSeqArrPart5 & StringMid($Entry,5121,1020) & $IndxHdrUpdSeqArrPart6 & StringMid($Entry,6145,1020) & $IndxHdrUpdSeqArrPart7 & StringMid($Entry,7169,1020) & $IndxHdrUpdSeqArrPart8
		EndIf
	;	ConsoleWrite("Fixed INDX record:" & @crlf)
	;	ConsoleWrite(_HexEncode("0x"&$Entry) & @crlf)
		$IndxRecordSize = Dec(_SwapEndian(StringMid($Entry,$LocalAttributeOffset+56,8)),2)
	;	ConsoleWrite("$IndxRecordSize = " & StringMid($Entry,$LocalAttributeOffset+56,8) & @crlf)
		$IndxHeaderSize = Dec(_SwapEndian(StringMid($Entry,$LocalAttributeOffset+48,8)),2)
	;	ConsoleWrite("$IndxHeaderSize = " & StringMid($Entry,$LocalAttributeOffset+48,8) & @crlf)
		$IsNotLeafNode = StringMid($Entry,$LocalAttributeOffset+72,2) ;1 if not leaf node
		$LocalAttributeOffset = $LocalAttributeOffset+48+($IndxHeaderSize*2)
		$SizeofIndxRecord = $LocalAttributeOffset+48+($IndxHeaderSize*2) + ($IndxRecordSize-$IndxHeaderSize-16)*2
	;	$SizeofIndxRecord = ($IndxRecordSize-$IndxHeaderSize-16)*2
	;	ConsoleWrite("$SizeofIndxRecord = " & $SizeofIndxRecord & @crlf)

		$NewLocalAttributeOffset = $LocalAttributeOffset
		$MFTReference = StringMid($Entry,$NewLocalAttributeOffset,12)
	;	ConsoleWrite("$MFTReference = " & StringMid($Entry,$NewLocalAttributeOffset,12) & @crlf)
		$MFTReference = StringMid($MFTReference,7,2)&StringMid($MFTReference,5,2)&StringMid($MFTReference,3,2)&StringMid($MFTReference,1,2)
		$MFTReference = Dec($MFTReference)
		$MFTReferenceSeqNo = StringMid($Entry,$NewLocalAttributeOffset+12,4)
		$MFTReferenceSeqNo = Dec(StringMid($MFTReferenceSeqNo,3,2)&StringMid($MFTReferenceSeqNo,1,2))
		$IndexEntryLength = StringMid($Entry,$NewLocalAttributeOffset+16,4)
		$IndexEntryLength = Dec(StringMid($IndexEntryLength,3,2)&StringMid($IndexEntryLength,3,2))
		$OffsetToFileName = StringMid($Entry,$NewLocalAttributeOffset+20,4)
		$OffsetToFileName = Dec(StringMid($OffsetToFileName,3,2)&StringMid($OffsetToFileName,3,2))
		$IndexFlags = StringMid($Entry,$NewLocalAttributeOffset+24,4)
	;	$Padding = StringMid($Entry,$NewLocalAttributeOffset+28,4)
		$MFTReferenceOfParent = StringMid($Entry,$NewLocalAttributeOffset+32,12)
		$MFTReferenceOfParent = StringMid($MFTReferenceOfParent,7,2)&StringMid($MFTReferenceOfParent,5,2)&StringMid($MFTReferenceOfParent,3,2)&StringMid($MFTReferenceOfParent,1,2)
		$MFTReferenceOfParent = Dec($MFTReferenceOfParent)
		#cs
		If $MFTReferenceOfParent <> $CurrentRef Then ;Wrong INDX
			ConsoleWrite("Error: Wrong INDX" & @crlf)
;			If $EntryCounter<2 Then $CorrectIndx=0
;			ExitLoop
			Return 0
		EndIf
		#ce
		$MFTReferenceOfParentSeqNo = StringMid($Entry,$NewLocalAttributeOffset+44,4)
		$MFTReferenceOfParentSeqNo = Dec(StringMid($MFTReferenceOfParentSeqNo,3,2) & StringMid($MFTReferenceOfParentSeqNo,3,2))
		$Indx_CTime = StringMid($Entry,$NewLocalAttributeOffset+48,16)
		$Indx_CTime = StringMid($Indx_CTime,15,2) & StringMid($Indx_CTime,13,2) & StringMid($Indx_CTime,11,2) & StringMid($Indx_CTime,9,2) & StringMid($Indx_CTime,7,2) & StringMid($Indx_CTime,5,2) & StringMid($Indx_CTime,3,2) & StringMid($Indx_CTime,1,2)
		$Indx_CTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_CTime)
		$Indx_CTime = _WinTime_UTCFileTimeFormat(Dec($Indx_CTime)-$tDelta,$DateTimeFormat,2)
		If @error Then
			$Indx_CTime = "-"
		Else
			$Indx_CTime = $Indx_CTime & ":" & _FillZero(StringRight($Indx_CTime_tmp,4))
		EndIf
		$Indx_ATime = StringMid($Entry,$NewLocalAttributeOffset+64,16)
		$Indx_ATime = StringMid($Indx_ATime,15,2) & StringMid($Indx_ATime,13,2) & StringMid($Indx_ATime,11,2) & StringMid($Indx_ATime,9,2) & StringMid($Indx_ATime,7,2) & StringMid($Indx_ATime,5,2) & StringMid($Indx_ATime,3,2) & StringMid($Indx_ATime,1,2)
		$Indx_ATime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_ATime)
		$Indx_ATime = _WinTime_UTCFileTimeFormat(Dec($Indx_ATime)-$tDelta,$DateTimeFormat,2)
		If @error Then
			$Indx_ATime = "-"
		Else
			$Indx_ATime = $Indx_ATime & ":" & _FillZero(StringRight($Indx_ATime_tmp,4))
		EndIf
		$Indx_MTime = StringMid($Entry,$NewLocalAttributeOffset+80,16)
		$Indx_MTime = StringMid($Indx_MTime,15,2) & StringMid($Indx_MTime,13,2) & StringMid($Indx_MTime,11,2) & StringMid($Indx_MTime,9,2) & StringMid($Indx_MTime,7,2) & StringMid($Indx_MTime,5,2) & StringMid($Indx_MTime,3,2) & StringMid($Indx_MTime,1,2)
		$Indx_MTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_MTime)
		$Indx_MTime = _WinTime_UTCFileTimeFormat(Dec($Indx_MTime)-$tDelta,$DateTimeFormat,2)
		If @error Then
			$Indx_MTime = "-"
		Else
			$Indx_MTime = $Indx_MTime & ":" & _FillZero(StringRight($Indx_MTime_tmp,4))
		EndIf
		$Indx_RTime = StringMid($Entry,$NewLocalAttributeOffset+96,16)
		$Indx_RTime = StringMid($Indx_RTime,15,2) & StringMid($Indx_RTime,13,2) & StringMid($Indx_RTime,11,2) & StringMid($Indx_RTime,9,2) & StringMid($Indx_RTime,7,2) & StringMid($Indx_RTime,5,2) & StringMid($Indx_RTime,3,2) & StringMid($Indx_RTime,1,2)
		$Indx_RTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_RTime)
		$Indx_RTime = _WinTime_UTCFileTimeFormat(Dec($Indx_RTime)-$tDelta,$DateTimeFormat,2)
		If @error Then
			$Indx_RTime = "-"
		Else
			$Indx_RTime = $Indx_RTime & ":" & _FillZero(StringRight($Indx_RTime_tmp,4))
		EndIf

		$Indx_AllocSize = StringMid($Entry,$NewLocalAttributeOffset+112,16)
		$Indx_AllocSize = Dec(StringMid($Indx_AllocSize,15,2) & StringMid($Indx_AllocSize,13,2) & StringMid($Indx_AllocSize,11,2) & StringMid($Indx_AllocSize,9,2) & StringMid($Indx_AllocSize,7,2) & StringMid($Indx_AllocSize,5,2) & StringMid($Indx_AllocSize,3,2) & StringMid($Indx_AllocSize,1,2))
		$Indx_RealSize = StringMid($Entry,$NewLocalAttributeOffset+128,16)
		$Indx_RealSize = Dec(StringMid($Indx_RealSize,15,2) & StringMid($Indx_RealSize,13,2) & StringMid($Indx_RealSize,11,2) & StringMid($Indx_RealSize,9,2) & StringMid($Indx_RealSize,7,2) & StringMid($Indx_RealSize,5,2) & StringMid($Indx_RealSize,3,2) & StringMid($Indx_RealSize,1,2))
		$Indx_File_Flags = StringMid($Entry,$NewLocalAttributeOffset+144,16)
		$Indx_File_Flags = StringMid($Indx_File_Flags,15,2) & StringMid($Indx_File_Flags,13,2) & StringMid($Indx_File_Flags,11,2) & StringMid($Indx_File_Flags,9,2)&StringMid($Indx_File_Flags,7,2) & StringMid($Indx_File_Flags,5,2) & StringMid($Indx_File_Flags,3,2) & StringMid($Indx_File_Flags,1,2)
		$Indx_File_Flags = StringMid($Indx_File_Flags,13,8)
		$Indx_File_Flags = _File_Attributes("0x" & $Indx_File_Flags)
		$Indx_NameLength = StringMid($Entry,$NewLocalAttributeOffset+160,2)
		$Indx_NameLength = Dec($Indx_NameLength)
		$Indx_NameSpace = StringMid($Entry,$NewLocalAttributeOffset+162,2)
		Select
			Case $Indx_NameSpace = "00"	;POSIX
				$Indx_NameSpace = "POSIX"
			Case $Indx_NameSpace = "01"	;WIN32
				$Indx_NameSpace = "WIN32"
			Case $Indx_NameSpace = "02"	;DOS
				$Indx_NameSpace = "DOS"
			Case $Indx_NameSpace = "03"	;DOS+WIN32
				$Indx_NameSpace = "DOS+WIN32"
		EndSelect
		$Indx_FileName = StringMid($Entry,$NewLocalAttributeOffset+164,$Indx_NameLength*2*2)
		$Indx_FileName = _UnicodeHexToStr($Indx_FileName)
		$tmp1 = 164+($Indx_NameLength*2*2)
		Do ; Calculate the length of the padding - 8 byte aligned
			$tmp2 = $tmp1/16
			If Not IsInt($tmp2) Then
				$tmp0 = 2
				$tmp1 += $tmp0
				$tmp3 += $tmp0
			EndIf
		Until IsInt($tmp2)
		$PaddingLength = $tmp3
	;	$Padding2 = StringMid($Entry,$NewLocalAttributeOffset+164+($Indx_NameLength*2*2),$PaddingLength)
		If $IndexFlags <> "0000" Then
			$SubNodeVCN = StringMid($Entry,$NewLocalAttributeOffset+164+($Indx_NameLength*2*2)+$PaddingLength,16)
			$SubNodeVCNLength = 16
		Else
			$SubNodeVCN = ""
			$SubNodeVCNLength = 0
		EndIf
	;--------- Resize Arrays
		ReDim $LocalIndxEntryNumberArr[1+$EntryCounter][2]
		ReDim $LocalIndxMFTReferenceArr[1+$EntryCounter][2]
		ReDim $LocalIndxMFTRefSeqNoArr[1+$EntryCounter][2]
		ReDim $LocalIndxIndexFlagsArr[1+$EntryCounter][2]
		ReDim $LocalIndxMFTReferenceOfParentArr[1+$EntryCounter][2]
		ReDim $LocalIndxMFTParentRefSeqNoArr[1+$EntryCounter][2]
		ReDim $LocalIndxCTimeArr[1+$EntryCounter][2]
		ReDim $LocalIndxATimeArr[1+$EntryCounter][2]
		ReDim $LocalIndxMTimeArr[1+$EntryCounter][2]
		ReDim $LocalIndxRTimeArr[1+$EntryCounter][2]
		ReDim $LocalIndxAllocSizeArr[1+$EntryCounter][2]
		ReDim $LocalIndxRealSizeArr[1+$EntryCounter][2]
		ReDim $LocalIndxFileFlagsArr[1+$EntryCounter][2]
		ReDim $LocalIndxFileNameArr[1+$EntryCounter][2]
		ReDim $LocalIndxNameSpaceArr[1+$EntryCounter][2]
		ReDim $LocalIndxSubNodeVCNArr[1+$EntryCounter][2]
	;-----------Data
		$LocalIndxEntryNumberArr[$EntryCounter][1] = $EntryCounter
		$LocalIndxMFTReferenceArr[$EntryCounter][1] = $MFTReference
		$LocalIndxMFTRefSeqNoArr[$EntryCounter][1] = $MFTReferenceSeqNo
		$LocalIndxIndexFlagsArr[$EntryCounter][1] = $IndexFlags
		$LocalIndxMFTReferenceOfParentArr[$EntryCounter][1] = $MFTReferenceOfParent
		$LocalIndxMFTParentRefSeqNoArr[$EntryCounter][1] = $MFTReferenceOfParentSeqNo
		$LocalIndxCTimeArr[$EntryCounter][1] = $Indx_CTime
		$LocalIndxATimeArr[$EntryCounter][1] = $Indx_ATime
		$LocalIndxMTimeArr[$EntryCounter][1] = $Indx_MTime
		$LocalIndxRTimeArr[$EntryCounter][1] = $Indx_RTime
		$LocalIndxAllocSizeArr[$EntryCounter][1] = $Indx_AllocSize
		$LocalIndxRealSizeArr[$EntryCounter][1] = $Indx_RealSize
		$LocalIndxFileFlagsArr[$EntryCounter][1] = $Indx_File_Flags
		$LocalIndxFileNameArr[$EntryCounter][1] = $Indx_FileName
		$LocalIndxNameSpaceArr[$EntryCounter][1] = $Indx_NameSpace
		$LocalIndxSubNodeVCNArr[$EntryCounter][1] = $SubNodeVCN
	;----------Offsets
	;	$LocalIndxEntryNumberArr[$EntryCounter][0] = $EntryCounter
		$LocalIndxMFTReferenceArr[$EntryCounter][0] = $NewLocalAttributeOffset
		$LocalIndxMFTRefSeqNoArr[$EntryCounter][0] = $NewLocalAttributeOffset+12
		$LocalIndxIndexFlagsArr[$EntryCounter][0] = $NewLocalAttributeOffset+24
		$LocalIndxMFTReferenceOfParentArr[$EntryCounter][0] = $NewLocalAttributeOffset+32
		$LocalIndxMFTParentRefSeqNoArr[$EntryCounter][0] = $NewLocalAttributeOffset+44
		$LocalIndxCTimeArr[$EntryCounter][0] = $NewLocalAttributeOffset+48
		$LocalIndxATimeArr[$EntryCounter][0] = $NewLocalAttributeOffset+64
		$LocalIndxMTimeArr[$EntryCounter][0] = $NewLocalAttributeOffset+80
		$LocalIndxRTimeArr[$EntryCounter][0] = $NewLocalAttributeOffset+96
		$LocalIndxAllocSizeArr[$EntryCounter][0] = $NewLocalAttributeOffset+112
		$LocalIndxRealSizeArr[$EntryCounter][0] = $NewLocalAttributeOffset+128
		$LocalIndxFileFlagsArr[$EntryCounter][0] = $NewLocalAttributeOffset+144
		$LocalIndxFileNameArr[$EntryCounter][0] = $NewLocalAttributeOffset+164
		$LocalIndxNameSpaceArr[$EntryCounter][0] = $NewLocalAttributeOffset+162
	;	$LocalIndxSubNodeVCNArr[$EntryCounter][0] = $SubNodeVCN
	; Work through the rest of the index entries
		$NextEntryOffset = $NewLocalAttributeOffset+164+($Indx_NameLength*2*2)+$PaddingLength+$SubNodeVCNLength
		If Not (Int($NextEntryOffset+64) >= Int($SizeofIndxRecord)) Then
			Do
				$EntryCounter += 1
		;		ConsoleWrite("$EntryCounter = " & $EntryCounter & @crlf)
				$MFTReference = StringMid($Entry,$NextEntryOffset,12)
		;		ConsoleWrite("$MFTReference = " & $MFTReference & @crlf)
				$MFTReference = StringMid($MFTReference,7,2)&StringMid($MFTReference,5,2)&StringMid($MFTReference,3,2)&StringMid($MFTReference,1,2)
		;		$MFTReference = StringMid($MFTReference,15,2)&StringMid($MFTReference,13,2)&StringMid($MFTReference,11,2)&StringMid($MFTReference,9,2)&StringMid($MFTReference,7,2)&StringMid($MFTReference,5,2)&StringMid($MFTReference,3,2)&StringMid($MFTReference,1,2)
		;		ConsoleWrite("$MFTReference = " & $MFTReference & @crlf)
				$MFTReference = Dec($MFTReference)
				$MFTReferenceSeqNo = StringMid($Entry,$NextEntryOffset+12,4)
				$MFTReferenceSeqNo = Dec(StringMid($MFTReferenceSeqNo,3,2)&StringMid($MFTReferenceSeqNo,1,2))
				$IndexEntryLength = StringMid($Entry,$NextEntryOffset+16,4)
		;		ConsoleWrite("$IndexEntryLength = " & $IndexEntryLength & @crlf)
				$IndexEntryLength = Dec(StringMid($IndexEntryLength,3,2)&StringMid($IndexEntryLength,3,2))
		;		ConsoleWrite("$IndexEntryLength = " & $IndexEntryLength & @crlf)
				$OffsetToFileName = StringMid($Entry,$NextEntryOffset+20,4)
		;		ConsoleWrite("$OffsetToFileName = " & $OffsetToFileName & @crlf)
				$OffsetToFileName = Dec(StringMid($OffsetToFileName,3,2)&StringMid($OffsetToFileName,3,2))
		;		ConsoleWrite("$OffsetToFileName = " & $OffsetToFileName & @crlf)
				$IndexFlags = StringMid($Entry,$NextEntryOffset+24,4)
		;		ConsoleWrite("$IndexFlags = " & $IndexFlags & @crlf)
				$Padding = StringMid($Entry,$NextEntryOffset+28,4)
		;		ConsoleWrite("$Padding = " & $Padding & @crlf)
				$MFTReferenceOfParent = StringMid($Entry,$NextEntryOffset+32,12)
		;		ConsoleWrite("$MFTReferenceOfParent = " & $MFTReferenceOfParent & @crlf)
				$MFTReferenceOfParent = StringMid($MFTReferenceOfParent,7,2)&StringMid($MFTReferenceOfParent,5,2)&StringMid($MFTReferenceOfParent,3,2)&StringMid($MFTReferenceOfParent,1,2)
		;		$MFTReferenceOfParent = StringMid($MFTReferenceOfParent,15,2)&StringMid($MFTReferenceOfParent,13,2)&StringMid($MFTReferenceOfParent,11,2)&StringMid($MFTReferenceOfParent,9,2)&StringMid($MFTReferenceOfParent,7,2)&StringMid($MFTReferenceOfParent,5,2)&StringMid($MFTReferenceOfParent,3,2)&StringMid($MFTReferenceOfParent,1,2)
		;		ConsoleWrite("$MFTReferenceOfParent = " & $MFTReferenceOfParent & @crlf)
				$MFTReferenceOfParent = Dec($MFTReferenceOfParent)
				#cs
				If $MFTReferenceOfParent <> $CurrentRef Then ;Wrong INDX
					ConsoleWrite("Error: Wrong INDX" & @crlf)
;					If $EntryCounter<2 Then $CorrectIndx=0 ;This should never occur anyway, so check can be removed
					ExitLoop
;					Return 0
				EndIf
				#ce
				$MFTReferenceOfParentSeqNo = StringMid($Entry,$NextEntryOffset+44,4)
				$MFTReferenceOfParentSeqNo = Dec(StringMid($MFTReferenceOfParentSeqNo,3,2) & StringMid($MFTReferenceOfParentSeqNo,3,2))

				$Indx_CTime = StringMid($Entry,$NextEntryOffset+48,16)
				$Indx_CTime = StringMid($Indx_CTime,15,2) & StringMid($Indx_CTime,13,2) & StringMid($Indx_CTime,11,2) & StringMid($Indx_CTime,9,2) & StringMid($Indx_CTime,7,2) & StringMid($Indx_CTime,5,2) & StringMid($Indx_CTime,3,2) & StringMid($Indx_CTime,1,2)
				$Indx_CTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_CTime)
				$Indx_CTime = _WinTime_UTCFileTimeFormat(Dec($Indx_CTime)-$tDelta,$DateTimeFormat,2)
				$Indx_CTime = $Indx_CTime & ":" & _FillZero(StringRight($Indx_CTime_tmp,4))
		;		ConsoleWrite("$Indx_CTime = " & $Indx_CTime & @crlf)
		;
				$Indx_ATime = StringMid($Entry,$NextEntryOffset+64,16)
				$Indx_ATime = StringMid($Indx_ATime,15,2) & StringMid($Indx_ATime,13,2) & StringMid($Indx_ATime,11,2) & StringMid($Indx_ATime,9,2) & StringMid($Indx_ATime,7,2) & StringMid($Indx_ATime,5,2) & StringMid($Indx_ATime,3,2) & StringMid($Indx_ATime,1,2)
				$Indx_ATime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_ATime)
				$Indx_ATime = _WinTime_UTCFileTimeFormat(Dec($Indx_ATime)-$tDelta,$DateTimeFormat,2)
				$Indx_ATime = $Indx_ATime & ":" & _FillZero(StringRight($Indx_ATime_tmp,4))
		;		ConsoleWrite("$Indx_ATime = " & $Indx_ATime & @crlf)
		;
				$Indx_MTime = StringMid($Entry,$NextEntryOffset+80,16)
				$Indx_MTime = StringMid($Indx_MTime,15,2) & StringMid($Indx_MTime,13,2) & StringMid($Indx_MTime,11,2) & StringMid($Indx_MTime,9,2) & StringMid($Indx_MTime,7,2) & StringMid($Indx_MTime,5,2) & StringMid($Indx_MTime,3,2) & StringMid($Indx_MTime,1,2)
				$Indx_MTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_MTime)
				$Indx_MTime = _WinTime_UTCFileTimeFormat(Dec($Indx_MTime)-$tDelta,$DateTimeFormat,2)
				$Indx_MTime = $Indx_MTime & ":" & _FillZero(StringRight($Indx_MTime_tmp,4))
		;		ConsoleWrite("$Indx_MTime = " & $Indx_MTime & @crlf)
		;
				$Indx_RTime = StringMid($Entry,$NextEntryOffset+96,16)
				$Indx_RTime = StringMid($Indx_RTime,15,2) & StringMid($Indx_RTime,13,2) & StringMid($Indx_RTime,11,2) & StringMid($Indx_RTime,9,2) & StringMid($Indx_RTime,7,2) & StringMid($Indx_RTime,5,2) & StringMid($Indx_RTime,3,2) & StringMid($Indx_RTime,1,2)
				$Indx_RTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_RTime)
				$Indx_RTime = _WinTime_UTCFileTimeFormat(Dec($Indx_RTime)-$tDelta,$DateTimeFormat,2)
				$Indx_RTime = $Indx_RTime & ":" & _FillZero(StringRight($Indx_RTime_tmp,4))
		;		ConsoleWrite("$Indx_RTime = " & $Indx_RTime & @crlf)
		;
				$Indx_AllocSize = StringMid($Entry,$NextEntryOffset+112,16)
				$Indx_AllocSize = Dec(StringMid($Indx_AllocSize,15,2) & StringMid($Indx_AllocSize,13,2) & StringMid($Indx_AllocSize,11,2) & StringMid($Indx_AllocSize,9,2) & StringMid($Indx_AllocSize,7,2) & StringMid($Indx_AllocSize,5,2) & StringMid($Indx_AllocSize,3,2) & StringMid($Indx_AllocSize,1,2))
		;		ConsoleWrite("$Indx_AllocSize = " & $Indx_AllocSize & @crlf)
				$Indx_RealSize = StringMid($Entry,$NextEntryOffset+128,16)
				$Indx_RealSize = Dec(StringMid($Indx_RealSize,15,2) & StringMid($Indx_RealSize,13,2) & StringMid($Indx_RealSize,11,2) & StringMid($Indx_RealSize,9,2) & StringMid($Indx_RealSize,7,2) & StringMid($Indx_RealSize,5,2) & StringMid($Indx_RealSize,3,2) & StringMid($Indx_RealSize,1,2))
		;		ConsoleWrite("$Indx_RealSize = " & $Indx_RealSize & @crlf)
				$Indx_File_Flags = StringMid($Entry,$NextEntryOffset+144,16)
		;		ConsoleWrite("$Indx_File_Flags = " & $Indx_File_Flags & @crlf)
				$Indx_File_Flags = StringMid($Indx_File_Flags,15,2) & StringMid($Indx_File_Flags,13,2) & StringMid($Indx_File_Flags,11,2) & StringMid($Indx_File_Flags,9,2)&StringMid($Indx_File_Flags,7,2) & StringMid($Indx_File_Flags,5,2) & StringMid($Indx_File_Flags,3,2) & StringMid($Indx_File_Flags,1,2)
		;		ConsoleWrite("$Indx_File_Flags = " & $Indx_File_Flags & @crlf)
				$Indx_File_Flags = StringMid($Indx_File_Flags,13,8)
				$Indx_File_Flags = _File_Attributes("0x" & $Indx_File_Flags)
		;		ConsoleWrite("$Indx_File_Flags = " & $Indx_File_Flags & @crlf)
				$Indx_NameLength = StringMid($Entry,$NextEntryOffset+160,2)
				$Indx_NameLength = Dec($Indx_NameLength)
		;		ConsoleWrite("$Indx_NameLength = " & $Indx_NameLength & @crlf)
				$Indx_NameSpace = StringMid($Entry,$NextEntryOffset+162,2)
		;		ConsoleWrite("$Indx_NameSpace = " & $Indx_NameSpace & @crlf)
				Select
					Case $Indx_NameSpace = "00"	;POSIX
						$Indx_NameSpace = "POSIX"
					Case $Indx_NameSpace = "01"	;WIN32
						$Indx_NameSpace = "WIN32"
					Case $Indx_NameSpace = "02"	;DOS
						$Indx_NameSpace = "DOS"
					Case $Indx_NameSpace = "03"	;DOS+WIN32
						$Indx_NameSpace = "DOS+WIN32"
				EndSelect
				$Indx_FileName = StringMid($Entry,$NextEntryOffset+164,$Indx_NameLength*2*2)
		;		ConsoleWrite("$Indx_FileName = " & $Indx_FileName & @crlf)
				$Indx_FileName = _UnicodeHexToStr($Indx_FileName)
				;ConsoleWrite("$Indx_FileName = " & $Indx_FileName & @crlf)
				$tmp0 = 0
				$tmp2 = 0
				$tmp3 = 0
				$tmp1 = 164+($Indx_NameLength*2*2)
				Do ; Calculate the length of the padding - 8 byte aligned
					$tmp2 = $tmp1/16
					If Not IsInt($tmp2) Then
						$tmp0 = 2
						$tmp1 += $tmp0
						$tmp3 += $tmp0
					EndIf
				Until IsInt($tmp2)
				$PaddingLength = $tmp3
		;		ConsoleWrite("$PaddingLength = " & $PaddingLength & @crlf)
				$Padding = StringMid($Entry,$NextEntryOffset+164+($Indx_NameLength*2*2),$PaddingLength)
		;		ConsoleWrite("$Padding = " & $Padding & @crlf)
				If $IndexFlags <> "0000" Then
					$SubNodeVCN = StringMid($Entry,$NextEntryOffset+164+($Indx_NameLength*2*2)+$PaddingLength,16)
					$SubNodeVCNLength = 16
				Else
					$SubNodeVCN = ""
					$SubNodeVCNLength = 0
				EndIf
		;		ConsoleWrite("$SubNodeVCN = " & $SubNodeVCN & @crlf)
	;			$NextEntryOffset = $NextEntryOffset+164+($Indx_NameLength*2*2)+$PaddingLength+$SubNodeVCNLength
	;			ConsoleWrite("$NextEntryOffset = " & $NextEntryOffset & @crlf)
	;			ConsoleWrite("$NextEntryOffset+32 = " & $NextEntryOffset+32 & @crlf)
				ReDim $LocalIndxEntryNumberArr[1+$EntryCounter][2]
				ReDim $LocalIndxMFTReferenceArr[1+$EntryCounter][2]
				Redim $LocalIndxMFTRefSeqNoArr[1+$EntryCounter][2]
				ReDim $LocalIndxIndexFlagsArr[1+$EntryCounter][2]
				ReDim $LocalIndxMFTReferenceOfParentArr[1+$EntryCounter][2]
				ReDim $LocalIndxMFTParentRefSeqNoArr[1+$EntryCounter][2]
				ReDim $LocalIndxCTimeArr[1+$EntryCounter][2]
				ReDim $LocalIndxATimeArr[1+$EntryCounter][2]
				ReDim $LocalIndxMTimeArr[1+$EntryCounter][2]
				ReDim $LocalIndxRTimeArr[1+$EntryCounter][2]
				ReDim $LocalIndxAllocSizeArr[1+$EntryCounter][2]
				ReDim $LocalIndxRealSizeArr[1+$EntryCounter][2]
				ReDim $LocalIndxFileFlagsArr[1+$EntryCounter][2]
				ReDim $LocalIndxFileNameArr[1+$EntryCounter][2]
				ReDim $LocalIndxNameSpaceArr[1+$EntryCounter][2]
				ReDim $LocalIndxSubNodeVCNArr[1+$EntryCounter][2]
		;----------Data
				$LocalIndxEntryNumberArr[$EntryCounter][1] = $EntryCounter
				$LocalIndxMFTReferenceArr[$EntryCounter][1] = $MFTReference
				$LocalIndxMFTRefSeqNoArr[$EntryCounter][1] = $MFTReferenceSeqNo
				$LocalIndxIndexFlagsArr[$EntryCounter][1] = $IndexFlags
				$LocalIndxMFTReferenceOfParentArr[$EntryCounter][1] = $MFTReferenceOfParent
				$LocalIndxMFTParentRefSeqNoArr[$EntryCounter][1] = $MFTReferenceOfParentSeqNo
				$LocalIndxCTimeArr[$EntryCounter][1] = $Indx_CTime
				$LocalIndxATimeArr[$EntryCounter][1] = $Indx_ATime
				$LocalIndxMTimeArr[$EntryCounter][1] = $Indx_MTime
				$LocalIndxRTimeArr[$EntryCounter][1] = $Indx_RTime
				$LocalIndxAllocSizeArr[$EntryCounter][1] = $Indx_AllocSize
				$LocalIndxRealSizeArr[$EntryCounter][1] = $Indx_RealSize
				$LocalIndxFileFlagsArr[$EntryCounter][1] = $Indx_File_Flags
				$LocalIndxFileNameArr[$EntryCounter][1] = $Indx_FileName
				$LocalIndxNameSpaceArr[$EntryCounter][1] = $Indx_NameSpace
				$LocalIndxSubNodeVCNArr[$EntryCounter][1] = $SubNodeVCN
		;-----------Offsets
				$LocalIndxMFTReferenceArr[$EntryCounter][0] = $NextEntryOffset
				$LocalIndxMFTRefSeqNoArr[$EntryCounter][0] = $NextEntryOffset+12
				$LocalIndxIndexFlagsArr[$EntryCounter][0] = $NextEntryOffset+24
				$LocalIndxMFTReferenceOfParentArr[$EntryCounter][0] = $NextEntryOffset+32
				$LocalIndxMFTParentRefSeqNoArr[$EntryCounter][0] = $NextEntryOffset+44
				$LocalIndxCTimeArr[$EntryCounter][0] = $NextEntryOffset+48
				$LocalIndxATimeArr[$EntryCounter][0] = $NextEntryOffset+64
				$LocalIndxMTimeArr[$EntryCounter][0] = $NextEntryOffset+80
				$LocalIndxRTimeArr[$EntryCounter][0] = $NextEntryOffset+96
				$LocalIndxAllocSizeArr[$EntryCounter][0] = $NextEntryOffset+112
				$LocalIndxRealSizeArr[$EntryCounter][0] = $NextEntryOffset+128
				$LocalIndxFileFlagsArr[$EntryCounter][0] = $NextEntryOffset+144
				$LocalIndxFileNameArr[$EntryCounter][0] = $NextEntryOffset+164
				$LocalIndxNameSpaceArr[$EntryCounter][0] = $NextEntryOffset+162
				$NextEntryOffset = $NextEntryOffset+164+($Indx_NameLength*2*2)+$PaddingLength+$SubNodeVCNLength
			Until Int($NextEntryOffset+32) >= Int($SizeofIndxRecord)
		EndIf

;-------------------------Done parsing the INDX record
;	_ArrayDisplay($LocalIndxFileNameArr,"$LocalIndxFileNameArr")

;--------------------------------Patch the record

		Local $Counter=0
		For $i = 1 To Ubound($LocalIndxRTimeArr)-1
			If $TargetRef = $LocalIndxMFTReferenceArr[$i][1] Then
				If (StringLeft($InfoArrShadowMainTarget[1],1) <> StringLeft($LocalIndxFileNameArr[$i][1],1)) Or (StringLen($InfoArrShadowMainTarget[1]) < StringLen($LocalIndxFileNameArr[$i][1])) Then
					MsgBox(0,"Error","Mismatch when evaluating INDX records")
					ContinueLoop
				EndIf
				$Counter+=1
				Select
					Case $DoCTime
	;					$TmpCTimeOffset = Int(($LocalIndxCTimeArr[$i][0]-1)/2)
	;					ConsoleWrite("CTime offset: 0x" & Hex($TmpCTimeOffset,8) & @CRLF)
						$Entry = StringMid($Entry,1,$LocalIndxCTimeArr[$i][0]-1) & $NewTimestampShifted & StringMid($Entry,$LocalIndxCTimeArr[$i][0]+16,($INDX_Record_Size*2)-$LocalIndxCTimeArr[$i][0])
					Case $DoATime
						$Entry = StringMid($Entry,1,$LocalIndxATimeArr[$i][0]-1) & $NewTimestampShifted & StringMid($Entry,$LocalIndxATimeArr[$i][0]+16,($INDX_Record_Size*2)-$LocalIndxATimeArr[$i][0])
					Case $DoMTime
						$Entry = StringMid($Entry,1,$LocalIndxMTimeArr[$i][0]-1) & $NewTimestampShifted & StringMid($Entry,$LocalIndxMTimeArr[$i][0]+16,($INDX_Record_Size*2)-$LocalIndxMTimeArr[$i][0])
					Case $DoRTime
						$Entry = StringMid($Entry,1,$LocalIndxRTimeArr[$i][0]-1) & $NewTimestampShifted & StringMid($Entry,$LocalIndxRTimeArr[$i][0]+16,($INDX_Record_Size*2)-$LocalIndxRTimeArr[$i][0])
					Case $DoAll4Timestamps
						$Entry = StringMid($Entry,1,$LocalIndxCTimeArr[$i][0]-1) & $NewTimestampShifted & $NewTimestampShifted & $NewTimestampShifted & $NewTimestampShifted & StringMid($Entry,$LocalIndxRTimeArr[$i][0]+16,($INDX_Record_Size*2)-$LocalIndxRTimeArr[$i][0])
				EndSelect
			EndIf
		Next

;		_ArrayDisplay($LocalIndxFileNameArr,"$LocalIndxFileNameArr")
;		_ArrayDisplay($LocalIndxMFTReferenceArr,"$LocalIndxMFTReferenceArr")
		If Not $Counter Then
;			ConsoleWrite("Error: could not find ref " & $TargetRef & " in this INDX record" & @crlf)
	;		_ArrayDisplay($LocalIndxMFTReferenceArr,"$LocalIndxMFTReferenceArr")
			ContinueLoop
		EndIf
		$Counter2+=$Counter
	;	_ArrayDisplay($LocalIndxMFTReferenceArr,"$LocalIndxMFTReferenceArr")
	;	ConsoleWrite("Patched timestamps:" & @crlf)
	;	ConsoleWrite(_HexEncode("0x"&$Entry) & @crlf)

		$LocalAttributeOffset = 1
		$IndxHdrUpdateSeqArrOffset = Dec(_SwapEndian(StringMid($Entry,$LocalAttributeOffset+8,4)))
		$OffsetToUsa = 1+($IndxHdrUpdateSeqArrOffset*2) ;offset of usa ()
		$RecordHeaderBeforeUsa = StringMid($Entry,1,$OffsetToUsa-1) ;Record header up until usa
		$UpdateSequenceNumber = StringMid($Entry,$OffsetToUsa,4)

		;The fixup values
		$UsaPart1 = StringMid($Entry,1021,4)
		$UsaPart2 = StringMid($Entry,2045,4)
		$UsaPart3 = StringMid($Entry,3069,4)
		$UsaPart4 = StringMid($Entry,4093,4)
		$UsaPart5 = StringMid($Entry,5117,4)
		$UsaPart6 = StringMid($Entry,6141,4)
		$UsaPart7 = StringMid($Entry,7165,4)
		$UsaPart8 = StringMid($Entry,8189,4)
		;The data between fixups
		$RecordSector1Rest = StringMid($Entry,$OffsetToUsa+36,1021-($OffsetToUsa+36)) ;From end of usa and until end of sector 1
		$RecordSector2 = StringMid($Entry,1025,1020)
		$RecordSector3 = StringMid($Entry,2049,1020)
		$RecordSector4 = StringMid($Entry,3073,1020)
		$RecordSector5 = StringMid($Entry,4097,1020)
		$RecordSector6 = StringMid($Entry,5121,1020)
		$RecordSector7 = StringMid($Entry,6145,1020)
		$RecordSector8 = StringMid($Entry,7169,1020)
		;New usa
		$NewUsa = $UpdateSequenceNumber & $UsaPart1 & $UsaPart2 & $UsaPart3 & $UsaPart4 & $UsaPart5 & $UsaPart6 & $UsaPart7 & $UsaPart8
		;Reassemble the record
		$Entry = $RecordHeaderBeforeUsa & $NewUsa & $RecordSector1Rest & $UpdateSequenceNumber & $RecordSector2 & $UpdateSequenceNumber & $RecordSector3 & $UpdateSequenceNumber & $RecordSector4 & $UpdateSequenceNumber & $RecordSector5 & $UpdateSequenceNumber & $RecordSector6 & $UpdateSequenceNumber & $RecordSector7 & $UpdateSequenceNumber & $RecordSector8 & $UpdateSequenceNumber
	;	ConsoleWrite("Reassembled INDX record:" & @crlf)
	;	ConsoleWrite(_HexEncode("0x"&$Entry) & @crlf)

		;Put modified MFT entry into new buffer
		Local $tBuffer2 = DllStructCreate("byte[" & $INDX_Record_Size & "]")
		DllStructSetData($tBuffer2,1,"0x"&$Entry)

		$Success += _WriteIt($DiskOffset+($CurrentRecord*4096), $tBuffer2)
	Next
	_WinAPI_CloseHandle($hFile)
	If $Counter2=0 Then ConsoleWrite("Info: Ref " & $TargetRef & " was not present in this INDX record" & @crlf)
	If $Counter2>0 And $Success=0 Then ConsoleWrite("Error: Ref " & $TargetRef & " was found in this INDX record, but modification failed" & @crlf)
	Return $Success
EndFunc

Func _RawModMft($DiskOffset,$TargetRef)
	Local $nBytes;,$number
	$IsLocked = 0
	$IsDismounted = 0

	Local $hFile = _WinAPI_CreateFile("\\.\" & $TargetDrive,2,6,7)
	If Not $hFile then
		ConsoleWrite("Error in CreateFile in function _RawModMft(): " & _WinAPI_GetLastErrorMessage() & " for: " & "\\.\" & $TargetDrive & @crlf)
		Return 0
	EndIf

	_WinAPI_SetFilePointerEx($hFile, $DiskOffset)
	Local $TmpOffset = DllCall('kernel32.dll', 'int', 'SetFilePointerEx', 'ptr', $hFile, 'int64', 0, 'int64*', 0, 'dword', 1)
	$TmpOffset = Int($TmpOffset[3])
;
	Local $tBuffer1 = DllStructCreate("byte[" & $MFT_Record_Size & "]")
	$read = _WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer1), $MFT_Record_Size, $nBytes)
	If $read = 0 then
		ConsoleWrite("Error in ReadFile in function _RawModMft(): " & _WinAPI_GetLastErrorMessage() & " for: " & "\\.\" & $TargetDrive & @crlf)
		Return 0
	EndIf
	Local $MFTRecordDump = DllStructGetData($tBuffer1,1)
	_WinAPI_CloseHandle($hFile)
	If _DecodeMFTRecord($TargetDrive,$MFTRecordDump,0) < 1 Then
		ConsoleWrite("Could not verify MFT record at offset: 0x" & Hex($TmpOffset) & @CRLF)
		Return 0
	EndIf
	$UpdSeqArrOffset = StringMid($MFTRecordDump,11,4)
	$UpdSeqArrOffset = Dec(StringMid($UpdSeqArrOffset,3,2) & StringMid($UpdSeqArrOffset,1,2))
	$UpdSeqArrSize = StringMid($MFTRecordDump,15,4)
	$UpdSeqArrSize = Dec(StringMid($UpdSeqArrSize,3,2) & StringMid($UpdSeqArrSize,1,2))
	$UpdSeqArr = StringMid($MFTRecordDump,3+($UpdSeqArrOffset*2),$UpdSeqArrSize*2*2)
	;ConsoleWrite("$UpdSeqArr: " & $UpdSeqArr & @crlf)
	;ConsoleWrite("Dump of record for " & $cmdline[1] & @crlf)
	;ConsoleWrite(_HexEncode($MFTRecordDump) & @crlf)

	If $MFT_Record_Size = 1024 Then
		Local $UpdSeqArrPart0 = StringMid($UpdSeqArr,1,4)
		Local $UpdSeqArrPart1 = StringMid($UpdSeqArr,5,4)
		Local $UpdSeqArrPart2 = StringMid($UpdSeqArr,9,4)
		Local $RecordEnd1 = StringMid($MFTRecordDump,1023,4)
		Local $RecordEnd2 = StringMid($MFTRecordDump,2047,4)
		If $UpdSeqArrPart0 <> $RecordEnd1 OR $UpdSeqArrPart0 <> $RecordEnd2 Then
			ConsoleWrite("The record failed Fixup for ref " & $TargetRef)
			ConsoleWrite(_HexEncode($MFTRecordDump) & @CRLF)
			Return 0
		EndIf
		$MFTRecordDump = StringMid($MFTRecordDump,1,1022) & $UpdSeqArrPart1 & StringMid($MFTRecordDump,1027,1020) & $UpdSeqArrPart2
	ElseIf $MFT_Record_Size = 4096 Then
		Local $UpdSeqArrPart0 = StringMid($UpdSeqArr,1,4)
		Local $UpdSeqArrPart1 = StringMid($UpdSeqArr,5,4)
		Local $UpdSeqArrPart2 = StringMid($UpdSeqArr,9,4)
		Local $UpdSeqArrPart3 = StringMid($UpdSeqArr,13,4)
		Local $UpdSeqArrPart4 = StringMid($UpdSeqArr,17,4)
		Local $UpdSeqArrPart5 = StringMid($UpdSeqArr,21,4)
		Local $UpdSeqArrPart6 = StringMid($UpdSeqArr,25,4)
		Local $UpdSeqArrPart7 = StringMid($UpdSeqArr,29,4)
		Local $UpdSeqArrPart8 = StringMid($UpdSeqArr,33,4)
		Local $RecordEnd1 = StringMid($MFTRecordDump,1023,4)
		Local $RecordEnd2 = StringMid($MFTRecordDump,2047,4)
		Local $RecordEnd3 = StringMid($MFTRecordDump,3071,4)
		Local $RecordEnd4 = StringMid($MFTRecordDump,4095,4)
		Local $RecordEnd5 = StringMid($MFTRecordDump,5119,4)
		Local $RecordEnd6 = StringMid($MFTRecordDump,6143,4)
		Local $RecordEnd7 = StringMid($MFTRecordDump,7167,4)
		Local $RecordEnd8 = StringMid($MFTRecordDump,8191,4)
		If $UpdSeqArrPart0 <> $RecordEnd1 OR $UpdSeqArrPart0 <> $RecordEnd2 OR $UpdSeqArrPart0 <> $RecordEnd3 OR $UpdSeqArrPart0 <> $RecordEnd4 OR $UpdSeqArrPart0 <> $RecordEnd5 OR $UpdSeqArrPart0 <> $RecordEnd6 OR $UpdSeqArrPart0 <> $RecordEnd7 OR $UpdSeqArrPart0 <> $RecordEnd8 Then
			ConsoleWrite("The record failed Fixup for ref " & $TargetRef)
			ConsoleWrite(_HexEncode($MFTRecordDump) & @CRLF)
			Return 0
		Else
			$MFTRecordDump =  StringMid($MFTRecordDump,1,1022) & $UpdSeqArrPart1 & StringMid($MFTRecordDump,1027,1020) & $UpdSeqArrPart2 & StringMid($MFTRecordDump,2051,1020) & $UpdSeqArrPart3 & StringMid($MFTRecordDump,3075,1020) & $UpdSeqArrPart4 & StringMid($MFTRecordDump,4099,1020) & $UpdSeqArrPart5 & StringMid($MFTRecordDump,5123,1020) & $UpdSeqArrPart6 & StringMid($MFTRecordDump,6147,1020) & $UpdSeqArrPart7 & StringMid($MFTRecordDump,7171,1020) & $UpdSeqArrPart8
		EndIf
	EndIf

	If $DoSi Then
		Select
			Case $DoCTime
				$MFTRecordDump = StringMid($MFTRecordDump,1,$SIArrOffset[2][1]-1) & $NewTimestampShifted & StringMid($MFTRecordDump,$SIArrOffset[2][1]+16,($MFT_Record_Size*2)-$SIArrOffset[2][1])
			Case $DoATime
				$MFTRecordDump = StringMid($MFTRecordDump,1,$SIArrOffset[3][1]-1) & $NewTimestampShifted & StringMid($MFTRecordDump,$SIArrOffset[3][1]+16,($MFT_Record_Size*2)-$SIArrOffset[3][1])
			Case $DoMTime
				$MFTRecordDump = StringMid($MFTRecordDump,1,$SIArrOffset[4][1]-1) & $NewTimestampShifted & StringMid($MFTRecordDump,$SIArrOffset[4][1]+16,($MFT_Record_Size*2)-$SIArrOffset[4][1])
			Case $DoRTime
				$MFTRecordDump = StringMid($MFTRecordDump,1,$SIArrOffset[5][1]-1) & $NewTimestampShifted & StringMid($MFTRecordDump,$SIArrOffset[5][1]+16,($MFT_Record_Size*2)-$SIArrOffset[5][1])
			Case $DoAll4Timestamps
				$MFTRecordDump = StringMid($MFTRecordDump,1,$SIArrOffset[2][1]-1) & $NewTimestampShifted & $NewTimestampShifted & $NewTimestampShifted & $NewTimestampShifted & StringMid($MFTRecordDump,$SIArrOffset[5][1]+16,($MFT_Record_Size*2)-$SIArrOffset[5][1])
		EndSelect
	EndIf
	If $DoFn Then
		For $number=1 To $FN_Number
			Select
				Case $DoCTime
					$MFTRecordDump = StringMid($MFTRecordDump,1,$FNArrOffset[3][$number]-1) & $NewTimestampShifted & StringMid($MFTRecordDump,$FNArrOffset[3][$number]+16,($MFT_Record_Size*2)-$FNArrOffset[3][$number])
				Case $DoATime
					$MFTRecordDump = StringMid($MFTRecordDump,1,$FNArrOffset[4][$number]-1) & $NewTimestampShifted & StringMid($MFTRecordDump,$FNArrOffset[4][$number]+16,($MFT_Record_Size*2)-$FNArrOffset[4][$number])
				Case $DoMTime
					$MFTRecordDump = StringMid($MFTRecordDump,1,$FNArrOffset[5][$number]-1) & $NewTimestampShifted & StringMid($MFTRecordDump,$FNArrOffset[5][$number]+16,($MFT_Record_Size*2)-$FNArrOffset[5][$number])
				Case $DoRTime
					$MFTRecordDump = StringMid($MFTRecordDump,1,$FNArrOffset[6][$number]-1) & $NewTimestampShifted & StringMid($MFTRecordDump,$FNArrOffset[6][$number]+16,($MFT_Record_Size*2)-$FNArrOffset[6][$number])
				Case $DoAll4Timestamps
					$MFTRecordDump = StringMid($MFTRecordDump,1,$FNArrOffset[3][$number]-1) & $NewTimestampShifted & $NewTimestampShifted & $NewTimestampShifted & $NewTimestampShifted & StringMid($MFTRecordDump,$FNArrOffset[6][$number]+16,($MFT_Record_Size*2)-$FNArrOffset[6][$number])
			EndSelect
		Next
	EndIf

; fixup
	$OffsetToUsa = 3+($UpdSeqArrOffset*2) ;offset of usa ()
	If $MFT_Record_Size = 1024 Then
		$RecordHeaderBeforeUsa = StringMid($MFTRecordDump,1,$OffsetToUsa-1) ;Record header up until usa
		$UpdateSequenceNumber = StringMid($MFTRecordDump,$OffsetToUsa,4)
		$UsaPart1 = StringMid($MFTRecordDump,1023,4)
		$UsaPart2 = StringMid($MFTRecordDump,2047,4)
		$RecordSector1Rest = StringMid($MFTRecordDump,$OffsetToUsa+12,1023-($OffsetToUsa+12)) ;From end of usa and until end of sector 1
		$RecordSector2 = StringMid($MFTRecordDump,1027,1020)
		$MFTRecordDump = $RecordHeaderBeforeUsa & $UpdateSequenceNumber & $UsaPart1 & $UsaPart2 & $RecordSector1Rest & $UpdateSequenceNumber & $RecordSector2 & $UpdateSequenceNumber
	ElseIf $MFT_Record_Size = 4096 Then
		$RecordHeaderBeforeUsa = StringMid($MFTRecordDump,1,$OffsetToUsa-1) ;Record header up until usa
		$UpdateSequenceNumber = StringMid($MFTRecordDump,$OffsetToUsa,4)
		$UsaPart1 = StringMid($MFTRecordDump,1023,4)
		$UsaPart2 = StringMid($MFTRecordDump,2047,4)
		$UsaPart3 = StringMid($MFTRecordDump,3071,4)
		$UsaPart4 = StringMid($MFTRecordDump,4095,4)
		$UsaPart5 = StringMid($MFTRecordDump,5119,4)
		$UsaPart6 = StringMid($MFTRecordDump,6143,4)
		$UsaPart7 = StringMid($MFTRecordDump,7167,4)
		$UsaPart8 = StringMid($MFTRecordDump,8191,4)
		$RecordSector1Rest = StringMid($MFTRecordDump,$OffsetToUsa+36,1023-($OffsetToUsa+36)) ;From end of usa and until end of sector 1
		$RecordSector2 = StringMid($MFTRecordDump,1027,1020)
		$RecordSector3 = StringMid($MFTRecordDump,2051,1020)
		$RecordSector4 = StringMid($MFTRecordDump,3075,1020)
		$RecordSector5 = StringMid($MFTRecordDump,4099,1020)
		$RecordSector6 = StringMid($MFTRecordDump,5123,1020)
		$RecordSector7 = StringMid($MFTRecordDump,6147,1020)
		$RecordSector8 = StringMid($MFTRecordDump,7171,1020)
		$MFTRecordDump = $RecordHeaderBeforeUsa & $UpdateSequenceNumber & $UsaPart1 & $UsaPart2 & $UsaPart3 & $UsaPart4 & $UsaPart5 & $UsaPart6 & $UsaPart7 & $UsaPart8 & $RecordSector1Rest & $UpdateSequenceNumber & $RecordSector2 & $UpdateSequenceNumber & $RecordSector3 & $UpdateSequenceNumber & $RecordSector4 & $UpdateSequenceNumber & $RecordSector5 & $UpdateSequenceNumber & $RecordSector6 & $UpdateSequenceNumber & $RecordSector7 & $UpdateSequenceNumber & $RecordSector8 & $UpdateSequenceNumber
	Else
		ConsoleWrite("Error: MFT record size incorrect: " & $MFT_Record_Size & @crlf)
		Return 0
	EndIf
;	ConsoleWrite("Dump of modified record " & @crlf)
;	ConsoleWrite(_HexEncode($MFTRecordDump) & @crlf)

	;Put modified MFT entry into new buffer
	Local $tBuffer2 = DllStructCreate("byte[" & $MFT_Record_Size & "]")
	DllStructSetData($tBuffer2,1,$MFTRecordDump)

	Return _WriteIt($DiskOffset, $tBuffer2)
EndFunc

Func _WriteIt($DiskOffset, $tBuffer)
	Local $nBytes
	;Determine correct registry location
	If @AutoItX64 Then
		;ConsoleWrite("64-bit mode" & @CRLF)
		$RegRoot = "HKLM64"
	Else
		;ConsoleWrite("32-bit mode" & @CRLF)
		$RegRoot = "HKLM"
	EndIf

	If @OSArch = "X86" Then
		$DriverFile = @ScriptDir&"\sectorio.sys"
		$TargetRCDataNumber = 1
	Else
		$DriverFile = @ScriptDir&"\sectorio64.sys"
		$TargetRCDataNumber = 2
	EndIf

	Local $ServiceName = $Drivername

	;Put modified MFT entry into new buffer
;	Local $tBuffer2 = DllStructCreate("byte[" & $MFT_Record_Size & "]")
;	DllStructSetData($tBuffer2,1,$MFTRecordDump)

	If _PrepareDriver() Then
		;Try to write with driver
		Local $DriverJobOk = _SectorIo($TargetDrive, $DiskOffset, $tBuffer)
		If Not @error And $DriverJobOk > 0 Then
			_NtUnloadDriver($ServiceName)
			FileDelete($DriverFile)
			RegDelete($RegRoot & "\SYSTEM\CurrentControlSet\Services\" & $ServiceName)
			ConsoleWrite("Success writing timestamps to disk at offset 0x" & Hex(Int($DriverJobOk)) & @crlf)
			Return 1
		Else
			_NtUnloadDriver($ServiceName)
			FileDelete($DriverFile)
			RegDelete($RegRoot & "\SYSTEM\CurrentControlSet\Services\" & $ServiceName)
			ConsoleWrite("Error writing timestamps to disk with driver" & @crlf)
		EndIf
	Else
		ConsoleWrite("Error: Could not load driver" & @crlf)
	EndIf
	ConsoleWrite("Attempting write to physical disk without driver" & @crlf)

	;If driver failed, try basic method with WriteFile
	If @OSBuild >= 6000 And $NeedLock Then
;		If $DoShadows Then Run("cmd /c net stop vss","",@SW_HIDE)
		If StringLeft(@AutoItExe,2) = $TargetDrive Then
			ConsoleWrite("Error: You can't lock the volume that SetMace is run from" & @crlf)
			Return 0
		EndIf
		$hFile = _WinAPI_LockVolume($TargetDrive)
		If @error Then
			$hFile = _WinAPI_DismountVolumeMod($TargetDrive)
			If $hFile = 0 Then
				ConsoleWrite("Error: Could not dismount " & $TargetDrive & @CRLF)
				Return 0
			EndIf
			ConsoleWrite("Success dismounting " & $TargetDrive & @CRLF)
			$IsDismounted = 1
		Else
			$IsLocked = 1
			ConsoleWrite("Successfully locked " & $TargetDrive & @CRLF)
		EndIf
	Else
		Local $hFile = _WinAPI_CreateFile("\\.\" & $TargetDrive,2,6,7)
		If $hFile = 0 then
			ConsoleWrite("Error CreateFile in function _RawModMft(): " & _WinAPI_GetLastErrorMessage() & " for: " & "\\.\" & $TargetDrive & @crlf)
			Return 0
		EndIf
	EndIf
	_WinAPI_SetFilePointerEx($hFile, $DiskOffset)
	_WinAPI_WriteFile($hFile, DllStructGetPtr($tBuffer), DllStructGetSize($tBuffer), $nBytes)
	If _WinAPI_GetLastError() <> 0 Then
		ConsoleWrite("Error: WriteFile returned: " & _WinAPI_GetLastErrorMessage() & @crlf)
		_WinAPI_CloseHandle($hFile)
		Return 0
	Else
		ConsoleWrite("Success writing timestamps" & @crlf)
	EndIf
	_WinAPI_FlushFileBuffers($hFile)
	_WinAPI_CloseHandle($hFile)
	Return 1
EndFunc


Func _PrepareDriver()
	;Determine correct registry location
	If @AutoItX64 Then
		;ConsoleWrite("64-bit mode" & @CRLF)
		$RegRoot = "HKLM64"
	Else
		;ConsoleWrite("32-bit mode" & @CRLF)
		$RegRoot = "HKLM"
	EndIf

	If @OSArch = "X86" Then
		$DriverFile = @ScriptDir&"\sectorio.sys"
		$TargetRCDataNumber = 1
	Else
		$DriverFile = @ScriptDir&"\sectorio64.sys"
		$TargetRCDataNumber = 2
	EndIf

	Local $ServiceName = $Drivername
	Local $ImagePath = "\??\"&$DriverFile

	;Write registry information for service
	RegWrite($RegRoot & "\SYSTEM\CurrentControlSet\Services\" & $ServiceName)
	RegWrite($RegRoot&"\SYSTEM\CurrentControlSet\Services\"&$ServiceName,"","REG_SZ","")
	RegWrite($RegRoot&"\SYSTEM\CurrentControlSet\Services\"&$ServiceName,"Type","REG_DWORD",1)
	RegWrite($RegRoot&"\SYSTEM\CurrentControlSet\Services\"&$ServiceName,"ImagePath","REG_EXPAND_SZ",$ImagePath)
	RegWrite($RegRoot&"\SYSTEM\CurrentControlSet\Services\"&$ServiceName,"Start","REG_DWORD",3)
	RegWrite($RegRoot&"\SYSTEM\CurrentControlSet\Services\"&$ServiceName,"ErrorControl","REG_DWORD",1)

	;Set permission to load drivers
	_SetPrivilege("SeLoadDriverPrivilege")
	If @error Then
		ConsoleWrite("Error assigning SeLoadDriverPrivilege" & @CRLF)
		return 0
	EndIf

	;Get driver from resource
	_WriteFileFromResource($DriverFile,$TargetRCDataNumber)
	If @error Or FileExists($DriverFile)=0 Then
;		ConsoleWrite("Error finding driver" & @CRLF)
		FileDelete($DriverFile)
		return 0
	EndIf

	;Load driver
	_NtLoadDriver($ServiceName)
	If @error Then
		RegDelete($RegRoot & "\SYSTEM\CurrentControlSet\Services\" & $ServiceName)
		FileDelete($DriverFile)
		return 0
	EndIf
	return 1
EndFunc

Func _config_timestamp()
	Local $timestamp_array, $input2LocalFileTime[9]
	If StringLen($cmdline[3]) <> 28 Then
		ConsoleWrite("Error: Length of date/time is not correct: " & $cmdline[3] & @CRLF)
		Exit
	EndIf
	$timestamp_array = StringSplit(StringReplace($cmdline[3],'"',''),":")
	If $timestamp_array[0] <> 8 Then
		ConsoleWrite("Error: Not right date/time parameters supplied: " & $timestamp_array[0] & @CRLF)
		Exit
	EndIf
	For $dateinputs = 1 To $timestamp_array[0]
		If StringIsDigit($timestamp_array[$dateinputs]) <> 1 Then
			ConsoleWrite("Error: Not right date/time format supplied: " & $timestamp_array[$dateinputs] & @CRLF)
			Exit
		EndIf
		If StringLen($timestamp_array[$dateinputs]) <> 2 And StringLen($timestamp_array[$dateinputs]) <> 4 And $dateinputs <> 7 Then
			ConsoleWrite("Error: Not right date/time format supplied: " & $timestamp_array[$dateinputs] & @CRLF)
			Exit
		EndIf
		If StringLen($timestamp_array[$dateinputs]) <> 3 And $dateinputs = 7 Then
			ConsoleWrite("Error: Not right date/time format supplied for MilliSec: " & $timestamp_array[$dateinputs] & @CRLF)
			Exit
		EndIf
		If StringLen($timestamp_array[$dateinputs]) <> 4 And $dateinputs = 8 Then
			ConsoleWrite("Error: Not right date/time format supplied for NanoSec: " & $timestamp_array[$dateinputs] & @CRLF)
			Exit
		EndIf
	Next
	$input2LocalFileTime[0] = _WinTime_SystemTimeToLocalFileTime($timestamp_array[1],$timestamp_array[2],$timestamp_array[3],$timestamp_array[4],$timestamp_array[5],$timestamp_array[6],$timestamp_array[7],-1)
	$input2LocalFileTime[1] = $timestamp_array[1]
	$input2LocalFileTime[2] = $timestamp_array[2]
	$input2LocalFileTime[3] = $timestamp_array[3]
	$input2LocalFileTime[4] = $timestamp_array[4]
	$input2LocalFileTime[5] = $timestamp_array[5]
	$input2LocalFileTime[6] = $timestamp_array[6]
	$input2LocalFileTime[7] = $timestamp_array[7]
	$input2LocalFileTime[8] = $timestamp_array[8]
	Return $input2LocalFileTime
EndFunc

Func _ShiftEndian($aa)
	Local $ab, $ac
	$abc = StringLen($aa)
	If NOT IsInt($abc/2) Then
		$aa = '0' & $aa
	EndIf
	For $i = 1 To $abc Step 2
		$ab = StringMid($aa,$abc-$i,2)
		$ac &= $ab
	Next
	Return $ac
EndFunc

Func _validate_parameters()
	Local $FileAttrib
	If $cmdline[0] < 2 Then
		ConsoleWrite("Error: Incorrect parameters supplied" & @CRLF & @CRLF)
		_PrintHelp()
		Exit
	EndIf
	If Not StringMid($cmdline[1],2,1) = ":" Then
		ConsoleWrite("Error: parameter incorrect" & @CRLF & @CRLF)
		_PrintHelp()
		Exit
	EndIf
	If $cmdline[2] <> "-d" Then
		If $cmdline[0] <> 4 And $cmdline[0] <> 5 Then
			ConsoleWrite("Error: Wrong number of parameters supplied: " & $cmdline[0] & @CRLF & @CRLF)
			_PrintHelp()
			Exit
		EndIf
		If $cmdline[4] <> "-x" And $cmdline[4] <> "-fn" And $cmdline[4] <> "-si" Then
			ConsoleWrite("Error: Input parameter number 4 is unknown: " & $cmdline[4] & @CRLF & @CRLF)
			_PrintHelp()
			Exit
		EndIf
		If $cmdline[2] = "-c" Then $DoCTime=1
		If $cmdline[2] = "-m" Then $DoATime=1
		If $cmdline[2] = "-e" Then $DoMTime=1
		If $cmdline[2] = "-a" Then $DoRTime=1
		If $cmdline[2] = "-z" Then $DoAll4Timestamps=1
		If $cmdline[4] = "-si" Then $DoSi=1
		If $cmdline[4] = "-fn" Then $DoFn=1
		If $cmdline[4] = "-x" Then
			$DoSi=1
			$DoFn=1
		EndIf
		If @OSBuild >= 6000 Then $NeedLock = 1
		If $cmdline[0] = 5 Then
			If $cmdline[5] = "-shadow" Then $DoShadows = 1
		EndIf
	EndIf
	If $cmdline[2] = "-d" Then
		If $cmdline[0] <> 2 And $cmdline[0] <> 3 Then
			ConsoleWrite("Error: Wrong number of parameters supplied: " & $cmdline[0] & @CRLF & @CRLF)
			_PrintHelp()
			Exit
		EndIf
		$DoRead=1
		$NeedLock = 0
		If $cmdline[0] = 3 Then
			If $cmdline[3] = "-shadow" Then $DoShadows = 1
		EndIf
	EndIf
	If $cmdline[2] <> "-m" And  $cmdline[2] <> "-a" And $cmdline[2] <> "-c" And $cmdline[2] <> "-e" And $cmdline[2] <> "-z" And $cmdline[2] <> "-d" And $cmdline[2] <> "-g" Then
		ConsoleWrite("Error: Input parameter number 2 is unknown: " & $cmdline[2] & @CRLF & @CRLF)
		_PrintHelp()
		Exit
	EndIf
EndFunc

Func _SwapEndian($iHex)
	Return StringMid(Binary(Dec($iHex,2)),3, StringLen($iHex))
EndFunc

Func _AttribHeaderFlags($AHinput)
	Local $AHoutput = ""
	If BitAND($AHinput,0x0001) Then $AHoutput &= 'COMPRESSED+'
	If BitAND($AHinput,0x4000) Then $AHoutput &= 'ENCRYPTED+'
	If BitAND($AHinput,0x8000) Then $AHoutput &= 'SPARSE+'
	$AHoutput = StringTrimRight($AHoutput,1)
	Return $AHoutput
EndFunc

Func _File_Permissions($FPinput)
	Local $FPoutput = ""
	If BitAND($FPinput,0x0001) Then $FPoutput &= 'read_only+'
	If BitAND($FPinput,0x0002) Then $FPoutput &= 'hidden+'
	If BitAND($FPinput,0x0004) Then $FPoutput &= 'system+'
	If BitAND($FPinput,0x0020) Then $FPoutput &= 'archive+'
	If BitAND($FPinput,0x0040) Then $FPoutput &= 'device+'
	If BitAND($FPinput,0x0080) Then $FPoutput &= 'normal+'
	If BitAND($FPinput,0x0100) Then $FPoutput &= 'temporary+'
	If BitAND($FPinput,0x0200) Then $FPoutput &= 'sparse_file+'
	If BitAND($FPinput,0x0400) Then $FPoutput &= 'reparse_point+'
	If BitAND($FPinput,0x0800) Then $FPoutput &= 'compressed+'
	If BitAND($FPinput,0x1000) Then $FPoutput &= 'offline+'
	If BitAND($FPinput,0x2000) Then $FPoutput &= 'not_indexed+'
	If BitAND($FPinput,0x4000) Then $FPoutput &= 'encrypted+'
	If BitAND($FPinput,0x10000000) Then $FPoutput &= 'directory+'
	If BitAND($FPinput,0x20000000) Then $FPoutput &= 'index_view+'
	$FPoutput = StringTrimRight($FPoutput,1)
	Return $FPoutput
EndFunc

Func _PrintHelp()
	ConsoleWrite("Examples:" & @CRLF)
	ConsoleWrite("" & @CRLF)
	ConsoleWrite("Setting the CreationTime in the $STANDARD_INFORMATION attribute:" & @CRLF)
	ConsoleWrite('setmace.exe C:\file.txt -c "2000:01:01:00:00:00:789:1234" -si' & @CRLF)
	ConsoleWrite("" & @CRLF)
	ConsoleWrite("Setting the LastAccessTime in the $STANDARD_INFORMATION attribute:" & @CRLF)
	ConsoleWrite('setmace.exe C:\file.txt -a "2000:01:01:00:00:00:789:1234" -si' & @CRLF)
	ConsoleWrite("" & @CRLF)
	ConsoleWrite("Setting the LastWriteTime in the $FILE_NAME attribute:" & @CRLF)
	ConsoleWrite('setmace.exe C:\file.txt -m "2000:01:01:00:00:00:789:1234" -fn' & @CRLF)
	ConsoleWrite("" & @CRLF)
	ConsoleWrite("Setting the ChangeTime(MFT) in the $FILE_NAME attribute:" & @CRLF)
	ConsoleWrite('setmace.exe C:\file.txt -e "2000:01:01:00:00:00:789:1234" -fn' & @CRLF)
	ConsoleWrite("" & @CRLF)
	ConsoleWrite("setting all 4+4 timestamps in the $FILE_NAME attribute for a file with long filename:" & @CRLF)
	ConsoleWrite('setmace.exe "C:\a long filename.txt" -z "2000:01:01:00:00:00:789:1234" -fn' & @CRLF)
	ConsoleWrite("" & @CRLF)
	ConsoleWrite("setting 1+1 timestamps ($MFT creation time * 2) in the $FILE_NAME attribute for a file with long filename:" & @CRLF)
	ConsoleWrite('setmace.exe "C:\a long filename.txt" -e "2000:01:01:00:00:00:789:1234" -fn' & @CRLF)
	ConsoleWrite("" & @CRLF)
	ConsoleWrite("Setting all 4+4 (or 4+8) timestamps in both $STANDARD_INFORMATION and $FILE_NAME attributes:" & @CRLF)
	ConsoleWrite('setmace.exe C:\file.txt -z "2000:01:01:00:00:00:789:1234" -x' & @CRLF)
	ConsoleWrite("" & @CRLF)
	ConsoleWrite("Setting the LastWriteTime in both $STANDARD_INFORMATION and $FILE_NAME attribute of root directory (defined by its index number):" & @CRLF)
	ConsoleWrite('setmace.exe C:5 -m "2000:01:01:00:00:00:789:1234" -x' & @CRLF)
	ConsoleWrite("" & @CRLF)
	ConsoleWrite("Setting the LastWriteTime in the $STANDARD_INFORMATION attribute, for current timestamps and in all shadow copies:" & @CRLF)
	ConsoleWrite('setmace.exe C:\file.txt -m "2000:01:01:00:00:00:789:1234" -si -shadow' & @CRLF)
	ConsoleWrite("" & @CRLF)
	ConsoleWrite("Dumping all timestamps for $Boot (including all shadow copies):" & @CRLF)
	ConsoleWrite('setmace.exe C:\$Boot -d -shadow' & @CRLF)
	ConsoleWrite("" & @CRLF)
	ConsoleWrite("2 methods for dumping all timestamps for $MFT itself (no shadow copy timestamps displayed):" & @CRLF)
	ConsoleWrite('setmace.exe C:\$MFT -d' & @CRLF)
	ConsoleWrite('or' & @CRLF)
	ConsoleWrite('setmace.exe C:0 -d' & @CRLF)
EndFunc

Func _NtLoadDriver($TargetServiceName)
	$FullServiceName = "\Registry\Machine\SYSTEM\CurrentControlSet\Services\"&$TargetServiceName
	$szName = DllStructCreate("wchar[260]")
	$sUS = DllStructCreate($tagUNICODESTRING)
	DllStructSetData($szName, 1, $FullServiceName)
	$ret = DllCall("ntdll.dll", "none", "RtlInitUnicodeString", "ptr", DllStructGetPtr($sUS), "ptr", DllStructGetPtr($szName))
	$ret = DllCall("ntdll.dll", "int", "NtLoadDriver","ptr",DllStructGetPtr($sUS))
	If Not NT_SUCCESS($ret[0]) And $ret[0] <> 0xC000010E Then
		ConsoleWrite("Error: NtLoadDriver: 0x" & Hex($ret[0])& @CRLF)
		Return SetError(1,0,0)
	EndIf
EndFunc

Func _NtUnloadDriver($TargetServiceName)
	$FullServiceName = "\Registry\Machine\SYSTEM\CurrentControlSet\Services\"&$TargetServiceName
	$szName = DllStructCreate("wchar[260]")
	$sUS = DllStructCreate($tagUNICODESTRING)
	DllStructSetData($szName, 1, $FullServiceName)
	$ret = DllCall("ntdll.dll", "none", "RtlInitUnicodeString", "ptr", DllStructGetPtr($sUS), "ptr", DllStructGetPtr($szName))
	$ret = DllCall("ntdll.dll", "int", "NtUnloadDriver","ptr",DllStructGetPtr($sUS))
	If Not NT_SUCCESS($ret[0]) Then
		ConsoleWrite("Error: NtUnloadDriver: 0x" & Hex($ret[0])& @CRLF)
		Return SetError(1,0,0)
	EndIf
EndFunc

Func _SetPrivilege($Privilege)
    Local $tagLUIDANDATTRIB = "int64 Luid;dword Attributes"
    Local $count = 1
    Local $tagTOKENPRIVILEGES = "dword PrivilegeCount;byte LUIDandATTRIB[" & $count * 12 & "]"
    Local $TOKEN_ADJUST_PRIVILEGES = 0x20
    Local $SE_PRIVILEGE_ENABLED = 0x2

    Local $curProc = DllCall("kernel32.dll", "ptr", "GetCurrentProcess")
	Local $call = DllCall("advapi32.dll", "int", "OpenProcessToken", "ptr", $curProc[0], "dword", $TOKEN_ALL_ACCESS, "ptr*", "")
    If Not $call[0] Then Return False
    Local $hToken = $call[3]

    $call = DllCall("advapi32.dll", "int", "LookupPrivilegeValue", "str", "", "str", $Privilege, "int64*", "")
    Local $iLuid = $call[3]

    Local $TP = DllStructCreate($tagTOKENPRIVILEGES)
	Local $TPout = DllStructCreate($tagTOKENPRIVILEGES)
    Local $LUID = DllStructCreate($tagLUIDANDATTRIB, DllStructGetPtr($TP, "LUIDandATTRIB"))

    DllStructSetData($TP, "PrivilegeCount", $count)
    DllStructSetData($LUID, "Luid", $iLuid)
    DllStructSetData($LUID, "Attributes", $SE_PRIVILEGE_ENABLED)

    $call = DllCall("advapi32.dll", "int", "AdjustTokenPrivileges", "ptr", $hToken, "int", 0, "ptr", DllStructGetPtr($TP), "dword", DllStructGetSize($TPout), "ptr", DllStructGetPtr($TPout), "dword*", 0)
	$lasterror = _WinAPI_GetLastError()
	If $lasterror <> 0 Then
		ConsoleWrite("AdjustTokenPrivileges ("&$Privilege&"): " & _WinAPI_GetLastErrorMessage() & @CRLF)
		DllCall("kernel32.dll", "int", "CloseHandle", "ptr", $hToken)
		Return SetError(1, 0, 0)
	EndIf
    DllCall("kernel32.dll", "int", "CloseHandle", "ptr", $hToken)
    Return ($call[0] <> 0)
EndFunc

Func _DeviceIoControl($hFile, $IoControlCode, $InputBuffer, $OutputBuffer)
	Local $Ret = DllCall('kernel32.dll', 'int', 'DeviceIoControl', 'ptr', $hFile, 'dword', $IoControlCode, 'ptr', DllStructGetPtr($InputBuffer), "ulong", DllStructGetSize($InputBuffer), 'ptr', DllStructGetPtr($OutputBuffer), "ulong", DllStructGetSize($OutputBuffer), 'dword*', 0, 'ptr', 0)
	;ConsoleWrite("DeviceIoControl: 0x" & Hex($Ret[0]) & @CRLF)
	If (@error) Or (Not $Ret[0]) Then
		ConsoleWrite("Error in DeviceIoControl: " & _WinAPI_GetLastErrorMessage())
		_WinAPI_CloseHandle($hFile)
		Return SetError(1, 0, 0)
	EndIf
	Return $OutputBuffer
EndFunc

Func _SectorIo($TargetVolume,$VolumeOffsetForWrite,$GarbadgeData)
	Local $DiskOffsetForWrite, $PhysicalDriveNoN, $dwDiskObjOrdinal, $ullSectorNumber, $bIsRawDisk = 1, $TargetDevice = "\\.\sectorio", $DriverFile, $TargetRCDataNumber
	Local $tagDISK_LOCATION = "align 1;byte bIsRawDisk;dword dwDiskObjOrdinal;uint64 ullSectorNumber"
	Local $IOCTL_CODE_READ=0x8000E000
	Local $IOCTL_CODE_WRITE=0x8000E004
	Local $IOCTL_CODE_GET_SECTOR_SIZE=0x8000E008
	Local $NewDataSize=DllStructGetSize($GarbadgeData)
	If @error Or ($MFT_Record_Size <> $NewDataSize And $INDX_Record_Size <> $NewDataSize) Then
		ConsoleWrite("Error new MFT record buffer invalid" & @CRLF)
		return 0
	EndIf

	;Check offset
	If $VolumeOffsetForWrite = 0 Then
		ConsoleWrite("Error volume offset invalid" & @CRLF)
		return 0
	EndIf

	;Resolve physical offset of volume
	$PartitionInfo = _WinAPI_GetPartitionInfoEx($TargetVolume)
	If @error Then return 0
	$DiskOffsetForWrite = $VolumeOffsetForWrite + $PartitionInfo[1]
	If $DiskOffsetForWrite = 0 Then
		ConsoleWrite("Error disk offset invalid" & @CRLF)
		return 0
	EndIf
;	ConsoleWrite("$VolumeOffsetForWrite: " & $VolumeOffsetForWrite & @CRLF)
;	ConsoleWrite("$PartitionInfo[1]: " & $PartitionInfo[1] & @CRLF)

	;Determine sector number
	$ullSectorNumber = $DiskOffsetForWrite/$BytesPerSector
;	ConsoleWrite("$DiskOffsetForWrite: " & $DiskOffsetForWrite & @CRLF)
;	ConsoleWrite("$BytesPerSector: " & $BytesPerSector & @CRLF)
;	ConsoleWrite("$ullSectorNumber: " & $ullSectorNumber & @CRLF)

	;Work out which PhysicalDrive the volume is on
	If StringLen($TargetVolume)<>2 Then $TargetVolume = StringMid($TargetVolume,1,2)
	$PhysicalDriveN = _WinAPI_GetDriveNumber($TargetVolume)
	If @error Then
		ConsoleWrite("Error in GetDriveNumber: " & _WinAPI_GetLastErrorMessage())
		Return 0
	EndIf
	$dwDiskObjOrdinal = $PhysicalDriveN[1]
	ConsoleWrite("Volume resolved to \\.\PhysicalDrive" & $dwDiskObjOrdinal & @CRLF)

	;Prepare buffers
	Local $TestBuffer = DllStructCreate("byte["&$NewDataSize+13&"]")
	If @error Then return 0
	Local $pDISK_LOCATION = DllStructCreate($tagDISK_LOCATION,DllStructGetPtr($TestBuffer))
	If @error Then return 0
	DllStructSetData($pDISK_LOCATION,"bIsRawDisk",$bIsRawDisk)
	If @error Then return 0
	DllStructSetData($pDISK_LOCATION,"dwDiskObjOrdinal",$dwDiskObjOrdinal)
	If @error Then return 0
	DllStructSetData($pDISK_LOCATION,"ullSectorNumber",$ullSectorNumber)
	If @error Then return 0
	Local $pGARBADGE = DllStructCreate("byte["&$NewDataSize&"]",DllStructGetPtr($TestBuffer)+13)
	If @error Then return 0
	;DllStructSetData($pGARBADGE,1,'0x'&$GarbadgeData)
	DllStructSetData($pGARBADGE,1,DllStructGetData($GarbadgeData,1))
	If @error Then return 0
	Local $NewRecordBuff = DllStructCreate("byte["&DllStructGetSize($TestBuffer)&"]",DllStructGetPtr($TestBuffer))
	If @error Then return 0
	;This one is strictly not needed here, and only required with read operations
	Local $OutputBuff2 = DllStructCreate("byte["&$NewDataSize&"]")
	If @error Then return 0

	;Create handle to device
	$hDevice = _WinAPI_CreateFileEx($TargetDevice, $OPEN_EXISTING, BitOR($GENERIC_READ,$GENERIC_WRITE), BitOR($FILE_SHARE_READ,$FILE_SHARE_WRITE),$FILE_ATTRIBUTE_NORMAL)
	If Not $hDevice Then
		ConsoleWrite("Error CreateFile in function _SectorIo() for " & $TargetDevice & " : " & _WinAPI_GetLastErrorMessage())
		;_NtUnloadDriver($ServiceName)
		;FileDelete($DriverFile)
		;RegDelete($RegRoot & "\SYSTEM\CurrentControlSet\Services\" & $ServiceName)
		return 0
	EndIf

	;Send buffer with data and ioctl to driver
	Local $ResultBuffer2 = _DeviceIoControl($hDevice, $IOCTL_CODE_WRITE, $NewRecordBuff, 0)
	If @error Then
		DllCall("ntdll.dll", "int", "NtClose","handle",$hDevice)
		;_NtUnloadDriver($ServiceName)
		;FileDelete($DriverFile)
		;RegDelete($RegRoot & "\SYSTEM\CurrentControlSet\Services\" & $ServiceName)
		return 0
	Else
		DllCall("ntdll.dll", "int", "NtClose","handle",$hDevice)
		;_NtUnloadDriver($ServiceName)
		;FileDelete($DriverFile)
		;RegDelete($RegRoot & "\SYSTEM\CurrentControlSet\Services\" & $ServiceName)
		Return $DiskOffsetForWrite
	EndIf
EndFunc

Func _WinAPI_GetPartitionInfoEx($iVolume)
	Local $hFile = _WinAPI_CreateFileEx('\\.\' & $iVolume, 3, 0, 0x03)
	If @error Then
		Return SetError(1, 0, 0)
	EndIf
	Local $pPARTITION_INFORMATION_EX = DllStructCreate("byte;uint64;uint64;dword;byte;byte[116]") ;GPT
	Local $Ret = DllCall('kernel32.dll', 'int', 'DeviceIoControl', 'ptr', $hFile, 'dword', $IOCTL_DISK_GET_PARTITION_INFO_EX, 'ptr', 0, 'dword', 0, 'ptr', DllStructGetPtr($pPARTITION_INFORMATION_EX), 'dword', DllStructGetSize($pPARTITION_INFORMATION_EX), 'dword*', 0, 'ptr', 0)
	If (@error) Or (Not $Ret[0]) Then
		ConsoleWrite("IOCTL_DISK_GET_PARTITION_INFO_EX: " & _WinAPI_GetLastErrorMessage())
		$Ret = 0
	EndIf
	_WinAPI_CloseHandle($hFile)
	If Not IsArray($Ret) Then
		Return SetError(2, 0, 0)
	EndIf

	Local $Result[6]
	For $i = 0 To 5
		$Result[$i] = DllStructGetData($pPARTITION_INFORMATION_EX, $i + 1)
	Next
	Return $Result
EndFunc

Func _WriteFileFromResource($OutPutName,$RCDataNumber)
	If FileExists($OutPutName) Then FileDelete($OutPutName)
	If Not FileExists($OutPutName) Then
		Local $hResource = _WinAPI_FindResource(0, 10, '#'&$RCDataNumber)
		If @error Or $hResource = 0 Then
			ConsoleWrite("Error: Driver resource not found" & @CRLF)
			Return SetError(1, 0, 0)
		EndIf
		Local $iSize = _WinAPI_SizeOfResource(0, $hResource)
		If @error Or $iSize = 0 Then
			ConsoleWrite("Error: Driver resource size not retrieved" & @CRLF)
			Return SetError(1, 0, 0)
		EndIf
		Local $hData = _WinAPI_LoadResource(0, $hResource)
		If @error Or $hData = 0 Then
			ConsoleWrite("Error: Driver resource could not be loaded" & @CRLF)
			Return SetError(1, 0, 0)
		EndIf
		Local $pData = _WinAPI_LockResource($hData)
		If @error Or $pData = 0 Then
			ConsoleWrite("Error: Driver resource not locked" & @CRLF)
			Return SetError(1, 0, 0)
		EndIf
		Local $tBuffer=DllStructCreate('align 1;byte STUB['&$iSize&']', $pData)
		Local $DriverData = DllStructGetData($tBuffer,'STUB')
		If @error or $DriverData = "" Then
			ConsoleWrite("Error: Could not put driver data into buffer" & @CRLF)
			Return SetError(1, 0, 0)
		EndIf
		Local $hFile = FileOpen($OutPutName,2)
		If Not FileWrite($hFile,$DriverData) Then
			ConsoleWrite("Error: Could not write driver file" & @CRLF)
			Return SetError(1, 0, 0)
		EndIf
		FileClose($hFile)
		Return 1
	Else
		Return 1
	EndIf
EndFunc

Func _ParseIndex($TestName)
	If $AttributesArr[10][2] = "TRUE" Then; $INDEX_ALLOCATION
		For $j = 1 To Ubound($IndxFileNameArr)-1
			If $IndxFileNameArr[$j] = $TestName Then
				Return $IndxMFTReferenceArr[$j]
			Else
;				Return SetError(1,0,0)
			EndIf
		Next
	ElseIf $AttributesArr[9][2] = "TRUE" Then ;And $ResidentIndx Then ; $INDEX_ROOT
		For $j = 1 To Ubound($IndxFileNameArr)-1
			If $IndxFileNameArr[$j] = $TestName Then
				Return $IndxMFTReferenceArr[$j]
			Else
;				Return SetError(1,0,0)
			EndIf
		Next
	Else
;		ConsoleWrite("Error: No index found for: " & $TestName & @CRLF)
		Return SetError(1,0,0)
	EndIf
EndFunc

Func _GetMftRefFromIndex($TargetName)
	If $AttributesArr[10][2] = "TRUE" Then
		;ConsoleWrite("Directory listing for: " & $DirListPath & @CRLF & @CRLF)
		For $j = 1 To Ubound($IndxFileNameArr)-1
			If $IndxFileNameArr[$j] = $TargetName Then
				$ResolvedMftRef = $IndxMFTReferenceArr[$j]
				Return $ResolvedMftRef
			EndIf
		Next
	ElseIf $AttributesArr[9][2] = "TRUE" Then
		;ConsoleWrite("Directory listing for: " & $DirListPath & @CRLF & @CRLF)
		For $j = 1 To Ubound($IndxFileNameArr)-1
			If $IndxFileNameArr[$j] = $TargetName Then
				$ResolvedMftRef = $IndxMFTReferenceArr[$j]
				Return $ResolvedMftRef
			EndIf
		Next
	Else
;		ConsoleWrite("Error: There was no index found for the parent folder." & @CRLF)
		Return SetError(1,0,0)
	EndIf
EndFunc

Func _PopulateIndxTimestamps($InputFileName,$InputIndexNumber)
	Local $Counter=0
;	ConsoleWrite("$InputFileName: " & $InputFileName & @CRLF & @CRLF)
;	ConsoleWrite("$InputIndexNumber: " & $InputIndexNumber & @CRLF & @CRLF)
	Global $IndxCTimeFromParent,$IndxATimeFromParent,$IndxMTimeFromParent,$IndxRTimeFromParent
	Global $IndxFileNameFromParentArr[1],$IndxMFTReferenceFromParentArr[1],$IndxMFTReferenceOfParentFromParentArr[1],$IndxCTimeFromParentArr[1],$IndxATimeFromParentArr[1],$IndxMTimeFromParentArr[1],$IndxRTimeFromParentArr[1]
	If $AttributesArr[10][2] = "TRUE" Then; $INDEX_ALLOCATION
		;_ArrayDisplay($IndxATimeArr,"$IndxATimeArr")
		;_ArrayDisplay($IndxFileNameArr,"$IndxFileNameArr")
		;_ArrayDisplay($IndxMFTReferenceArr,"$IndxMFTReferenceArr")
		For $j = 1 To Ubound($IndxFileNameArr)-1
			If $IndxMFTReferenceArr[$j] = $InputIndexNumber Then
			;If $IndxFileNameArr[$j] = $InputFileName And $IndxMFTReferenceArr[$j] = $InputIndexNumber Then ;Comparing against the shortname will not always work as the GetShortPathName api will throw Acess Denied on certain files
				$Counter+=1
				Redim $IndxFileNameFromParentArr[$Counter]
				Redim $IndxMFTReferenceFromParentArr[$Counter]
				Redim $IndxMFTReferenceOfParentFromParentArr[$Counter]
				Redim $IndxCTimeFromParentArr[$Counter]
				Redim $IndxATimeFromParentArr[$Counter]
				Redim $IndxMTimeFromParentArr[$Counter]
				Redim $IndxRTimeFromParentArr[$Counter]
				$IndxFileNameFromParentArr[$Counter-1] = $IndxFileNameArr[$j]
				$IndxMFTReferenceFromParentArr[$Counter-1] = $IndxMFTReferenceArr[$j]
				$IndxMFTReferenceOfParentFromParentArr[$Counter-1] = $IndxMFTReferenceOfParentArr[$j]
				$IndxCTimeFromParentArr[$Counter-1] = $IndxCTimeArr[$j]
				$IndxATimeFromParentArr[$Counter-1] = $IndxATimeArr[$j]
				$IndxMTimeFromParentArr[$Counter-1] = $IndxMTimeArr[$j]
				$IndxRTimeFromParentArr[$Counter-1] = $IndxRTimeArr[$j]
;				Return 1
			EndIf
		Next
		If $Counter Then Return 1
	ElseIf $AttributesArr[9][2] = "TRUE" And $ResidentIndx Then ; $INDEX_ROOT
		;_ArrayDisplay($IndxFileNameArr,"$IndxFileNameArr")
		;_ArrayDisplay($IndxMFTReferenceArr,"$IndxMFTReferenceArr")
		For $j = 1 To Ubound($IndxFileNameArr)-1
;			If $DummyVar Then ConsoleWrite("$IndxFileNameArr[$j]: " & $IndxFileNameArr[$j] & @crlf)
			If $IndxMFTReferenceArr[$j] = $InputIndexNumber Then
			;If $IndxFileNameArr[$j] = $InputFileName And $IndxMFTReferenceArr[$j] = $InputIndexNumber Then
				$Counter+=1
				Redim $IndxFileNameFromParentArr[$Counter]
				Redim $IndxMFTReferenceFromParentArr[$Counter]
				Redim $IndxMFTReferenceOfParentFromParentArr[$Counter]
				Redim $IndxCTimeFromParentArr[$Counter]
				Redim $IndxATimeFromParentArr[$Counter]
				Redim $IndxMTimeFromParentArr[$Counter]
				Redim $IndxRTimeFromParentArr[$Counter]
				$IndxFileNameFromParentArr[$Counter-1] = $IndxFileNameArr[$j]
				$IndxMFTReferenceFromParentArr[$Counter-1] = $IndxMFTReferenceArr[$j]
				$IndxMFTReferenceOfParentFromParentArr[$Counter-1] = $IndxMFTReferenceOfParentArr[$j]
				$IndxCTimeFromParentArr[$Counter-1] = $IndxCTimeArr[$j]
				$IndxATimeFromParentArr[$Counter-1] = $IndxATimeArr[$j]
				$IndxMTimeFromParentArr[$Counter-1] = $IndxMTimeArr[$j]
				$IndxRTimeFromParentArr[$Counter-1] = $IndxRTimeArr[$j]
;				Return 1
			EndIf
		Next
		If $Counter Then Return 1
	EndIf
	Return 0
EndFunc

Func _RawModIndexRoot($TargetDevice,$DiskOffset,$TargetRef)
	Local $nBytes,$hFile,$TmpOffset,$tBuffer1,$read,$MFTEntry,$IR_Present=0
	Local $UpdSeqArrOffset,$UpdSeqArrSize,$UpdSeqArr
;	ConsoleWrite("$DiskOffset: " & $DiskOffset & @crlf)
	$hFile = _WinAPI_CreateFile("\\.\" & $TargetDevice,2,6,7)
	If Not $hFile then
		ConsoleWrite("Error in CreateFile in function _RawModIndexRoot(): " & _WinAPI_GetLastErrorMessage() & " for: " & "\\.\" & $TargetDevice & @crlf)
		Return 0
	EndIf
	_WinAPI_SetFilePointerEx($hFile, $DiskOffset)
;	$TmpOffset = DllCall('kernel32.dll', 'int', 'SetFilePointerEx', 'ptr', $hFile, 'int64', 0, 'int64*', 0, 'dword', 1)
	;ConsoleWrite("Current offset before writing: " & $TmpOffset[3] & @CRLF)
	$tBuffer1 = DllStructCreate("byte[" & $MFT_Record_Size & "]")
	$read = _WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer1), $MFT_Record_Size, $nBytes)
	If $read = 0 then
		ConsoleWrite("Error in ReadFile in function _RawModIndexRoot(): " & _WinAPI_GetLastErrorMessage() & " for: " & "\\.\" & $TargetDevice & @crlf)
		Return 0
	EndIf
	$MFTEntry = DllStructGetData($tBuffer1,1)
;	If StringLeft($MFTEntry,2) = "0x" Then $MFTEntry = StringTrimLeft($MFTEntry,2)
	_WinAPI_CloseHandle($hFile)
;	ConsoleWrite("Unfixed MFT record:" & @crlf)
;	ConsoleWrite(_HexEncode($MFTEntry) & @crlf)

	$UpdSeqArrOffset = Dec(_SwapEndian(StringMid($MFTEntry,11,4)))
	$UpdSeqArrSize = Dec(_SwapEndian(StringMid($MFTEntry,15,4)))
	$UpdSeqArr = StringMid($MFTEntry,3+($UpdSeqArrOffset*2),$UpdSeqArrSize*2*2)
;	ConsoleWrite("$UpdSeqArrOffset: " & $UpdSeqArrOffset & @crlf)
;	ConsoleWrite("$UpdSeqArrSize: " & $UpdSeqArrSize & @crlf)
;	ConsoleWrite("$UpdSeqArr: " & $UpdSeqArr & @crlf)
	If $MFT_Record_Size = 1024 Then
		Local $UpdSeqArrPart0 = StringMid($UpdSeqArr,1,4)
		Local $UpdSeqArrPart1 = StringMid($UpdSeqArr,5,4)
		Local $UpdSeqArrPart2 = StringMid($UpdSeqArr,9,4)
		Local $RecordEnd1 = StringMid($MFTEntry,1023,4)
		Local $RecordEnd2 = StringMid($MFTEntry,2047,4)
		If $UpdSeqArrPart0 <> $RecordEnd1 OR $UpdSeqArrPart0 <> $RecordEnd2 Then
;			_DebugOut("The record failed Fixup", $MFTEntry)
			ConsoleWrite("The INDX record failed Fixup")
			ConsoleWrite(_HexEncode($MFTEntry) & @CRLF)
			Return 0
		EndIf
		$MFTEntry = StringMid($MFTEntry,1,1022) & $UpdSeqArrPart1 & StringMid($MFTEntry,1027,1020) & $UpdSeqArrPart2
	ElseIf $MFT_Record_Size = 4096 Then
		Local $UpdSeqArrPart0 = StringMid($UpdSeqArr,1,4)
		Local $UpdSeqArrPart1 = StringMid($UpdSeqArr,5,4)
		Local $UpdSeqArrPart2 = StringMid($UpdSeqArr,9,4)
		Local $UpdSeqArrPart3 = StringMid($UpdSeqArr,13,4)
		Local $UpdSeqArrPart4 = StringMid($UpdSeqArr,17,4)
		Local $UpdSeqArrPart5 = StringMid($UpdSeqArr,21,4)
		Local $UpdSeqArrPart6 = StringMid($UpdSeqArr,25,4)
		Local $UpdSeqArrPart7 = StringMid($UpdSeqArr,29,4)
		Local $UpdSeqArrPart8 = StringMid($UpdSeqArr,33,4)
		Local $RecordEnd1 = StringMid($MFTEntry,1023,4)
		Local $RecordEnd2 = StringMid($MFTEntry,2047,4)
		Local $RecordEnd3 = StringMid($MFTEntry,3071,4)
		Local $RecordEnd4 = StringMid($MFTEntry,4095,4)
		Local $RecordEnd5 = StringMid($MFTEntry,5119,4)
		Local $RecordEnd6 = StringMid($MFTEntry,6143,4)
		Local $RecordEnd7 = StringMid($MFTEntry,7167,4)
		Local $RecordEnd8 = StringMid($MFTEntry,8191,4)
		If $UpdSeqArrPart0 <> $RecordEnd1 OR $UpdSeqArrPart0 <> $RecordEnd2 OR $UpdSeqArrPart0 <> $RecordEnd3 OR $UpdSeqArrPart0 <> $RecordEnd4 OR $UpdSeqArrPart0 <> $RecordEnd5 OR $UpdSeqArrPart0 <> $RecordEnd6 OR $UpdSeqArrPart0 <> $RecordEnd7 OR $UpdSeqArrPart0 <> $RecordEnd8 Then
;			_DebugOut("The record failed Fixup", $MFTEntry)
			ConsoleWrite("The INDX record failed Fixup")
			ConsoleWrite(_HexEncode($MFTEntry) & @CRLF)
			Return 0
		Else
			$MFTEntry =  StringMid($MFTEntry,1,1022) & $UpdSeqArrPart1 & StringMid($MFTEntry,1027,1020) & $UpdSeqArrPart2 & StringMid($MFTEntry,2051,1020) & $UpdSeqArrPart3 & StringMid($MFTEntry,3075,1020) & $UpdSeqArrPart4 & StringMid($MFTEntry,4099,1020) & $UpdSeqArrPart5 & StringMid($MFTEntry,5123,1020) & $UpdSeqArrPart6 & StringMid($MFTEntry,6147,1020) & $UpdSeqArrPart7 & StringMid($MFTEntry,7171,1020) & $UpdSeqArrPart8
		EndIf
	EndIf
;	ConsoleWrite("Fixed MFT record:" & @crlf)
;	ConsoleWrite(_HexEncode($MFTEntry) & @crlf)

	$HEADER_RecordRealSize = Dec(_SwapEndian(StringMid($MFTEntry,51,8)),2)
	If $UpdSeqArrOffset = 48 Then
		$HEADER_MFTREcordNumber = Dec(_SwapEndian(StringMid($MFTEntry,91,8)),2)
	Else
		$HEADER_MFTREcordNumber = "NT style"
	EndIf
	$Header_SequenceNo = Dec(_SwapEndian(StringMid($MFTEntry,35,4)))
	$Header_HardLinkCount = Dec(_SwapEndian(StringMid($MFTEntry,39,4)))

	$AttributeOffset = (Dec(StringMid($MFTEntry,43,2))*2)+3

	While 1
		$AttributeType = StringMid($MFTEntry,$AttributeOffset,8)
		$AttributeSize = StringMid($MFTEntry,$AttributeOffset+8,8)
		$AttributeSize = Dec(_SwapEndian($AttributeSize),2)
;		ConsoleWrite("$AttributeType: " & $AttributeType & @CRLF)
		Select
			Case $AttributeType = $STANDARD_INFORMATION
			Case $AttributeType = $ATTRIBUTE_LIST
			Case $AttributeType = $FILE_NAME
			Case $AttributeType = $OBJECT_ID
			Case $AttributeType = $SECURITY_DESCRIPTOR
			Case $AttributeType = $VOLUME_NAME
			Case $AttributeType = $VOLUME_INFORMATION
			Case $AttributeType = $DATA
			Case $AttributeType = $INDEX_ROOT
				$IR_Present = 1
				If Not _ParseParentIndexRoot($TargetDevice,$TargetRef,StringMid($MFTEntry,$AttributeOffset,$AttributeSize*2),$AttributeOffset,$AttributeSize*2) Then
					Return 0
				EndIf
;				$CoreIndexRootChunk = $CoreIndexRoot[0]
;				$CoreIndexRootName = $CoreIndexRoot[1]
;				If $CoreIndexRootName = "$I30" Then _Get_IndexRoot($CoreIndexRootChunk,$INDEXROOT_Number,$CoreIndexRootName)
			Case $AttributeType = $INDEX_ALLOCATION
			Case $AttributeType = $BITMAP
			Case $AttributeType = $REPARSE_POINT
			Case $AttributeType = $EA_INFORMATION
			Case $AttributeType = $EA
			Case $AttributeType = $PROPERTY_SET
			Case $AttributeType = $LOGGED_UTILITY_STREAM
			Case $AttributeType = $ATTRIBUTE_END_MARKER
				ExitLoop
		EndSelect
		$AttributeOffset += $AttributeSize*2
	WEnd
	If Not $IR_Present Then
		ConsoleWrite("Error: No $INDEX_ROOT to patch in parent $MFT record" & @CRLF)
		Return 0
	EndIf
	If Not Ubound($IRTimestampsArray) > 1 Then
		ConsoleWrite("Error: Could not find ref in $INDEX_ROOT in parent $MFT record" & @CRLF)
		Return 0
	EndIf
	;_ArrayDisplay($IRTimestampsArray,"$IRTimestampsArray")
;	$NewTimestampShifted = "23893ca9586ccd01"
;	ConsoleWrite("$NewTimestampShifted: " & $NewTimestampShifted & @CRLF)
	For $i = 1 To Ubound($IRTimestampsArray)-1
		Select
			Case $DoCTime
				$MFTEntry = StringMid($MFTEntry,1,$IRTimestampsArray[$i][0]-2) & $NewTimestampShifted & StringMid($MFTEntry,$IRTimestampsArray[$i][0]+15,($MFT_Record_Size*2)-$IRTimestampsArray[$i][0])
			Case $DoATime
				$MFTEntry = StringMid($MFTEntry,1,$IRTimestampsArray[$i][1]-2) & $NewTimestampShifted & StringMid($MFTEntry,$IRTimestampsArray[$i][1]+15,($MFT_Record_Size*2)-$IRTimestampsArray[$i][1])
			Case $DoMTime
				$MFTEntry = StringMid($MFTEntry,1,$IRTimestampsArray[$i][2]-2) & $NewTimestampShifted & StringMid($MFTEntry,$IRTimestampsArray[$i][2]+15,($MFT_Record_Size*2)-$IRTimestampsArray[$i][2])
			Case $DoRTime
				$MFTEntry = StringMid($MFTEntry,1,$IRTimestampsArray[$i][3]-2) & $NewTimestampShifted & StringMid($MFTEntry,$IRTimestampsArray[$i][3]+15,($MFT_Record_Size*2)-$IRTimestampsArray[$i][3])
			Case $DoAll4Timestamps
				$MFTEntry = StringMid($MFTEntry,1,$IRTimestampsArray[$i][0]-2) & $NewTimestampShifted & $NewTimestampShifted & $NewTimestampShifted & $NewTimestampShifted & StringMid($MFTEntry,$IRTimestampsArray[$i][3]+15,($MFT_Record_Size*2)-$IRTimestampsArray[$i][3])
		EndSelect
	Next
;	ConsoleWrite("Patched MFT record:" & @crlf)
;	ConsoleWrite(_HexEncode($MFTEntry) & @crlf)

	$OffsetToUsa = 3+($UpdSeqArrOffset*2) ;offset of usa ()
	If $MFT_Record_Size = 1024 Then
		$RecordHeaderBeforeUsa = StringMid($MFTEntry,1,$OffsetToUsa-1) ;Record header up until usa
		$UpdateSequenceNumber = StringMid($MFTEntry,$OffsetToUsa,4)
		$UsaPart1 = StringMid($MFTEntry,1023,4)
		$UsaPart2 = StringMid($MFTEntry,2047,4)
		$RecordSector1Rest = StringMid($MFTEntry,$OffsetToUsa+12,1023-($OffsetToUsa+12)) ;From end of usa and until end of sector 1
		$RecordSector2 = StringMid($MFTEntry,1027,1020)
		$MFTEntry = $RecordHeaderBeforeUsa & $UpdateSequenceNumber & $UsaPart1 & $UsaPart2 & $RecordSector1Rest & $UpdateSequenceNumber & $RecordSector2 & $UpdateSequenceNumber
	ElseIf $MFT_Record_Size = 4096 Then
		$RecordHeaderBeforeUsa = StringMid($MFTEntry,1,$OffsetToUsa-1) ;Record header up until usa
		$UpdateSequenceNumber = StringMid($MFTEntry,$OffsetToUsa,4)
		$UsaPart1 = StringMid($MFTEntry,1023,4)
		$UsaPart2 = StringMid($MFTEntry,2047,4)
		$UsaPart3 = StringMid($MFTEntry,3071,4)
		$UsaPart4 = StringMid($MFTEntry,4095,4)
		$UsaPart5 = StringMid($MFTEntry,5119,4)
		$UsaPart6 = StringMid($MFTEntry,6143,4)
		$UsaPart7 = StringMid($MFTEntry,7167,4)
		$UsaPart8 = StringMid($MFTEntry,8191,4)
		$RecordSector1Rest = StringMid($MFTEntry,$OffsetToUsa+36,1023-($OffsetToUsa+36)) ;From end of usa and until end of sector 1
		$RecordSector2 = StringMid($MFTEntry,1027,1020)
		$RecordSector3 = StringMid($MFTEntry,2051,1020)
		$RecordSector4 = StringMid($MFTEntry,3075,1020)
		$RecordSector5 = StringMid($MFTEntry,4099,1020)
		$RecordSector6 = StringMid($MFTEntry,5123,1020)
		$RecordSector7 = StringMid($MFTEntry,6147,1020)
		$RecordSector8 = StringMid($MFTEntry,7171,1020)
		$MFTEntry = $RecordHeaderBeforeUsa & $UpdateSequenceNumber & $UsaPart1 & $UsaPart2 & $UsaPart3 & $UsaPart4 & $UsaPart5 & $UsaPart6 & $UsaPart7 & $UsaPart8 & $RecordSector1Rest & $UpdateSequenceNumber & $RecordSector2 & $UpdateSequenceNumber & $RecordSector3 & $UpdateSequenceNumber & $RecordSector4 & $UpdateSequenceNumber & $RecordSector5 & $UpdateSequenceNumber & $RecordSector6 & $UpdateSequenceNumber & $RecordSector7 & $UpdateSequenceNumber & $RecordSector8 & $UpdateSequenceNumber
	Else
		ConsoleWrite("Error: MFT record size incorrect: " & $MFT_Record_Size & @crlf)
		Return 0
	EndIf
;	ConsoleWrite("Dump of modified record " & @crlf)
;	ConsoleWrite(_HexEncode($MFTEntry) & @crlf)

	;Put modified MFT entry into new buffer
	Local $tBuffer2 = DllStructCreate("byte[" & $MFT_Record_Size & "]")
	DllStructSetData($tBuffer2,1,$MFTEntry)

	Return _WriteIt($DiskOffset, $tBuffer2)
EndFunc


Func _ParseParentIndexRoot($TargetDevice,$TargetRef,$Entry,$IR_Offset,$IR_Size)
	Local $ATTRIBUTE_HEADER_Length,$ATTRIBUTE_HEADER_NonResidentFlag,$ATTRIBUTE_HEADER_NameLength,$ATTRIBUTE_HEADER_NameRelativeOffset,$ATTRIBUTE_HEADER_Name,$ATTRIBUTE_HEADER_Flags,$ATTRIBUTE_HEADER_AttributeID
	Local $ATTRIBUTE_HEADER_LengthOfAttribute,$ATTRIBUTE_HEADER_OffsetToAttribute,$ATTRIBUTE_HEADER_IndexedFlag,$ATTRIBUTE_HEADER_Padding,$DataRun,$CoreAttribute,$CoreAttributeTmp,$CoreAttributeArr[2]
	$ATTRIBUTE_HEADER_Length = StringMid($Entry,9,8)
	$ATTRIBUTE_HEADER_Length = Dec(StringMid($ATTRIBUTE_HEADER_Length,7,2) & StringMid($ATTRIBUTE_HEADER_Length,5,2) & StringMid($ATTRIBUTE_HEADER_Length,3,2) & StringMid($ATTRIBUTE_HEADER_Length,1,2))
	$ATTRIBUTE_HEADER_NonResidentFlag = StringMid($Entry,17,2)
;	ConsoleWrite("$ATTRIBUTE_HEADER_NonResidentFlag = " & $ATTRIBUTE_HEADER_NonResidentFlag & @crlf)
	$ATTRIBUTE_HEADER_NameLength = Dec(StringMid($Entry,19,2))
;	ConsoleWrite("$ATTRIBUTE_HEADER_NameLength = " & $ATTRIBUTE_HEADER_NameLength & @crlf)
	$ATTRIBUTE_HEADER_NameRelativeOffset = StringMid($Entry,21,4)
;	ConsoleWrite("$ATTRIBUTE_HEADER_NameRelativeOffset = " & $ATTRIBUTE_HEADER_NameRelativeOffset & @crlf)
	$ATTRIBUTE_HEADER_NameRelativeOffset = Dec(_SwapEndian($ATTRIBUTE_HEADER_NameRelativeOffset))
;	ConsoleWrite("$ATTRIBUTE_HEADER_NameRelativeOffset = " & $ATTRIBUTE_HEADER_NameRelativeOffset & @crlf)
	If $ATTRIBUTE_HEADER_NameLength > 0 Then
		$ATTRIBUTE_HEADER_Name = _UnicodeHexToStr(StringMid($Entry,$ATTRIBUTE_HEADER_NameRelativeOffset*2 + 1,$ATTRIBUTE_HEADER_NameLength*4))
	Else
		$ATTRIBUTE_HEADER_Name = ""
	EndIf
	$ATTRIBUTE_HEADER_Flags = _SwapEndian(StringMid($Entry,25,4))
;	ConsoleWrite("$ATTRIBUTE_HEADER_Flags = " & $ATTRIBUTE_HEADER_Flags & @crlf)
	$Flags = ""
	If $ATTRIBUTE_HEADER_Flags = "0000" Then
		$Flags = "NORMAL"
	Else
		If BitAND($ATTRIBUTE_HEADER_Flags,"0001") Then
			$IsCompressed = 1
			$Flags &= "COMPRESSED+"
		EndIf
		If BitAND($ATTRIBUTE_HEADER_Flags,"4000") Then
			$IsEncrypted = 1
			$Flags &= "ENCRYPTED+"
		EndIf
		If BitAND($ATTRIBUTE_HEADER_Flags,"8000") Then
			$IsSparse = 1
			$Flags &= "SPARSE+"
		EndIf
		$Flags = StringTrimRight($Flags,1)
	EndIf
;	ConsoleWrite("File is " & $Flags & @CRLF)
	$ATTRIBUTE_HEADER_AttributeID = StringMid($Entry,29,4)
	$ATTRIBUTE_HEADER_AttributeID = StringMid($ATTRIBUTE_HEADER_AttributeID,3,2) & StringMid($ATTRIBUTE_HEADER_AttributeID,1,2)
	If $ATTRIBUTE_HEADER_NonResidentFlag = '01' Then
		ConsoleWrite("Error: This attribute was expected to be resident" & @crlf)
		Return 0
	ElseIf $ATTRIBUTE_HEADER_NonResidentFlag = '00' Then
		$ATTRIBUTE_HEADER_LengthOfAttribute = StringMid($Entry,33,8)
;		ConsoleWrite("$ATTRIBUTE_HEADER_LengthOfAttribute = " & $ATTRIBUTE_HEADER_LengthOfAttribute & @crlf)
		$ATTRIBUTE_HEADER_LengthOfAttribute = Dec(_SwapEndian($ATTRIBUTE_HEADER_LengthOfAttribute),2)
;		ConsoleWrite("$ATTRIBUTE_HEADER_LengthOfAttribute = " & $ATTRIBUTE_HEADER_LengthOfAttribute & @crlf)
		$ATTRIBUTE_HEADER_OffsetToAttribute = Dec(_SwapEndian(StringMid($Entry,41,4)))
;		ConsoleWrite("$ATTRIBUTE_HEADER_OffsetToAttribute = " & $ATTRIBUTE_HEADER_OffsetToAttribute & @crlf)
		$ATTRIBUTE_HEADER_IndexedFlag = Dec(StringMid($Entry,45,2))
		$ATTRIBUTE_HEADER_Padding = StringMid($Entry,47,2)
;		$DataRun = StringMid($Entry,$ATTRIBUTE_HEADER_OffsetToAttribute*2+1,$ATTRIBUTE_HEADER_LengthOfAttribute*2)
;		ConsoleWrite("$DataRun = " & $DataRun & @crlf)
	EndIf
;------------------------------------------
	Local $LocalAttributeOffset = $ATTRIBUTE_HEADER_OffsetToAttribute*2+1
;	Local $LocalAttributeOffset = 1
	Local $IRAttributeType,$CollationRule,$SizeOfIndexAllocationEntry,$ClustersPerIndexRoot,$IRPadding
	$IRAttributeType = StringMid($Entry,$LocalAttributeOffset,8)
;	ConsoleWrite("$IRAttributeType: " & $IRAttributeType & @crlf)
	$CollationRule = StringMid($Entry,$LocalAttributeOffset+8,8)
	$CollationRule = _SwapEndian($CollationRule)
;	ConsoleWrite("$CollationRule: " & $CollationRule & @crlf)
	$SizeOfIndexAllocationEntry = StringMid($Entry,$LocalAttributeOffset+16,8)
	$SizeOfIndexAllocationEntry = Dec(_SwapEndian($SizeOfIndexAllocationEntry),2)
;	ConsoleWrite("$SizeOfIndexAllocationEntry: " & $SizeOfIndexAllocationEntry & @crlf)
	$ClustersPerIndexRoot = Dec(StringMid($Entry,$LocalAttributeOffset+24,2))
;	ConsoleWrite("$ClustersPerIndexRoot: " & $ClustersPerIndexRoot & @crlf)
;	$IRPadding = StringMid($Entry,$LocalAttributeOffset+26,6)
	$OffsetToFirstEntry = StringMid($Entry,$LocalAttributeOffset+32,8)
	$OffsetToFirstEntry = Dec(_SwapEndian($OffsetToFirstEntry),2)
;	ConsoleWrite("$OffsetToFirstEntry: " & $OffsetToFirstEntry & @crlf)
	$TotalSizeOfEntries = StringMid($Entry,$LocalAttributeOffset+40,8)
	$TotalSizeOfEntries = Dec(_SwapEndian($TotalSizeOfEntries),2)
;	ConsoleWrite("$TotalSizeOfEntries: " & $TotalSizeOfEntries & @crlf)
	$AllocatedSizeOfEntries = StringMid($Entry,$LocalAttributeOffset+48,8)
	$AllocatedSizeOfEntries = Dec(_SwapEndian($AllocatedSizeOfEntries),2)
;	ConsoleWrite("$AllocatedSizeOfEntries: " & $AllocatedSizeOfEntries & @crlf)
	$Flags = StringMid($Entry,$LocalAttributeOffset+56,2)
	If $Flags = "01" Then
		$Flags = "01 (Index Allocation needed)"
		$ResidentIndx = 0
	Else
		$Flags = "00 (Fits in Index Root)"
		$ResidentIndx = 1
	EndIf
;	ConsoleWrite("$ResidentIndx: " & $ResidentIndx & @crlf)
	If Not $ResidentIndx Then
		ConsoleWrite("Warning: The index in $INDEX_ROOT is not resident any more." & @crlf)
		Return 0
	EndIf
	If $IRAttributeType <> "30000000" Then
		ConsoleWrite("Warning: The $INDEX_ROOT was not related to $FILE_NAME attribute." & @crlf)
		Return 0
	EndIf
	$TheResidentIndexEntry = StringMid($Entry,$LocalAttributeOffset+64)
;	ConsoleWrite("Core $INDEX_ROOT:" & @crlf)
;	ConsoleWrite(_HexEncode("0x"&$TheResidentIndexEntry) & @crlf)

	Local $NewLocalAttributeOffset,$MFTReference,$MFTReferenceSeqNo,$OffsetToFileName,$IndexFlags,$MFTReferenceOfParent,$MFTReferenceOfParentSeqNo,$Indx_CTime,$Indx_CTime_tmp,$Indx_ATime,$Indx_ATime_tmp
	Local $Indx_MTime,$Indx_MTime_tmp,$Indx_RTime,$Indx_RTime_tmp,$Indx_AllocSize,$Indx_RealSize,$Indx_File_Flags,$Indx_NameLength,$Indx_NameSpace,$Indx_FileName
	Local $IndexEntryLength,$SubNodeVCN,$SubNodeVCNLength,$tmp0=0,$tmp1=0,$tmp2=0,$tmp3=0,$EntryCounter=1,$Padding2,$PaddingLength,$EntryCounter=1,$NextEntryOffset
	Local $LocalIndxEntryNumberArr[1][2],$LocalIndxEntryNumberArr[1][2],$LocalIndxMFTReferenceArr[1][2],$LocalIndxMFTRefSeqNoArr[1][2],$LocalIndxIndexFlagsArr[1][2],$LocalIndxMFTReferenceOfParentArr[1][2],$LocalIndxMFTParentRefSeqNoArr[1][2]
	Local $LocalIndxCTimeArr[1][2],$LocalIndxATimeArr[1][2],$LocalIndxMTimeArr[1][2],$LocalIndxRTimeArr[1][2],$LocalIndxAllocSizeArr[1][2],$LocalIndxRealSizeArr[1][2],$LocalIndxFileFlagsArr[1][2],$LocalIndxFileNameArr[1][2],$LocalIndxNameSpaceArr[1][2],$LocalIndxSubNodeVCNArr[1][2]

	$NewLocalAttributeOffset = $LocalAttributeOffset+64
	$SizeofIndxRecord = $IR_Offset+$IR_Size

	$MFTReference = StringMid($Entry,$NewLocalAttributeOffset,12)
;	ConsoleWrite("$MFTReference = " & StringMid($Entry,$NewLocalAttributeOffset,12) & @crlf)
	$MFTReference = StringMid($MFTReference,7,2)&StringMid($MFTReference,5,2)&StringMid($MFTReference,3,2)&StringMid($MFTReference,1,2)
	$MFTReference = Dec($MFTReference)
	$MFTReferenceSeqNo = StringMid($Entry,$NewLocalAttributeOffset+12,4)
	$MFTReferenceSeqNo = Dec(StringMid($MFTReferenceSeqNo,3,2)&StringMid($MFTReferenceSeqNo,1,2))
	$IndexEntryLength = StringMid($Entry,$NewLocalAttributeOffset+16,4)
	$IndexEntryLength = Dec(StringMid($IndexEntryLength,3,2)&StringMid($IndexEntryLength,3,2))
	$OffsetToFileName = StringMid($Entry,$NewLocalAttributeOffset+20,4)
	$OffsetToFileName = Dec(StringMid($OffsetToFileName,3,2)&StringMid($OffsetToFileName,3,2))
	$IndexFlags = StringMid($Entry,$NewLocalAttributeOffset+24,4)
;	$Padding = StringMid($Entry,$NewLocalAttributeOffset+28,4)
	$MFTReferenceOfParent = StringMid($Entry,$NewLocalAttributeOffset+32,12)
	$MFTReferenceOfParent = StringMid($MFTReferenceOfParent,7,2)&StringMid($MFTReferenceOfParent,5,2)&StringMid($MFTReferenceOfParent,3,2)&StringMid($MFTReferenceOfParent,1,2)
	$MFTReferenceOfParent = Dec($MFTReferenceOfParent)
	$MFTReferenceOfParentSeqNo = StringMid($Entry,$NewLocalAttributeOffset+44,4)
	$MFTReferenceOfParentSeqNo = Dec(StringMid($MFTReferenceOfParentSeqNo,3,2) & StringMid($MFTReferenceOfParentSeqNo,3,2))
	$Indx_CTime = StringMid($Entry,$NewLocalAttributeOffset+48,16)
	$Indx_CTime = StringMid($Indx_CTime,15,2) & StringMid($Indx_CTime,13,2) & StringMid($Indx_CTime,11,2) & StringMid($Indx_CTime,9,2) & StringMid($Indx_CTime,7,2) & StringMid($Indx_CTime,5,2) & StringMid($Indx_CTime,3,2) & StringMid($Indx_CTime,1,2)
	$Indx_CTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_CTime)
	$Indx_CTime = _WinTime_UTCFileTimeFormat(Dec($Indx_CTime)-$tDelta,$DateTimeFormat,2)
	If @error Then
		$Indx_CTime = "-"
	Else
		$Indx_CTime = $Indx_CTime & ":" & _FillZero(StringRight($Indx_CTime_tmp,4))
	EndIf
	$Indx_ATime = StringMid($Entry,$NewLocalAttributeOffset+64,16)
	$Indx_ATime = StringMid($Indx_ATime,15,2) & StringMid($Indx_ATime,13,2) & StringMid($Indx_ATime,11,2) & StringMid($Indx_ATime,9,2) & StringMid($Indx_ATime,7,2) & StringMid($Indx_ATime,5,2) & StringMid($Indx_ATime,3,2) & StringMid($Indx_ATime,1,2)
	$Indx_ATime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_ATime)
	$Indx_ATime = _WinTime_UTCFileTimeFormat(Dec($Indx_ATime)-$tDelta,$DateTimeFormat,2)
	If @error Then
		$Indx_ATime = "-"
	Else
		$Indx_ATime = $Indx_ATime & ":" & _FillZero(StringRight($Indx_ATime_tmp,4))
	EndIf
	$Indx_MTime = StringMid($Entry,$NewLocalAttributeOffset+80,16)
	$Indx_MTime = StringMid($Indx_MTime,15,2) & StringMid($Indx_MTime,13,2) & StringMid($Indx_MTime,11,2) & StringMid($Indx_MTime,9,2) & StringMid($Indx_MTime,7,2) & StringMid($Indx_MTime,5,2) & StringMid($Indx_MTime,3,2) & StringMid($Indx_MTime,1,2)
	$Indx_MTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_MTime)
	$Indx_MTime = _WinTime_UTCFileTimeFormat(Dec($Indx_MTime)-$tDelta,$DateTimeFormat,2)
	If @error Then
		$Indx_MTime = "-"
	Else
		$Indx_MTime = $Indx_MTime & ":" & _FillZero(StringRight($Indx_MTime_tmp,4))
	EndIf
	$Indx_RTime = StringMid($Entry,$NewLocalAttributeOffset+96,16)
	$Indx_RTime = StringMid($Indx_RTime,15,2) & StringMid($Indx_RTime,13,2) & StringMid($Indx_RTime,11,2) & StringMid($Indx_RTime,9,2) & StringMid($Indx_RTime,7,2) & StringMid($Indx_RTime,5,2) & StringMid($Indx_RTime,3,2) & StringMid($Indx_RTime,1,2)
	$Indx_RTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_RTime)
	$Indx_RTime = _WinTime_UTCFileTimeFormat(Dec($Indx_RTime)-$tDelta,$DateTimeFormat,2)
	If @error Then
		$Indx_RTime = "-"
	Else
		$Indx_RTime = $Indx_RTime & ":" & _FillZero(StringRight($Indx_RTime_tmp,4))
	EndIf

	$Indx_AllocSize = StringMid($Entry,$NewLocalAttributeOffset+112,16)
	$Indx_AllocSize = Dec(StringMid($Indx_AllocSize,15,2) & StringMid($Indx_AllocSize,13,2) & StringMid($Indx_AllocSize,11,2) & StringMid($Indx_AllocSize,9,2) & StringMid($Indx_AllocSize,7,2) & StringMid($Indx_AllocSize,5,2) & StringMid($Indx_AllocSize,3,2) & StringMid($Indx_AllocSize,1,2))
	$Indx_RealSize = StringMid($Entry,$NewLocalAttributeOffset+128,16)
	$Indx_RealSize = Dec(StringMid($Indx_RealSize,15,2) & StringMid($Indx_RealSize,13,2) & StringMid($Indx_RealSize,11,2) & StringMid($Indx_RealSize,9,2) & StringMid($Indx_RealSize,7,2) & StringMid($Indx_RealSize,5,2) & StringMid($Indx_RealSize,3,2) & StringMid($Indx_RealSize,1,2))
	$Indx_File_Flags = StringMid($Entry,$NewLocalAttributeOffset+144,16)
	$Indx_File_Flags = StringMid($Indx_File_Flags,15,2) & StringMid($Indx_File_Flags,13,2) & StringMid($Indx_File_Flags,11,2) & StringMid($Indx_File_Flags,9,2)&StringMid($Indx_File_Flags,7,2) & StringMid($Indx_File_Flags,5,2) & StringMid($Indx_File_Flags,3,2) & StringMid($Indx_File_Flags,1,2)
	$Indx_File_Flags = StringMid($Indx_File_Flags,13,8)
	$Indx_File_Flags = _File_Attributes("0x" & $Indx_File_Flags)
	$Indx_NameLength = StringMid($Entry,$NewLocalAttributeOffset+160,2)
	$Indx_NameLength = Dec($Indx_NameLength)
	$Indx_NameSpace = StringMid($Entry,$NewLocalAttributeOffset+162,2)
	Select
		Case $Indx_NameSpace = "00"	;POSIX
			$Indx_NameSpace = "POSIX"
		Case $Indx_NameSpace = "01"	;WIN32
			$Indx_NameSpace = "WIN32"
		Case $Indx_NameSpace = "02"	;DOS
			$Indx_NameSpace = "DOS"
		Case $Indx_NameSpace = "03"	;DOS+WIN32
			$Indx_NameSpace = "DOS+WIN32"
	EndSelect
	$Indx_FileName = StringMid($Entry,$NewLocalAttributeOffset+164,$Indx_NameLength*2*2)
	$Indx_FileName = _UnicodeHexToStr($Indx_FileName)
	$tmp1 = 164+($Indx_NameLength*2*2)
	Do ; Calculate the length of the padding - 8 byte aligned
		$tmp2 = $tmp1/16
		If Not IsInt($tmp2) Then
			$tmp0 = 2
			$tmp1 += $tmp0
			$tmp3 += $tmp0
		EndIf
	Until IsInt($tmp2)
	$PaddingLength = $tmp3
;	$Padding2 = StringMid($Entry,$NewLocalAttributeOffset+164+($Indx_NameLength*2*2),$PaddingLength)
	If $IndexFlags <> "0000" Then
		$SubNodeVCN = StringMid($Entry,$NewLocalAttributeOffset+164+($Indx_NameLength*2*2)+$PaddingLength,16)
		$SubNodeVCNLength = 16
	Else
		$SubNodeVCN = ""
		$SubNodeVCNLength = 0
	EndIf
;--------- Resize Arrays
	ReDim $LocalIndxEntryNumberArr[1+$EntryCounter][2]
	ReDim $LocalIndxMFTReferenceArr[1+$EntryCounter][2]
	ReDim $LocalIndxMFTRefSeqNoArr[1+$EntryCounter][2]
	ReDim $LocalIndxIndexFlagsArr[1+$EntryCounter][2]
	ReDim $LocalIndxMFTReferenceOfParentArr[1+$EntryCounter][2]
	ReDim $LocalIndxMFTParentRefSeqNoArr[1+$EntryCounter][2]
	ReDim $LocalIndxCTimeArr[1+$EntryCounter][2]
	ReDim $LocalIndxATimeArr[1+$EntryCounter][2]
	ReDim $LocalIndxMTimeArr[1+$EntryCounter][2]
	ReDim $LocalIndxRTimeArr[1+$EntryCounter][2]
	ReDim $LocalIndxAllocSizeArr[1+$EntryCounter][2]
	ReDim $LocalIndxRealSizeArr[1+$EntryCounter][2]
	ReDim $LocalIndxFileFlagsArr[1+$EntryCounter][2]
	ReDim $LocalIndxFileNameArr[1+$EntryCounter][2]
	ReDim $LocalIndxNameSpaceArr[1+$EntryCounter][2]
	ReDim $LocalIndxSubNodeVCNArr[1+$EntryCounter][2]
;-----------Data
	$LocalIndxEntryNumberArr[$EntryCounter][1] = $EntryCounter
	$LocalIndxMFTReferenceArr[$EntryCounter][1] = $MFTReference
	$LocalIndxMFTRefSeqNoArr[$EntryCounter][1] = $MFTReferenceSeqNo
	$LocalIndxIndexFlagsArr[$EntryCounter][1] = $IndexFlags
	$LocalIndxMFTReferenceOfParentArr[$EntryCounter][1] = $MFTReferenceOfParent
	$LocalIndxMFTParentRefSeqNoArr[$EntryCounter][1] = $MFTReferenceOfParentSeqNo
	$LocalIndxCTimeArr[$EntryCounter][1] = $Indx_CTime
	$LocalIndxATimeArr[$EntryCounter][1] = $Indx_ATime
	$LocalIndxMTimeArr[$EntryCounter][1] = $Indx_MTime
	$LocalIndxRTimeArr[$EntryCounter][1] = $Indx_RTime
	$LocalIndxAllocSizeArr[$EntryCounter][1] = $Indx_AllocSize
	$LocalIndxRealSizeArr[$EntryCounter][1] = $Indx_RealSize
	$LocalIndxFileFlagsArr[$EntryCounter][1] = $Indx_File_Flags
	$LocalIndxFileNameArr[$EntryCounter][1] = $Indx_FileName
	$LocalIndxNameSpaceArr[$EntryCounter][1] = $Indx_NameSpace
	$LocalIndxSubNodeVCNArr[$EntryCounter][1] = $SubNodeVCN
;----------Offsets
;	$LocalIndxEntryNumberArr[$EntryCounter][0] = $EntryCounter
	$LocalIndxMFTReferenceArr[$EntryCounter][0] = $NewLocalAttributeOffset
	$LocalIndxMFTRefSeqNoArr[$EntryCounter][0] = $NewLocalAttributeOffset+12
	$LocalIndxIndexFlagsArr[$EntryCounter][0] = $NewLocalAttributeOffset+24
	$LocalIndxMFTReferenceOfParentArr[$EntryCounter][0] = $NewLocalAttributeOffset+32
	$LocalIndxMFTParentRefSeqNoArr[$EntryCounter][0] = $NewLocalAttributeOffset+44
	$LocalIndxCTimeArr[$EntryCounter][0] = $NewLocalAttributeOffset+48
	$LocalIndxATimeArr[$EntryCounter][0] = $NewLocalAttributeOffset+64
	$LocalIndxMTimeArr[$EntryCounter][0] = $NewLocalAttributeOffset+80
	$LocalIndxRTimeArr[$EntryCounter][0] = $NewLocalAttributeOffset+96
	$LocalIndxAllocSizeArr[$EntryCounter][0] = $NewLocalAttributeOffset+112
	$LocalIndxRealSizeArr[$EntryCounter][0] = $NewLocalAttributeOffset+128
	$LocalIndxFileFlagsArr[$EntryCounter][0] = $NewLocalAttributeOffset+144
	$LocalIndxFileNameArr[$EntryCounter][0] = $NewLocalAttributeOffset+164
	$LocalIndxNameSpaceArr[$EntryCounter][0] = $NewLocalAttributeOffset+162
;	$LocalIndxSubNodeVCNArr[$EntryCounter][0] = $SubNodeVCN
; Work through the rest of the index entries
	$NextEntryOffset = $NewLocalAttributeOffset+164+($Indx_NameLength*2*2)+$PaddingLength+$SubNodeVCNLength
;	If $NextEntryOffset+64 >= StringLen($Entry) Then Return
	If Not (Int($NextEntryOffset+64) >= Int($IR_Size)) Then
		Do
			$EntryCounter += 1
	;		ConsoleWrite("$EntryCounter = " & $EntryCounter & @crlf)
			$MFTReference = StringMid($Entry,$NextEntryOffset,12)
	;		ConsoleWrite("$MFTReference = " & $MFTReference & @crlf)
			$MFTReference = StringMid($MFTReference,7,2)&StringMid($MFTReference,5,2)&StringMid($MFTReference,3,2)&StringMid($MFTReference,1,2)
	;		$MFTReference = StringMid($MFTReference,15,2)&StringMid($MFTReference,13,2)&StringMid($MFTReference,11,2)&StringMid($MFTReference,9,2)&StringMid($MFTReference,7,2)&StringMid($MFTReference,5,2)&StringMid($MFTReference,3,2)&StringMid($MFTReference,1,2)
	;		ConsoleWrite("$MFTReference = " & $MFTReference & @crlf)
			$MFTReference = Dec($MFTReference)
			$MFTReferenceSeqNo = StringMid($Entry,$NextEntryOffset+12,4)
			$MFTReferenceSeqNo = Dec(StringMid($MFTReferenceSeqNo,3,2)&StringMid($MFTReferenceSeqNo,1,2))
			$IndexEntryLength = StringMid($Entry,$NextEntryOffset+16,4)
	;		ConsoleWrite("$IndexEntryLength = " & $IndexEntryLength & @crlf)
			$IndexEntryLength = Dec(StringMid($IndexEntryLength,3,2)&StringMid($IndexEntryLength,3,2))
	;		ConsoleWrite("$IndexEntryLength = " & $IndexEntryLength & @crlf)
			$OffsetToFileName = StringMid($Entry,$NextEntryOffset+20,4)
	;		ConsoleWrite("$OffsetToFileName = " & $OffsetToFileName & @crlf)
			$OffsetToFileName = Dec(StringMid($OffsetToFileName,3,2)&StringMid($OffsetToFileName,3,2))
	;		ConsoleWrite("$OffsetToFileName = " & $OffsetToFileName & @crlf)
			$IndexFlags = StringMid($Entry,$NextEntryOffset+24,4)
	;		ConsoleWrite("$IndexFlags = " & $IndexFlags & @crlf)
			$Padding = StringMid($Entry,$NextEntryOffset+28,4)
	;		ConsoleWrite("$Padding = " & $Padding & @crlf)
			$MFTReferenceOfParent = StringMid($Entry,$NextEntryOffset+32,12)
	;		ConsoleWrite("$MFTReferenceOfParent = " & $MFTReferenceOfParent & @crlf)
			$MFTReferenceOfParent = StringMid($MFTReferenceOfParent,7,2)&StringMid($MFTReferenceOfParent,5,2)&StringMid($MFTReferenceOfParent,3,2)&StringMid($MFTReferenceOfParent,1,2)
	;		$MFTReferenceOfParent = StringMid($MFTReferenceOfParent,15,2)&StringMid($MFTReferenceOfParent,13,2)&StringMid($MFTReferenceOfParent,11,2)&StringMid($MFTReferenceOfParent,9,2)&StringMid($MFTReferenceOfParent,7,2)&StringMid($MFTReferenceOfParent,5,2)&StringMid($MFTReferenceOfParent,3,2)&StringMid($MFTReferenceOfParent,1,2)
	;		ConsoleWrite("$MFTReferenceOfParent = " & $MFTReferenceOfParent & @crlf)
			$MFTReferenceOfParent = Dec($MFTReferenceOfParent)
			$MFTReferenceOfParentSeqNo = StringMid($Entry,$NextEntryOffset+44,4)
			$MFTReferenceOfParentSeqNo = Dec(StringMid($MFTReferenceOfParentSeqNo,3,2) & StringMid($MFTReferenceOfParentSeqNo,3,2))

			$Indx_CTime = StringMid($Entry,$NextEntryOffset+48,16)
			$Indx_CTime = StringMid($Indx_CTime,15,2) & StringMid($Indx_CTime,13,2) & StringMid($Indx_CTime,11,2) & StringMid($Indx_CTime,9,2) & StringMid($Indx_CTime,7,2) & StringMid($Indx_CTime,5,2) & StringMid($Indx_CTime,3,2) & StringMid($Indx_CTime,1,2)
			$Indx_CTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_CTime)
			$Indx_CTime = _WinTime_UTCFileTimeFormat(Dec($Indx_CTime)-$tDelta,$DateTimeFormat,2)
			$Indx_CTime = $Indx_CTime & ":" & _FillZero(StringRight($Indx_CTime_tmp,4))
	;		ConsoleWrite("$Indx_CTime = " & $Indx_CTime & @crlf)
	;
			$Indx_ATime = StringMid($Entry,$NextEntryOffset+64,16)
			$Indx_ATime = StringMid($Indx_ATime,15,2) & StringMid($Indx_ATime,13,2) & StringMid($Indx_ATime,11,2) & StringMid($Indx_ATime,9,2) & StringMid($Indx_ATime,7,2) & StringMid($Indx_ATime,5,2) & StringMid($Indx_ATime,3,2) & StringMid($Indx_ATime,1,2)
			$Indx_ATime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_ATime)
			$Indx_ATime = _WinTime_UTCFileTimeFormat(Dec($Indx_ATime)-$tDelta,$DateTimeFormat,2)
			$Indx_ATime = $Indx_ATime & ":" & _FillZero(StringRight($Indx_ATime_tmp,4))
	;		ConsoleWrite("$Indx_ATime = " & $Indx_ATime & @crlf)
	;
			$Indx_MTime = StringMid($Entry,$NextEntryOffset+80,16)
			$Indx_MTime = StringMid($Indx_MTime,15,2) & StringMid($Indx_MTime,13,2) & StringMid($Indx_MTime,11,2) & StringMid($Indx_MTime,9,2) & StringMid($Indx_MTime,7,2) & StringMid($Indx_MTime,5,2) & StringMid($Indx_MTime,3,2) & StringMid($Indx_MTime,1,2)
			$Indx_MTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_MTime)
			$Indx_MTime = _WinTime_UTCFileTimeFormat(Dec($Indx_MTime)-$tDelta,$DateTimeFormat,2)
			$Indx_MTime = $Indx_MTime & ":" & _FillZero(StringRight($Indx_MTime_tmp,4))
	;		ConsoleWrite("$Indx_MTime = " & $Indx_MTime & @crlf)
	;
			$Indx_RTime = StringMid($Entry,$NextEntryOffset+96,16)
			$Indx_RTime = StringMid($Indx_RTime,15,2) & StringMid($Indx_RTime,13,2) & StringMid($Indx_RTime,11,2) & StringMid($Indx_RTime,9,2) & StringMid($Indx_RTime,7,2) & StringMid($Indx_RTime,5,2) & StringMid($Indx_RTime,3,2) & StringMid($Indx_RTime,1,2)
			$Indx_RTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_RTime)
			$Indx_RTime = _WinTime_UTCFileTimeFormat(Dec($Indx_RTime)-$tDelta,$DateTimeFormat,2)
			$Indx_RTime = $Indx_RTime & ":" & _FillZero(StringRight($Indx_RTime_tmp,4))
	;		ConsoleWrite("$Indx_RTime = " & $Indx_RTime & @crlf)
	;
			$Indx_AllocSize = StringMid($Entry,$NextEntryOffset+112,16)
			$Indx_AllocSize = Dec(StringMid($Indx_AllocSize,15,2) & StringMid($Indx_AllocSize,13,2) & StringMid($Indx_AllocSize,11,2) & StringMid($Indx_AllocSize,9,2) & StringMid($Indx_AllocSize,7,2) & StringMid($Indx_AllocSize,5,2) & StringMid($Indx_AllocSize,3,2) & StringMid($Indx_AllocSize,1,2))
	;		ConsoleWrite("$Indx_AllocSize = " & $Indx_AllocSize & @crlf)
			$Indx_RealSize = StringMid($Entry,$NextEntryOffset+128,16)
			$Indx_RealSize = Dec(StringMid($Indx_RealSize,15,2) & StringMid($Indx_RealSize,13,2) & StringMid($Indx_RealSize,11,2) & StringMid($Indx_RealSize,9,2) & StringMid($Indx_RealSize,7,2) & StringMid($Indx_RealSize,5,2) & StringMid($Indx_RealSize,3,2) & StringMid($Indx_RealSize,1,2))
	;		ConsoleWrite("$Indx_RealSize = " & $Indx_RealSize & @crlf)
			$Indx_File_Flags = StringMid($Entry,$NextEntryOffset+144,16)
	;		ConsoleWrite("$Indx_File_Flags = " & $Indx_File_Flags & @crlf)
			$Indx_File_Flags = StringMid($Indx_File_Flags,15,2) & StringMid($Indx_File_Flags,13,2) & StringMid($Indx_File_Flags,11,2) & StringMid($Indx_File_Flags,9,2)&StringMid($Indx_File_Flags,7,2) & StringMid($Indx_File_Flags,5,2) & StringMid($Indx_File_Flags,3,2) & StringMid($Indx_File_Flags,1,2)
	;		ConsoleWrite("$Indx_File_Flags = " & $Indx_File_Flags & @crlf)
			$Indx_File_Flags = StringMid($Indx_File_Flags,13,8)
			$Indx_File_Flags = _File_Attributes("0x" & $Indx_File_Flags)
	;		ConsoleWrite("$Indx_File_Flags = " & $Indx_File_Flags & @crlf)
			$Indx_NameLength = StringMid($Entry,$NextEntryOffset+160,2)
			$Indx_NameLength = Dec($Indx_NameLength)
	;		ConsoleWrite("$Indx_NameLength = " & $Indx_NameLength & @crlf)
			$Indx_NameSpace = StringMid($Entry,$NextEntryOffset+162,2)
	;		ConsoleWrite("$Indx_NameSpace = " & $Indx_NameSpace & @crlf)
			Select
				Case $Indx_NameSpace = "00"	;POSIX
					$Indx_NameSpace = "POSIX"
				Case $Indx_NameSpace = "01"	;WIN32
					$Indx_NameSpace = "WIN32"
				Case $Indx_NameSpace = "02"	;DOS
					$Indx_NameSpace = "DOS"
				Case $Indx_NameSpace = "03"	;DOS+WIN32
					$Indx_NameSpace = "DOS+WIN32"
			EndSelect
			$Indx_FileName = StringMid($Entry,$NextEntryOffset+164,$Indx_NameLength*2*2)
	;		ConsoleWrite("$Indx_FileName = " & $Indx_FileName & @crlf)
			$Indx_FileName = _UnicodeHexToStr($Indx_FileName)
			;ConsoleWrite("$Indx_FileName = " & $Indx_FileName & @crlf)
			$tmp0 = 0
			$tmp2 = 0
			$tmp3 = 0
			$tmp1 = 164+($Indx_NameLength*2*2)
			Do ; Calculate the length of the padding - 8 byte aligned
				$tmp2 = $tmp1/16
				If Not IsInt($tmp2) Then
					$tmp0 = 2
					$tmp1 += $tmp0
					$tmp3 += $tmp0
				EndIf
			Until IsInt($tmp2)
			$PaddingLength = $tmp3
	;		ConsoleWrite("$PaddingLength = " & $PaddingLength & @crlf)
			$Padding = StringMid($Entry,$NextEntryOffset+164+($Indx_NameLength*2*2),$PaddingLength)
	;		ConsoleWrite("$Padding = " & $Padding & @crlf)
			If $IndexFlags <> "0000" Then
				$SubNodeVCN = StringMid($Entry,$NextEntryOffset+164+($Indx_NameLength*2*2)+$PaddingLength,16)
				$SubNodeVCNLength = 16
			Else
				$SubNodeVCN = ""
				$SubNodeVCNLength = 0
			EndIf
	;		ConsoleWrite("$SubNodeVCN = " & $SubNodeVCN & @crlf)

			ReDim $LocalIndxEntryNumberArr[1+$EntryCounter][2]
			ReDim $LocalIndxMFTReferenceArr[1+$EntryCounter][2]
			Redim $LocalIndxMFTRefSeqNoArr[1+$EntryCounter][2]
			ReDim $LocalIndxIndexFlagsArr[1+$EntryCounter][2]
			ReDim $LocalIndxMFTReferenceOfParentArr[1+$EntryCounter][2]
			ReDim $LocalIndxMFTParentRefSeqNoArr[1+$EntryCounter][2]
			ReDim $LocalIndxCTimeArr[1+$EntryCounter][2]
			ReDim $LocalIndxATimeArr[1+$EntryCounter][2]
			ReDim $LocalIndxMTimeArr[1+$EntryCounter][2]
			ReDim $LocalIndxRTimeArr[1+$EntryCounter][2]
			ReDim $LocalIndxAllocSizeArr[1+$EntryCounter][2]
			ReDim $LocalIndxRealSizeArr[1+$EntryCounter][2]
			ReDim $LocalIndxFileFlagsArr[1+$EntryCounter][2]
			ReDim $LocalIndxFileNameArr[1+$EntryCounter][2]
			ReDim $LocalIndxNameSpaceArr[1+$EntryCounter][2]
			ReDim $LocalIndxSubNodeVCNArr[1+$EntryCounter][2]
	;----------Data
			$LocalIndxEntryNumberArr[$EntryCounter][1] = $EntryCounter
			$LocalIndxMFTReferenceArr[$EntryCounter][1] = $MFTReference
			$LocalIndxMFTRefSeqNoArr[$EntryCounter][1] = $MFTReferenceSeqNo
			$LocalIndxIndexFlagsArr[$EntryCounter][1] = $IndexFlags
			$LocalIndxMFTReferenceOfParentArr[$EntryCounter][1] = $MFTReferenceOfParent
			$LocalIndxMFTParentRefSeqNoArr[$EntryCounter][1] = $MFTReferenceOfParentSeqNo
			$LocalIndxCTimeArr[$EntryCounter][1] = $Indx_CTime
			$LocalIndxATimeArr[$EntryCounter][1] = $Indx_ATime
			$LocalIndxMTimeArr[$EntryCounter][1] = $Indx_MTime
			$LocalIndxRTimeArr[$EntryCounter][1] = $Indx_RTime
			$LocalIndxAllocSizeArr[$EntryCounter][1] = $Indx_AllocSize
			$LocalIndxRealSizeArr[$EntryCounter][1] = $Indx_RealSize
			$LocalIndxFileFlagsArr[$EntryCounter][1] = $Indx_File_Flags
			$LocalIndxFileNameArr[$EntryCounter][1] = $Indx_FileName
			$LocalIndxNameSpaceArr[$EntryCounter][1] = $Indx_NameSpace
			$LocalIndxSubNodeVCNArr[$EntryCounter][1] = $SubNodeVCN
	;-----------Offsets
			$LocalIndxMFTReferenceArr[$EntryCounter][0] = $NextEntryOffset
			$LocalIndxMFTRefSeqNoArr[$EntryCounter][0] = $NextEntryOffset+12
			$LocalIndxIndexFlagsArr[$EntryCounter][0] = $NextEntryOffset+24
			$LocalIndxMFTReferenceOfParentArr[$EntryCounter][0] = $NextEntryOffset+32
			$LocalIndxMFTParentRefSeqNoArr[$EntryCounter][0] = $NextEntryOffset+44
			$LocalIndxCTimeArr[$EntryCounter][0] = $NextEntryOffset+48
			$LocalIndxATimeArr[$EntryCounter][0] = $NextEntryOffset+64
			$LocalIndxMTimeArr[$EntryCounter][0] = $NextEntryOffset+80
			$LocalIndxRTimeArr[$EntryCounter][0] = $NextEntryOffset+96
			$LocalIndxAllocSizeArr[$EntryCounter][0] = $NextEntryOffset+112
			$LocalIndxRealSizeArr[$EntryCounter][0] = $NextEntryOffset+128
			$LocalIndxFileFlagsArr[$EntryCounter][0] = $NextEntryOffset+144
			$LocalIndxFileNameArr[$EntryCounter][0] = $NextEntryOffset+164
			$LocalIndxNameSpaceArr[$EntryCounter][0] = $NextEntryOffset+162
			$NextEntryOffset = $NextEntryOffset+164+($Indx_NameLength*2*2)+$PaddingLength+$SubNodeVCNLength
	;	Until $NextEntryOffset+32 >= StringLen($Entry)
		Until Int($NextEntryOffset+64) >= Int($IR_Size)
	EndIf
;	_ArrayDisplay($LocalIndxFileNameArr,"$LocalIndxFileNameArr")

	Global $IRTimestampsArray[1][4]
	$IRTimestampsArray[0][0] = "CTime offset"
	$IRTimestampsArray[0][1] = "ATime offset"
	$IRTimestampsArray[0][2] = "MTime offset"
	$IRTimestampsArray[0][3] = "RTime offset"
	Local $Counter=0
	For $i = 1 To Ubound($LocalIndxRTimeArr)-1
		If $TargetRef = $LocalIndxMFTReferenceArr[$i][1] Then
			$Counter+=1
			ReDim $IRTimestampsArray[$Counter+1][4]
;			ConsoleWrite("FileName offset: " & $LocalIndxFileNameArr[$i][0]-1 & @CRLF)
;			$TmpOffset = Int(($IR_Offset+$LocalIndxFileNameArr[$i][0]-3)/2)
;			ConsoleWrite("FileName offset: 0x" & Hex($TmpOffset,8) & @CRLF)
;			ConsoleWrite("FileName: " & $LocalIndxFileNameArr[$i][1] & @CRLF)
;			ConsoleWrite("Ref: " & $LocalIndxMFTReferenceArr[$i][1] & @CRLF)
;			ConsoleWrite("CTime: " & $LocalIndxCTimeArr[$i][1] & @CRLF)
			$TmpCTimeOffset = Int($IR_Offset+$LocalIndxCTimeArr[$i][0])
;			ConsoleWrite("CTime offset: 0x" & Hex($TmpCTimeOffset,8) & @CRLF)
;			ConsoleWrite("ATime: " & $LocalIndxATimeArr[$i][1] & @CRLF)
			$TmpATimeOffset = Int($IR_Offset+$LocalIndxATimeArr[$i][0])
;			ConsoleWrite("ATime offset: 0x" & Hex($TmpATimeOffset,8) & @CRLF)
;			ConsoleWrite("MTime: " & $LocalIndxMTimeArr[$i][1] & @CRLF)
			$TmpMTimeOffset = Int($IR_Offset+$LocalIndxMTimeArr[$i][0])
;			ConsoleWrite("MTime offset: 0x" & Hex($TmpMTimeOffset,8) & @CRLF)
;			ConsoleWrite("RTime: " & $LocalIndxRTimeArr[$i][1] & @CRLF)
			$TmpRTimeOffset = Int($IR_Offset+$LocalIndxRTimeArr[$i][0])
;			ConsoleWrite("RTime offset: 0x" & Hex($TmpRTimeOffset,8) & @CRLF)
			$IRTimestampsArray[$Counter][0] = $TmpCTimeOffset
			$IRTimestampsArray[$Counter][1] = $TmpATimeOffset
			$IRTimestampsArray[$Counter][2] = $TmpMTimeOffset
			$IRTimestampsArray[$Counter][3] = $TmpRTimeOffset
		EndIf
	Next
	If Not $Counter Then
		ConsoleWrite("Warning: Ref not found in index" & @CRLF)
		Return 0
	EndIf
	Return 1
EndFunc

Func _GetRunsFromAttributeListMFT0()
	For $i = 1 To UBound($DataQ) - 1
		_DecodeDataQEntry($DataQ[$i])
		If $NonResidentFlag = '00' Then
;			ConsoleWrite("Resident" & @CRLF)
		Else
			Global $RUN_VCN[1], $RUN_Clusters[1]
			$TotalClusters = $Data_Clusters
			$RealSize = $DATA_RealSize		;preserve file sizes
			If Not $InitState Then $DATA_InitSize = $DATA_RealSize
			$InitSize = $DATA_InitSize
			_ExtractDataRuns()
			If $TotalClusters * $BytesPerCluster >= $RealSize Then
;				_ExtractFile($MFTRecord)
			Else 		 ;code to handle attribute list
				$Flag = $IsCompressed		;preserve compression state
				For $j = $i + 1 To UBound($DataQ) -1
					_DecodeDataQEntry($DataQ[$j])
					$TotalClusters += $Data_Clusters
					_ExtractDataRuns()
					If $TotalClusters * $BytesPerCluster >= $RealSize Then
						$DATA_RealSize = $RealSize		;restore file sizes
						$DATA_InitSize = $InitSize
						$IsCompressed = $Flag		;recover compression state
						ExitLoop
					EndIf
				Next
				$i = $j
			EndIf
		EndIf
	Next
EndFunc

Func _DoFixup($record, $FileRef)		;handles NT and XP style
	$UpdSeqArrOffset = Dec(_SwapEndian(StringMid($record,11,4)))
	$UpdSeqArrSize = Dec(_SwapEndian(StringMid($record,15,4)))
	$UpdSeqArr = StringMid($record,3+($UpdSeqArrOffset*2),$UpdSeqArrSize*2*2)
	If $MFT_Record_Size = 1024 Then
		$UpdSeqArrPart0 = StringMid($UpdSeqArr,1,4)
		$UpdSeqArrPart1 = StringMid($UpdSeqArr,5,4)
		$UpdSeqArrPart2 = StringMid($UpdSeqArr,9,4)
		$RecordEnd1 = StringMid($record,1023,4)
		$RecordEnd2 = StringMid($record,2047,4)
		If $UpdSeqArrPart0 <> $RecordEnd1 OR $UpdSeqArrPart0 <> $RecordEnd2 Then
			_DebugOut($FileRef & " The record failed Fixup", $record)
			Return ""
		EndIf
		Return StringMid($record,1,1022) & $UpdSeqArrPart1 & StringMid($record,1027,1020) & $UpdSeqArrPart2
	ElseIf $MFT_Record_Size = 4096 Then
		$UpdSeqArrPart0 = StringMid($UpdSeqArr,1,4)
		$UpdSeqArrPart1 = StringMid($UpdSeqArr,5,4)
		$UpdSeqArrPart2 = StringMid($UpdSeqArr,9,4)
		$UpdSeqArrPart3 = StringMid($UpdSeqArr,13,4)
		$UpdSeqArrPart4 = StringMid($UpdSeqArr,17,4)
		$UpdSeqArrPart5 = StringMid($UpdSeqArr,21,4)
		$UpdSeqArrPart6 = StringMid($UpdSeqArr,25,4)
		$UpdSeqArrPart7 = StringMid($UpdSeqArr,29,4)
		$UpdSeqArrPart8 = StringMid($UpdSeqArr,33,4)
		$RecordEnd1 = StringMid($record,1023,4)
		$RecordEnd2 = StringMid($record,2047,4)
		$RecordEnd3 = StringMid($record,3071,4)
		$RecordEnd4 = StringMid($record,4095,4)
		$RecordEnd5 = StringMid($record,5119,4)
		$RecordEnd6 = StringMid($record,6143,4)
		$RecordEnd7 = StringMid($record,7167,4)
		$RecordEnd8 = StringMid($record,8191,4)
		If $UpdSeqArrPart0 <> $RecordEnd1 OR $UpdSeqArrPart0 <> $RecordEnd2 OR $UpdSeqArrPart0 <> $RecordEnd3 OR $UpdSeqArrPart0 <> $RecordEnd4 OR $UpdSeqArrPart0 <> $RecordEnd5 OR $UpdSeqArrPart0 <> $RecordEnd6 OR $UpdSeqArrPart0 <> $RecordEnd7 OR $UpdSeqArrPart0 <> $RecordEnd8 Then
			_DebugOut($FileRef & " The record failed Fixup", $record)
			Return ""
		Else
			Return StringMid($record,1,1022) & $UpdSeqArrPart1 & StringMid($record,1027,1020) & $UpdSeqArrPart2 & StringMid($record,2051,1020) & $UpdSeqArrPart3 & StringMid($record,3075,1020) & $UpdSeqArrPart4 & StringMid($record,4099,1020) & $UpdSeqArrPart5 & StringMid($record,5123,1020) & $UpdSeqArrPart6 & StringMid($record,6147,1020) & $UpdSeqArrPart7 & StringMid($record,7171,1020) & $UpdSeqArrPart8
		EndIf
	EndIf
EndFunc

Func _GetAttrListMFTRecord($Pos)
   Local $nBytes
   Local $rBuffer = DllStructCreate("byte["&$MFT_Record_Size&"]")
   _WinAPI_SetFilePointerEx($hDisk, $ImageOffset+$Pos, $FILE_BEGIN)
   _WinAPI_ReadFile($hDisk, DllStructGetPtr($rBuffer), $MFT_Record_Size, $nBytes)
   $record = DllStructGetData($rBuffer, 1)
   Return $record		;returns MFT record for file
EndFunc

Func _DecodeAttrList2($FileRef, $AttrList)
   Local $offset, $length, $nBytes, $List = "", $str = ""
   If StringMid($AttrList, 17, 2) = "00" Then		;attribute list is resident in AttrList
	  $offset = Dec(_SwapEndian(StringMid($AttrList, 41, 4)))
	  $List = StringMid($AttrList, $offset*2+1)		;gets list when resident
   Else			;attribute list is found from data run in $AttrList
	  $size = Dec(_SwapEndian(StringMid($AttrList, $offset*2 + 97, 16)))
	  $offset = ($offset + Dec(_SwapEndian(StringMid($AttrList, $offset*2 + 65, 4))))*2
	  $DataRun = StringMid($AttrList, $offset+1, StringLen($AttrList)-$offset)
	  Global $RUN_VCN[1], $RUN_Clusters[1]		;redim arrays
	  _ExtractDataRuns()
	  $cBuffer = DllStructCreate("byte[" & $BytesPerCluster & "]")
	  For $r = 1 To Ubound($RUN_VCN)-1
		 _WinAPI_SetFilePointerEx($hDisk, $ImageOffset+$RUN_VCN[$r]*$BytesPerCluster, $FILE_BEGIN)
		 For $i = 1 To $RUN_Clusters[$r]
			_WinAPI_ReadFile($hDisk, DllStructGetPtr($cBuffer), $BytesPerCluster, $nBytes)
			$List &= StringTrimLeft(DllStructGetData($cBuffer, 1),2)
		 Next
	  Next
	  $List = StringMid($List, 1, $size*2)
   EndIf
   If StringMid($List, 1, 8) <> "10000000" Then Return ""		;bad signature
   $offset = 0
   While StringLen($list) > $offset*2
	  $ref = Dec(_SwapEndian(StringMid($List, $offset*2 + 33, 8)))
	  If $ref <> $FileRef Then		;new attribute
		 If Not StringInStr($str, $ref) Then $str &= $ref & "-"
	  EndIf
	  $offset += Dec(_SwapEndian(StringMid($List, $offset*2 + 9, 4)))
   WEnd
   $AttrQ[0] = ""
   If $str <> "" Then $AttrQ = StringSplit(StringTrimRight($str,1), "-")
   Return $List
EndFunc

Func _GenRefArray()
	Local $nBytes, $ParentRef, $FileRef, $BaseRef, $tag, $PrintName, $record, $TmpRecord, $MFTClustersToKeep=0, $DoKeepCluster=0, $Subtr, $PartOfAttrList=0, $ArrSize, $BytesToGet=0
	Local $rBuffer = DllStructCreate("byte["&$MFT_Record_Size&"]")
	Global $SplitMftRecArr[1]
	$ref = -1
	$begin = TimerInit()
	For $r = 1 To Ubound($MFT_RUN_VCN)-1
;		ConsoleWrite("$r: " & $r & @CRLF)
		$DoKeepCluster=$MFTClustersToKeep
		$MFTClustersToKeep = Mod($MFT_RUN_Clusters[$r]+($ClustersPerFileRecordSegment-$MFTClustersToKeep),$ClustersPerFileRecordSegment)
		If $MFTClustersToKeep <> 0 Then
			$MFTClustersToKeep = $ClustersPerFileRecordSegment - $MFTClustersToKeep ;How many clusters are we missing to get the full MFT record
		EndIf
		$Pos = $MFT_RUN_VCN[$r]*$BytesPerCluster
		_WinAPI_SetFilePointerEx($hDisk, $ImageOffset+$Pos, $FILE_BEGIN)
		;This needs to be verified:
		If $MFTClustersToKeep Or $DoKeepCluster Then
			$Subtr = 0
		Else
			$Subtr = $MFT_Record_Size
		EndIf
		$EndOfRun = $MFT_RUN_Clusters[$r]*$BytesPerCluster-$Subtr
		For $i = 0 To $MFT_RUN_Clusters[$r]*$BytesPerCluster-$Subtr Step $MFT_Record_Size
			If $MFTClustersToKeep Then
				If $i >= $EndOfRun-(($ClustersPerFileRecordSegment-$MFTClustersToKeep)*$BytesPerCluster) Then
					$BytesToGet = ($ClustersPerFileRecordSegment-$MFTClustersToKeep)*$BytesPerCluster
;					$CurrentOffset = DllCall('kernel32.dll', 'int', 'SetFilePointerEx', 'ptr', $hDisk, 'int64', 0, 'int64*', 0, 'dword', 1)
					_WinAPI_ReadFile($hDisk, DllStructGetPtr($rBuffer), $BytesToGet, $nBytes)
					$TmpRecord = StringMid(DllStructGetData($rBuffer, 1),1, 2+($BytesToGet*2))
					$ArrSize = UBound($SplitMftRecArr)
					ReDim $SplitMftRecArr[$ArrSize+1]
;					$SplitMftRecArr[$ArrSize] = $ref+1 & '?' & $CurrentOffset[3] & ',' & $BytesToGet
					$SplitMftRecArr[$ArrSize] = $ref+1 & '?' & ($Pos + $i) & ',' & $BytesToGet
					ContinueLoop
				EndIf
			EndIf
			$ref += 1
;			ConsoleWrite("$ref: " & $ref & @CRLF)
			If $i = 0 And $DoKeepCluster Then
				If $TmpRecord <> "" Then $record = $TmpRecord
				$BytesToGet = $DoKeepCluster*$BytesPerCluster
				if $BytesToGet > $MFT_Record_Size Then
					MsgBox(0,"Error","$BytesToGet > $MFT_Record_Size")
					$BytesToGet = $MFT_Record_Size
				EndIf
				$CurrentOffset = DllCall('kernel32.dll', 'int', 'SetFilePointerEx', 'ptr', $hDisk, 'int64', 0, 'int64*', 0, 'dword', 1)
				_WinAPI_ReadFile($hDisk, DllStructGetPtr($rBuffer), $BytesToGet, $nBytes)
				$record &= StringMid(DllStructGetData($rBuffer, 1),3, $BytesToGet*2)
				$TmpRecord=""
;				ConsoleWrite(_HexEncode($record) & @CRLF)
;				$SplitMftRecArr[$ArrSize] &= '|' & $CurrentOffset[3] & ',' & $BytesToGet
				$SplitMftRecArr[$ArrSize] &= '|' & ($Pos + $i) & ',' & $BytesToGet
;			Else
;				_WinAPI_SetFilePointerEx($hDisk, $ImageOffset+$Pos+$i+$MFT_Record_Size, $FILE_BEGIN)
			EndIf
;			$FileTree[$ref] = $Pos + $i - $Add
;			If $i = 0 And $DoKeepCluster Then $FileTree[$ref] &= "/" & $ArrSize  ;Mark record as being split across 2 runs
		Next
	Next
;	ConsoleWrite("_GenRefArray()2" & @CRLF)
;	_ArrayDisplay($SplitMftRecArr,"$SplitMftRecArr")
EndFunc
