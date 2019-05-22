###
#
# Lenovo PowerShell script examples - Manage Intel DCPMM
#
#
# Copyright © 2019-present Lenovo
# Licensed under BSD-3, see LICENSE file for details
###

param([switch]$Show, [switch]$ShowPhysicalInfo, [switch]$Ready, [switch]$RemoveAll, [switch]$Remove, [switch]$Help, [switch]$Version)

# Show the basic information of pmem disks 
function ShowPmemDisk()
{
    $diskInfo = get-disk | where -filter {$_.Bustype -like "SCM"}
    if ($diskInfo -eq $null)
    {
        write-host "no available pmem device" -ForegroundColor "Red"
    }
    else
    {
        $diskInfo
    }
}

# Show the physical information of pmem disks
function ShowPhysicalInfo()
{
    $diskInfo = get-disk | where -filter {$_.Bustype -like "SCM"}
    if ($diskInfo -eq $null)
    {
        write-host "no available pmem device" -ForegroundColor "Red"
    }
    else
    {
        Get-PmemDisk | Get-PmemPhysicalDevice
    }
}

# Make all your pmem disks ready to be use
function MakePmemDiskReady()
{
    # Get the information of used drive
    $usedDrive = (Get-PSDrive -PSProvider FileSystem).Name
    # Get the information of unused drive except for A, B, and C drive
    $unusedDrive = 68..90 | ForEach-Object {[string][char]$_} | Where-Object {$usedDrive -notcontains $_}
    #write-host "The available drives are as following:" -ForegroundColor "Green"
    #$unusedDrive

    $UnusedPMCheck = Get-PmemUnusedRegion
    if ($UnusedPMCheck -ne $null)
    {
        write-host "try to create namespace for unused region of pmem device" -ForegroundColor "Green"
        Get-PmemUnusedRegion | New-PmemDisk
        $diskInfo = get-disk | where -filter {$_.Bustype -like "SCM"} 
    }

    # Get the disk information for persistent memory
    $diskInfo = get-disk | where -filter {$_.Bustype -like "SCM"} 
    if ($diskInfo -eq $null)
    {
        write-host "no available pmem device" -ForegroundColor "Red"
    }
    else
    {
        #$diskInfo = get-disk | where -filter {$_.Bustype -like "SCM"}
        $diskInfo = get-disk -FriendlyName "Persistent memory disk" | where {$_.PartitionStyle -eq "RAW"}
        if ($diskInfo -eq $null)
        {
            write-host "Pmem device is ready for use" -ForegroundColor "Green"
        }
        else
        {
            if ($unusedDrive.Count -lt $diskInfo.Count)
            {
                 write-host "The free drive is less than the required!" -ForegroundColor "Red"
                 write-host "The available drives are as following:" -ForegroundColor "Green"
                 $unusedDrive
                 write-host "The count for pmem devices is :" $diskInfo.Count -ForegroundColor "Green"
            }

            $i = 0;
            write-host "RAW SCM devices are waiting for the initialization: " -ForegroundColor "Green"  
            Foreach ($disknum in $diskInfo.Number) {
               if ($i -ge $unusedDrive.Count)
               {
                   write-host "No more free drive!" -ForegroundColor "Red"
                   return
               }

               # format the persistent memory disk with GPT partition
               get-disk -number $disknum | Initialize-Disk -PartitionStyle GPT
               # Initialize the persistent memory disk with DAX mode. The drive letter is the minimal unused one.
               get-disk -number $disknum | New-Volume -FriendlyName DAX-VOL -DriveLetter $unusedDrive[$i] | Format-volume -Filesystem NTFS -IsDAX $true      
               $i = $i +1;       
            }
        }
    }
}

# Remove one pmem disk. 
# The input is the disk number
function RemovePmemDisk($number)
{
    # Here we remove the persistent memory disk whose disk number is got from input args

    # Get the disk information for persistent memory
    $diskInfo = get-disk | where -filter {$_.Bustype -like "SCM"}
    if ($diskInfo -eq $null)
    {
        write-host "No pmem device to be removed" -ForegroundColor "Red"
        return
    }
    if ($diskInfo.DiskNumber -notcontains $number)
    {
        write-host "No pmem device to be removed" -ForegroundColor "Red"
        return
    }
    

    # Get the disk information for RAW SCM
    $diskInfo = get-disk | where {$_.PartitionStyle -match "RAW"} | where -filter {$_.Bustype -like "SCM"} 
    if ($diskInfo -ne $null -and $diskInfo.DiskNumber -contains $number)
    {
        write-host "This operation will destroy the persistent namespaces from your disk $number" -ForegroundColor "White"
        write-host "Data will lose if you select Yes or Yes to All in the subsequent pop-up box." -ForegroundColor "Red"
        Get-PmemDisk $number | Remove-PmemDisk
    }

    # Get the disk information for initialized SCM
    $diskInfo = get-disk | where {$_.PartitionStyle -match "GPT"} | where -filter {$_.Bustype -like "SCM"} 
    if ($diskInfo -ne $null -and $diskInfo.DiskNumber -contains $number)
    {
        write-host "This operation will destroy the persistent namespaces from your disk $number" -ForegroundColor "White"
        write-host "Data will lose if you select Yes or Yes to All in the subsequent pop-up box." -ForegroundColor "Red"
        #if the disk is initialized you should clear it first
        Clear-Disk -Number $number -RemoveData
        Get-PmemDisk $number | Remove-PmemDisk
    }
}

