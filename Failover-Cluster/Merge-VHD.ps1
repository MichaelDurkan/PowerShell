# This uses Powershell to pass parameters into the Merge-VHD command in order to merge an avhdx file back to its parent vhdx

$Merge = @{
  Path = 'c:\artofshell\client01_670A3C15-3E10-425E-A60E-A6F93DF13E20.avhdx'
  DestinationPath = 'c:\artofshell\client01.vhdx'
}
Merge-VHD @Merge
