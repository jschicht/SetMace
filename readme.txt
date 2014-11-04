This is an advanced filesystem timestamp manipulation tool, originally inspired by good old timestomp. This version is NTFS only, and attributes supported for timestamp manipulation are $STANDARD_INFORMATION, $FILE_NAME, $INDEX_ROOT, and $INDEX_ALLOCATION. In latest version, there is no longer any dependency on NtSetInformationFile. That means it is completely based on resolving the filesystem internally and writing the timestamps directly to the physical disk, and effectively bypassing anything imposed by the filesystem/OS. Though you need to have adminstrator privileges. As of version 1.0.0.10, a kernel mode driver is responsible for writing the modified record back to disk. There is also support for unlimited $FILE_NAME attributes, but is restricted to what fits inside an MFT record (not spread across $ATTRIBUTE_LISTS). In earlier versions only the $FILE_NAME attributes was handled this way, but now also $STANDARD_INFORMATION. However be sure to have read the warning below! Makes Cache Manager reload the file system cache stored in memory, after modification.

The $FILE_NAME attribute can be present twice, giving it 8 possible timestamps. Short filenames have only 1 $FILE_NAME attribute (4 timestamps) whereas files with long filenames have 2 $FILE_NAME attributes (4+4 timestamps). In fact, files with links (for instance hardlinks), may have more than 2 $FILE_NAME attributes!

Parameter explanation;

- Parameter 1 is input/target file. Must be full path like "c:\folder\file.ext"

- Parameter 2 is determining which timestamp to update. 
"-m" = LastWriteTime
"-a" = LastAccessTime
"-c" = CreationTime
"-e" = ChangeTime (in $MFT)
"-z" = all 4
"-d" = Dump existing timestamps (given in UTC 0.00), including those in the INDX of the parent.

- Parameter 3 is the wanted new timestamp. Format must be strictly followed like; "1954:04:01:22:39:44:666:1234". That is YYYY:MM:DD:HH:MM:SS:MSMSMS:NSNSNSNS. The smallest possible value to set is; "1601:01:01:00:00:00:000:0001". Timestamps are written as UTC and thus will show up in explorer as interpreted by your timezone location. If parameter 2 is "-g" then this one should be a valid path+filename. Note that nanoseconds are supported.

- Parameter 4 determines if $STANDARD_INFORMATION or $FILE_NAME attribute or both should be modified. 
"-si" will only update timestamps in $STANDARD_INFORMATION (4 timestamps), or just LastWriteTime, LastAccessTime and CreationTime (3 timestamps) for non-NTFS.
"-fn" will only update timestamps in $FILE_NAME (4 timestamps for short names, 8 timestamps for long names, or more if links are involved), and only for NTFS.
"-x" will update timestamps in both $FILE_NAME and $STANDARD_INFORMATION.

- Parameter 4 is optional.
"-shadow" will activate shadow copy mode. Relevant for both read and write. See examples.

Note:
Directories are also supported just like regular files. Since version 1.0.0.10, where a kernel mode driver was implemented, a lot of the restrictions put on earlier versions are now removed. The restrictions that was limiting SetMace in previous versions:

Since nt6.x Microsoft blocked direct write access to within volume space (like \\.\PhysicalDrive0 or \\.\E:): http://msdn.microsoft.com/en-us/library/windows/hardware/ff551353(v=vs.85).aspx
In order to do so it was necessary to dismount the volume first, effectively releasing all open handles to the volume. However this was of course not possible to do on certain volumes (for instance on the systemdrive or a volume where a pagefile existed). The solution to make this work the proper way is to implement a driver that can set the SL_FORCE_DIRECT_WRITE flag on the Irp before sending it further: http://msdn.microsoft.com/en-us/library/windows/hardware/ff549427(v=vs.85).aspx That way, there is no need to dismount the volume, and thus even the systemdrive can be modified. All this, did not apply to nt5.x (XP and Server 2003) and earlier. With 64-bit Windows, Microsoft implemented another security measure, "PatchGuard", that will protect the kernel in memory, and prevent loading unsigned drivers or drivers signed with a test certificate. Of course Windows does not natively ship with a driver allowing to circumvent the security feature mentioned above. That leaves 3 possible options to for properly using SetMace on a 64-bit nt6.x OS (all other Windows OS's are fine):

1. Boot with TESTSIGNING configured and use a test signed driver.
2. Crack PatchGuard (and thus no need for TESTSIGNING  configured) and use a test signed driver.
3. Find a way to use a properly signed driver (maybe next version).

Since the driver in this version is test signed, we need to choose 1 or 2. Both work equally well, and in fact  as of today 4. August 2014, patchguard is officially cracked and unfixed (google KPP Destroyer).

Also note that if driver fails loading, SetMace will attempt the old method of writing to physical disk by dismounting the volume first.

