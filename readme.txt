This is a filesystem timestamp manipulation tool, originally inspired by good old timestomp. This version is NTFS only, and both $STANDARD_INFORMATION and $FILE_NAME attributes are supported. In latest version, there is no longer any dependency on NtSetInformationFile. That means it is completely based on resolving the filesystem internally and writing the timestamps directly to the physical disk, and effectively bypassing anything imposed by the filesystem/OS. Though you need to have adminstrator privileges. In this version there is also support for unlimited $FILE_NAME attributes, but is restricted to what fits inside an MFT record (not spread across $ATTRIBUTE_LISTS). In the previous version only the $FILE_NAME attributes was handled this way, but now also $STANDARD_INFORMATION. However be sure to have read the warning below! The $FILE_NAME attribute can be present twice, giving it 8 possible timestamps. Short filenames have only 1 $FILE_NAME attribute (4 timestamps) whereas files with long filenames have 2 $FILE_NAME attributes (4+4 timestamps). In fact, files with links (for instance hardlinks), may have more than 2 $FILE_NAME attributes!

Parameter explanation;

- Parameter 1 is input/target file. Must be full path like "c:\folder\file.ext"

- Parameter 2 is determining which timestamp to update. 
"-m" = LastWriteTime
"-a" = LastAccessTime
"-c" = CreationTime
"-e" = ChangeTime (in $MFT)
"-z" = all 4
"-d" = Dump existing timestamps (given in UTC 0.00)

- Parameter 3 is the wanted new timestamp. Format must be strictly followed like; "1954:04:01:22:39:44:666:1234". That is YYYY:MM:DD:HH:MM:SS:MSMSMS:NSNSNSNS. The smallest possible value to set is; "1601:01:01:00:00:00:000:0001". Timestamps are written as UTC and thus will show up in explorer as interpreted by your timezone location. If parameter 2 is "-g" then this one should be a valid path+filename. Note that nanoseconds are supported.

- Parameter 4 determines if $STANDARD_INFORMATION or $FILE_NAME attribute or both should be modified. 
"-si" will only update timestamps in $STANDARD_INFORMATION (4 timestamps), or just LastWriteTime, LastAccessTime and CreationTime (3 timestamps) for non-NTFS.
"-fn" will only update timestamps in $FILE_NAME (4 timestamps for short names, 8 timestamps for long names, or more if links are involved), and only for NTFS.
"-x" will update timestamps in both $FILE_NAME and $STANDARD_INFORMATION. 

Note:
Directories are also supported just like regular files. On nt6.x (Vista - Windows 8), it is not easily possible to modify timestamps on the systemdrive (or a volume where a pagefile exist) when the host OS is running (unless you implement a kernel mode driver that can give you a "SL_FORCE_DIRECT_WRITE". However booting to WinPE (CD, USB, PXE etc) will let this tool write directly to the volume that the local system (systemdrive) is on. This restriction is only applicable to this tool on nt6.x and the systemdrive when host is running. Also beware that on nt6.x target volume will be automatically locked/dismounted prior physical disk writing, so be sure no heavy filesystem activity is going on on that volume when using this tool. And for nt6.x, since the volume is locked/dismounted, SetMace itself can't be located on the same volume as the target file for timestamp manipulation.

Dumping information with the -d switch
From version 1.0.0.9 the -d switch will also dump timestamp information from the target volume, as well as from present any shadow copies of that volume. So if the volume that the target file resides on, also have shadow copies, the -d switch will also dump information for the same MFT reference for every relevant shadow copy. Matching shadow copies are identified by the volume name and serial number. The dumped information includes filename, parent ref, sequence number and hardlink number to help identify if the same file actually holds a particular MFT ref across shadow copies.

Warning:
Bypassing the filesystem and writing to physical disk is by nature a risky operation. And it's success is totally dependent on me/SetMace having resolved NTFS correctly. Having said that, I have tested this new version on both XP sp3 x86 and Windows 7 x86/x64, on which it works fine. This new method of timestamp manipulation is a whole lot harder to detect. In fact, I can't think of any method, except the presence of this tool. The earlier version with the move-trick and/or NtSetInformationFile would leave traces in the $LogFile. That's no longer a concern with latest version. I will still call this new version experimental, so please do not test on any volume you are afraid of loosing data from. If you want to test it for me, please let me know.

Examples;

Setting the CreationTime in the $STANDARD_INFORMATION attribute:
setmace.exe C:\file.txt -c "2000:01:01:00:00:00:789:1234" -si

Setting the LastAccessTime in the $STANDARD_INFORMATION attribute:
setmace.exe C:\file.txt -a "2000:01:01:00:00:00:789:1234" -si

Setting the LastWriteTime in the $FILE_NAME attribute:
setmace.exe C:\file.txt -m "2000:01:01:00:00:00:789:1234" -fn

Setting the ChangeTime(MFT) in the $FILE_NAME attribute:
setmace.exe C:\file.txt -e "2000:01:01:00:00:00:789:1234" -fn

setting all 4+4 timestamps in the $FILE_NAME attribute for a file with long filename:
setmace.exe "C:\a long filename.txt" -z "2000:01:01:00:00:00:789:1234" -fn

setting 1+1 timestamps ($MFT creation time * 2) in the $FILE_NAME attribute for a file with long filename:
setmace.exe "C:\a long filename.txt" -e "2000:01:01:00:00:00:789:1234" -fn

Setting all 4+4 (or 4+8) timestamps in both $STANDARD_INFORMATION and $FILE_NAME attributes:
setmace.exe C:\file.txt -z "2000:01:01:00:00:00:789:1234" -x

Setting the LastWriteTime in both $STANDARD_INFORMATION and $FILE_NAME attribute of root directory (defined by index number):
setmace.exe C:5 -m "2000:01:01:00:00:00:789:1234" -x

Dumping all timestamps for $MFT itself:
setmace.exe C:\$MFT -d
or
setmace.exe C:0 -d




Thanks:
Ascend4nt for the WinTimeFunctions
DDan at forensicfocus for various help





