# PmemTool 1.2. 
A PowerShell tool to manage Intel Optane DC Persistent Memory (DCPM) in Windows Server 2019

Description
----------
You can use this tool to manage your Intel DCPMM in App direct or mixed mode in Windows Server 2019.
Before using it the one thing you need do is to create goal for your pmem disk in UEFI setting.


Usage
----------
To show the basic infomation of pmem disks, such as disk number, healthy status, size  
Usage: `PmemTool.ps1 -Show`

To show the physical information of pmem disks, such as deviceID, physical location, firmware version, size
Usage: `PmemTool.ps1 -ShowPhysicalInfo`

To make all your pmem disks ready to be use with DAX mode
Usage: `PmemTool.ps1 -Ready`

* If there is unused region of your pmem disk, this operation will help to create namespaces.
* It will help you initialize the disk with GPT partition and format them with DAX mode.
* It will assign the free drives for your pmem disks one by one.
* If the free drives are not enough for your pmem disks it will tell you.

To remove one pmem disk
Usage: `PmemTool.ps1 -Remove disknum`
*  If you want to clean this pmem disk, suggest you select "Yes to all" in the pop-up box. The data will lose.
* If you don't want to clean this pmem disk, suggest you select "Not to all" in the pop-up box. 

To remove all pmem disks
Usage: `PmemTool.ps1 -Removeall`
* If you want to clean your pmem disks, suggest you select "Yes to all" in the pop-up box. The data will lose.
* If you don't want to clean your pmem disks, suggest you select "Not to all" in the pop-up box. 

To get the version of this tool
Usage: `PmemTool.ps1 -Version`

To get the help about this tool
Usage: `PmemTool.ps1 -Help`

