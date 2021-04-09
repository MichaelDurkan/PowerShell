# This file shows a list of commands to be used when setting up a 4-Node Storage Spaces Direct Cluster
# https://channel9.msdn.com/Series/Server2016Storage/Storage-Spaces-Direct-Deploying-End-to-End


#Test Cluster Configuration
Test-Cluster -Node Node1, Node2, Node3, Node4 -Include "Storage Spaces Direct", Inventory, Network, "System Configuration"

#Create New Cluster
New-Cluster -Name <ClusterName> -Node Node1, Node2, Node3, Node4 -NoStorage -StaticAddress 10.0.0.1

#Rename Networks
(Get-ClusterNetwork | Where-Object {$_.Address -eq "10.1.0.0/24"}).Name = "mgmt-net"
(Get-ClusterNetwork | Where-Object {$_.Address -eq "10.2.0.0/24"}).Name = "smb1-net"
(Get-ClusterNetwork | Where-Object {$_.Address -eq "10.3.0.0/24"}).Name = "smb2-net"

#Assign Roles to Networks
#Role 1 is Cluster Only, Role 3 is Cluster and Client - https://blogs.technet.microsoft.com/askcore/2014/02/19/configuring-windows-failover-cluster-networks/
(Get-ClusterNetwork -Name "mgmt-net").Role = 3
(Get-ClusterNetwork -Name "smb1-net").Role = 3
(Get-ClusterNetwork -Name "smb2-net").Role = 3

#Set Live Migration Network
Get-ClusterResourceType -Name "Virtual Machine" | Set-ClusterParameter -Name MigrationExcludeNetworks -Value ([String]::Join(";",(Get-ClusterNetwork | Where-Object {$_.Name -ne "Live Migration"}).ID))

# Enable S2D
Enable-ClusterStorageSpacesDirect

#Check Cluster Health
Get-StorageSubSystem *Cluster*

#Count Physical Disks
(Get-StorageSubSystem -Name *Cluster* | Get-PhysicalDisk).Count

#Show disks that cannot be added to storage pool (should return as empty)
Get-StorageSubSystem -Name *Cluster* | Get-PhysicalDisk |? CanPool -ne $true

#Show disks that can be added to storage pool (should list all disks)
Get-StorageSubSystem -Name *Cluster* | Get-PhysicalDisk |? CanPool -eq $true

#Create StoragePool
New-StoragePool -StorageSubSystemName *Cluster* -FriendlyName S2DPool01 -WriteCacheSizeDefault 0 - ProvisioningTypeDefault Fixed -ResiliencySettingNameDefault Mirror -PhysicalDisk (Get-StorageSubSystem -Name *Cluster* | Get-PhysicalDisk)
Set-StoragePool -FriendlyName S2DPool01 -WriteCacheSizeDefault 0 - ProvisioningTypeDefault Fixed -ResiliencySettingNameDefault Mirror

#Set all disks of type SSD to Journal Mode (Cache)
Get-StoragePool S2DPool01 | Get-PhysicalDisk |? MediaType -eq SSD | Set-PhysicalDisk -Usage Journal

#Create Storage Tiers
New-StorageTier -StoragePoolFriendlyName S2DPool01 -FriendlyName MirrorTier1 -MediaType HDD -ResiliencySetting Mirror -PhysicalDiskRedundancy 2
New-StorageTier -StoragePoolFriendlyName S2DPool01 -FriendlyName ParityTier1 -MediaType HDD -ResiliencySetting Parity -PhysicalDiskRedundancy 2

#Create Multi-Resilient Volume
$mt = Get-StorageTier MirrorTier1
$mt = Get-StorageTier ParityTier1

New-Volume -FriendlyName “Pool1-CL1” -FileSystem CSVFS_ReFS -StoragePoolFriendlyName IEATS2DPool01  -Size 5TB -ResiliencySettingName Mirror
New-Volume -FriendlyName “Pool2-CL1” -FileSystem CSVFS_ReFS -StoragePoolFriendlyName IEATS2DPool01  -Size 10TB -ResiliencySettingName Mirror


#Create Scale Out File Server

New-StorageFileServer -StorageSubSystemName *Cluster* -FriendlyName FS01 -Hostname FS01 -Protocols SMB
(associate IPs SMB Networks)


#Create File Shares
md C:\ClusterStorage\Volume1\VMs
New-SMBShare -Name VMs -Path C:\ClusterStorage\Volume1\VMs -FullAccess Node1$, Node2$, Node3$, Node4$, Administrator, IEAT-S2D-CL01$, AllComputers 
Set-SmbPathAcl -ShareName VMs

# Set SMB Multi Channel Constraints - https://www.darrylvanderpeijl.com/scale-out-file-server-dns-settings/

New-SmbMultichannelConstraint -ServerName FS01 -InterfaceAlias “smb1-net1”, “smb2-net”

## The above commands need to be done for both NetBIOS and FQDN of each SOFS on all of the S2D Cluster Nodes
