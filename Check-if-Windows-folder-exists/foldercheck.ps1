# Checks a text file for a list of machines
Get-Content c:\temp\ccm-machines.txt | `

# Runs check to see if folder exists on target machine(s)
Select-Object @{Name='ComputerName';Expression={$_}},@{Name='FolderExist';Expression={ Test-Path "\\$_\c$\windows\ccmsetup\ccmsetup.exe"}} |

# Exports results to csv
Export-Csv c:\temp\results.csv

# Results will look like this

##TYPE Selected.System.String
#"ComputerName","FolderExist"
#"PC05","True"
#"PC23","False"
#"PC25","True"
#"PC41","True"
#"PC67","False"
#"PC71","False"
#"PC72","False"
#"PC83","True"
