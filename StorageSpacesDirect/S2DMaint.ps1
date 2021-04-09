# The list of commands below are used in maintenance operations on S2D Clusters. 
# BE CAREFUL WHEN RUNNING THESE, AS SOME OF THEM CAN CAUSE SEVERE DAMAGE OR DESTROY ELEMENTS OF YOUR CLUSTER AND CAUSE OUTAGES!!

# Runs Full Repair and Rebalance on all Nodes and Storage Pool
Get-StoragePool IEATS2DpOOL01 | Optimize-StoragePool

# Show Status of Jobs running on Storage Pool
Get-StorageJob

# Show Status of VirtualDisks in Storage Pool
Get-VirtualDisk

# This will create the "RefreshStorageJobStatus" function which will run the Get-VirtualDisk and Get StorageJob commands in a loop every second and outputs to the screen. Once the command has completed, run "RefreshStorageJobStatus" from the command line
function RefreshStorageJobStatus () { while($true) { Get-VirtualDisk | ft; Write-Host "-----------";  Get-StorageJob;Start-Sleep -s 1;Clear-Host; } }

# Creates SMB Constraint so that SMB traffic will only use SMB Networks. Needs to be done on each S2D Cluster Node
New-SmbMultichannelConstraint -ServerName FS01 -InterfaceAlias "smb1-net", "smb2-net"

# Gets output of all drives in specific node plus their attributes
Get-StorageNode -Name <Cluster-Node> | Get-PhysicalDisk -PhysicallyConnected | sort PhysicalLocation | ft SerialNumber, PhysicalLocation, OperationalStatus, Usage

# Attempt to repair the entire cluster
Repair-ClusterStorageSpacesDirect

# Attempt to repair a single node in the S2D cluster
Repair-ClusterStorageSpacesDirect - Node <Cluster-Node>


# Take Disk Offline and Run Chkdsk

# Takes CSV Offline
Stop-clusterresource -Name "Cluster Disk 1"

# removes the disk from Cluster Shared Volumes
Remove-clustersharedvolume -Name "Cluster Disk 1"

# Runs Chkdsk on CSV
Get-Clusterresource -Name "Infra-CL1" | set-clusterparameter -name diskrunchkdsk -value 7

# Sets Action to try to recover the disk in event of failure
Get-ClusterResource -Name "Infra-CL1" | Set-ClusterParameter -Name diskrecoveryaction -Value 1

# Once the repair jobs have completed, set the Cluster Parameters back to default values, which is 0
Get-ClusterResource -Name "Cluster Disk 1" | Set-ClusterParameter -Name diskrecoveryaction -Value 0
Get-Clusterresource -Name "Cluster Disk 1" | set-clusterparameter -name diskrunchkdsk -value 0

# adds the disk from Cluster Shared Volumes
Remove-clustersharedvolume -Name "Cluster Disk 1"

# Brings the CSV back online
Start-clusterresource -Name "Cluster Disk 1"

# disables requirement for SMB security signature - details here: https://support.microsoft.com/en-us/help/4458042/reduced-performance-after-smb-encryption-or-smb-signing-is-enabled
Set-SmbClientConfiguration -RequireSecuritySignature $false -EnableSecuritySignature $false
Set-SmbServerConfiguration -RejectUnencryptedAccess $false -EnableSecuritySignature $false -RequireSecuritySignature $false

# To remove retired or damaged disks from the storage pool

# creates a $disk variable that will be used in the next command to remove all disks that are in 
$disk = get-physicaldisk | where-object usage -like retired
Get-StoragePool <FriendlyName> | Remove-PhysicalDisk -physicaldisk $disk