# Remove all pmem disks
function RemoveAllPmemDisk()
{
    $diskInfo = get-disk | where -filter {$_.Bustype -like "SCM"}
    if ($diskInfo -eq $null)
    {
        write-host "No pmem device to be removed" -ForegroundColor "Red"
        return
    }

    # Get the disk information for RAW SCM
    $diskInfo = get-disk | where {$_.PartitionStyle -match "RAW"} | where -filter {$_.Bustype -like "SCM"}
    if ($diskInfo -ne $null)
    {
        write-host "This operation will destroy the persistent namespaces from your disk $number" -ForegroundColor "White"
        write-host "Data will lose if you select Yes or Yes to All in the subsequent pop-up box." -ForegroundColor "Red"
     
        $myDiskNumber = $diskInfo.DiskNumber | Measure-Object -Minimum
        $j = $myDiskNumber.Minimum

        $i = $diskInfo.DiskNumber.Count - 1
        while ($i -ge 0) {
            Get-PmemDisk $j | Remove-PmemDisk
            $i = $i - 1
        }
    } 

    # Get the disk information for initialized SCM
    $diskInfo = get-disk | where {$_.PartitionStyle -match "GPT"} | where -filter {$_.Bustype -like "SCM"}
    if ($diskInfo -ne $null)
    {
        write-host "This operation will destroy the persistent namespaces from your disk $number" -ForegroundColor "White"
        write-host "Data will lose if you select Yes or Yes to All in the subsequent pop-up box." -ForegroundColor "Red"
     
        $myDiskNumber = $diskInfo.DiskNumber | Measure-Object -Minimum
        $j = $myDiskNumber.Minimum

        $i = $diskInfo.DiskNumber.Count - 1
        while ($i -ge 0) {
            #if the disk is initialized you should clear it first
            Clear-Disk -Number $j -RemoveData
            Get-PmemDisk $j | Remove-PmemDisk
            $i = $i - 1
        }
    } 
}

# Remove one pmem disk and initialize the label storage area on the physical persistent memory devices. 
# This can be used to clear corrupted label storage info on the persistent memory devices.
# The input is the disk number
function RemovePmemDisk_label($number)
{
    # Here we remove the persistent memory disk whose disk number is got from input args

    # Get the disk information for persistent memory
    $diskInfo = get-disk | where -filter {$_.Bustype -like "SCM"} 
    if ($diskInfo -ne $null)
    {
        if ($diskInfo.DiskNumber -contains $number)
        {
            write-host "This operation will destroy the persistent namespaces from your disk $number and re-initialize the lable storage area." -ForegroundColor "White"
            write-host "Data will lose if you select Yes or Yes to All in the subsequent pop-up box." -ForegroundColor "Red"
            Get-PmemDisk $number | Get-PmemPhysicalDevice | Initialize-PmemPhysicalDevice
        }
        else
        {
            write-host "No such a pmem device. Please check the input disk number!" -ForegroundColor "Red"
        }
    }
    else
    {
    write-host "No pmem device to be removed" -ForegroundColor "Red"
    }
}

# Remove all pmem disks and initialize the label storage area on the physical persistent memory devices. 
# This can be used to clear corrupted label storage info on the persistent memory devices.
function RemoveAllPmemDisk_label()
{
    # Get the disk information for persistent memory
    $diskInfo = get-disk | where -filter {$_.Bustype -like "SCM"} 
    if ($diskInfo -ne $null)
    {
        write-host "This operation will destroy ALL persistent namespaces from your pmem disks and re-initialize the lable storage area." -ForegroundColor "White"
        write-host "Data will lose if you select Yes or Yes to All in the subsequent pop-up box." -ForegroundColor "Red"
     
        $myDiskNumber = $diskInfo.DiskNumber | Measure-Object -Minimum
        $j = $myDiskNumber.Minimum

        $i = $diskInfo.DiskNumber.Count - 1
        while ($i -ge 0) {
            Get-PmemDisk $j | Get-PmemPhysicalDevice | Initialize-PmemPhysicalDevice
            $i = $i - 1
        }
    } 
    else
    {
        write-host "No pmem device to be removed" -ForegroundColor "Red"
    } 
}

# Show help information
function PmemToolHelp()
{
    write-host "#####################################################################################"
    write-host "Please use this tool in Windows Server 2019 to manage your pmem disk:" -ForegroundColor "White"
    write-host "To show the basic information of pmem disks   , usage: PmemTool.ps1 -Show" -ForegroundColor "White"
    write-host "To show the physical information of pmem disks, usage: PmemTool.ps1 -ShowPhysicalInfo" -ForegroundColor "White"
    write-host "To make all your pmem disks ready to be use,    usage: PmemTool.ps1 -Ready" -ForegroundColor "White"
    write-host "To remove one pmem disk,                        usage: PmemTool.ps1 -Remove disknum" -ForegroundColor "White"
    write-host "To remove all pmem disks,                       usage: PmemTool.ps1 -Removeall" -ForegroundColor "White"
    write-host "To get the version of this tool,                usage: PmemTool.ps1 -Version" -ForegroundColor "White"
    write-host "#####################################################################################"
}

if ($Show)
{
    ShowPmemDisk
}
if ($ShowPhysicalInfo)
{
    ShowPhysicalInfo
}

if ($Ready)
{
    MakePmemDiskReady
}

if ($Remove)
{
    RemovePmemDisk($args[0])
}
if ($RemoveAll)
{
    RemoveAllPmemDisk
}

if ($Help)
{
    PmemToolHelp
}

if ($Version)
{
    write-host "PMemtool v1.2 " -ForegroundColor "Green"  
}