The synchronization of timestamps from $STANDARD_INFORMATION andthose found in the parents INDX entries.
Directories keep attributes of type $INDEX_ROOT and/or $INDEX_ALLOCATION which contains various information about the objects (files/directoris) within that directory. The content within these attributes are indexed information taken from both the $STANDARD_INFORMATION and $FILE_NAME attributes of the object. The timestamps are taken from $STANDARD_INFORMATION. It seems the indexed information is updated whenever the target object is queried in some way. A full investigation of this behavious has not been performed, but I found that a simple call to NtQueryInformationFile would force it to be updated. This fix was implemented in v1.0.0.13. Earlier versions would in some cases leave inconsistencies between $STANDARD_INFORMATION and the indexed $STANDARD_INFORMATION as found in $INDEX_ROOT/$INDEX_ALLOCATION of the parent. The limitation to the fix for this is that target file for modification must be specified by name and not IndexNumber, and NtQueryInformationFile will fail for any of the filesystem metafiles. That means timestamps for metafiles like $MFT and $LogFile can still be changed, but if $STANDARD_INFORMATION is modified, these will be inconsistent with the ones found in the INDX of the root directory. Modified timestamps in $FILE_NAME attribute will not face this inconsistency issue. This holds true for any file on the filesystem.


Dumping information with the -d switch
From version 1.0.0.9 the -d switch will also dump timestamp information from the target volume, as well as from present any shadow copies of that volume. So if the volume that the target file resides on, also have shadow copies, the -d switch will also dump information for the same MFT reference for every relevant shadow copy. Matching shadow copies are identified by the volume name and serial number. The dumped information includes filename, parent ref, sequence number and hardlink number to help identify if the same file actually holds a particular MFT ref across shadow copies. From version 1.0.0.13, also the timestamps in the INDX of the parent are retrieved.

Shadow Copies
With version 1.0.0.14 support has been added to also modify timestamps within shadow copies. It is either all shadow copies or none. Use the -shadow switch. The switch matters for both read and write mode. In order to add the write mode support, quite comprehensive shadow copy parser code had to be added to SetMace. So how could write mode work when shadow copies are read-only. The reason is it is only the symbolic link to it like for instance \\.\GLOBALROOT\Device\HarddiskVolumeShadowCopyX that is read-only. In the end, on the filesystem, it is just a file within the "System Volume Information" folder. However, this file has a complicated structure that needs to be parsed correctly. And the actual data within it, are the modified clusters of the original volume (may appear as a bunch of bits and pieces). The name of the shadow copies are constructed like {GUID}{GUID}, whereas the information about these files are found within a shadow copy master file named {3808876b-c176-4e48-b7ae-04046e6cc752}. The method by which it writes to the shadow copies, is by direct writing to sectors just like it modifes $MFT.

Detection
This new method of timestamp manipulation is a whole lot harder to detect. In oder to do so I can think of analyzing other artifacts like a shadow copy, $UsnJrnl and maybe $LogFile on not so heavily used volumes. A carefully performed and detailed forensic analysis with generated timeline may reviel various things, however this is not trivial work. The earlier version with the move-trick and/or NtSetInformationFile would leave traces in the $LogFile. Even though the $LogFile is circular, and does not hold "evidence" for long on a system drive, you may find earlier versions of it in a shadow copy. The $LogFile contains lots of information, not just traces from NtSetInformationFile (see https://github.com/jschicht/LogFileParser).

Warning:
Bypassing the filesystem and writing to physical disk is by nature a risky operation. And it's success is totally dependent on me gotten SetMace resolving NTFS correctly. Having said that, I have tested it on both XP sp3 x86,  Windows 7 x86/x64 and Windows 8.1 x64, on which it works fine. Still, consider this as very experimental software that is provided for educational purposes. Do not try this tool on volumes you don't have backup of.


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

Setting the LastWriteTime in both $STANDARD_INFORMATION and $FILE_NAME attribute of root directory (defined by its index number):
setmace.exe C:5 -m "2000:01:01:00:00:00:789:1234" -x

Setting the LastWriteTime in the $STANDARD_INFORMATION attribute, for current timestamps and in all shadow copies:
setmace.exe C:\file.txt -m "2000:01:01:00:00:00:789:1234" -si -shadow

Dumping all timestamps for $Boot (including all shadow copies):
setmace.exe C:\$Boot -d -shadow

2 methods for dumping all timestamps for $MFT itself (no shadow copy timestamps displayed):
setmace.exe C:\$MFT -d
or
setmace.exe C:0 -d



Thanks:
Ascend4nt for the WinTimeFunctions
DDan at forensicfocus for various help
Driver code; http://www.codeproject.com/Articles/28314/Reading-and-Writing-to-Raw-Disk-Sectors





