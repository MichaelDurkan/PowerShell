# This uses Powershell to pass parameters into the Merge-VHD command in order to merge an avhdx file back to its parent vhdx

$Merge = @{
  Path = 'c:\artofshell\client01_670A3C15-3E10-425E-A60E-A6F93DF13E20.avhdx'
  DestinationPath = 'c:\artofshell\client01.vhdx'
}
Merge-VHD @Merge

# If you get an error from the above command, you need to install the PS Module for Hyper-V
# To do this, run ```Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-PowerShell```
