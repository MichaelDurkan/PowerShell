# Script: ccmuninstall.ps1
# Description: Uninstalls current SCCM Client from a group of computers specified in a text file
# Execution: PS> PowerShell.exe -ExecutionPolicy ByPass ".\ccmuninstall.ps1" -WindowStyle Hidden -Wait
# Author: Michael Durkan
# Last Modified: 2021-03-25
#

# This file queries a txt file for a list of fqdn computer names and stores them in a variable
$computerNames = Get-Content "C:\temp\ccm-machines2.txt"

# This specifies the application name that we wish to uninstall. You can get a list of these by running "Get-WmiObject -Class Win32_Product", and selecting the "Name"
$appName = "Configuration Manager Client"

# This prompts for credentials - you must have Administrator credentials on the target machines for the uninstall to complete
$yourAccount = Get-Credential

# This cycles through the list of computers stored in the "$computernames" and runs the ScriptBlock to uninstall
ForEach ($computerName in $computerNames) {
    Invoke-Command -ComputerName $computerName -Credential $yourAccount -ScriptBlock {
    $logPath = "C:\temp\SCCM-Client"
    # This specifies a log file path on the target machine(s) for the uninstaller
    New-Item -Path $logPath -Type Directory -Force | Out-Null
    $timeDate = Get-Date -Format "yyyyMMdd-HHmmss"
    $logFileName = $env:COMPUTERNAME + "_" + $timeDate
    #
    New-Item -Path $logPath -Type Directory -Force | Out-Null
    #
    #
    $procMsiExec = Get-Process -Name msiexec -ErrorAction SilentlyContinue
    $procCCMExec = Get-Process -Name ccmexec -ErrorAction SilentlyContinue
    $procCCMSetup = Get-Process -Name ccmsetup -ErrorAction SilentlyContinue
    #
    #
    # This stops the CcmExec service on the target machine(s)
    if ($procMsiExec -or $procCCMExec -or $procCCMSetup) {
    Stop-Service -Name CcmExec -Force | Out-File -FilePath $logPath\$logFileName.log -Append -Encoding ascii -Force
    "Processess have been stopped. Executing ccmsetup.exe /uninstall command..." | Out-File -FilePath $logPath\$logFileName.log -Append -Encoding ascii -Force
    # Once the services havve stopped, this runs the uninstall command and outputs the results to the log files specified in $logpath
    Start-Process "ccmsetup.exe" -ArgumentList "/uninstall" -Wait | Out-File -FilePath $logPath\$logFileName.log -Append -Encoding ascii -Force
    Start-Sleep 15
    do {
    Start-Sleep 10
    "Uninstall is running..." | Out-File -FilePath $logPath\$logFileName.log -Append -Encoding ascii -Force
    $procMsiExec = Get-Process -Name msiexec -ErrorAction SilentlyContinue
    $procCCMExec = Get-Process -Name ccmexec -ErrorAction SilentlyContinue
    $procCCMSetup = Get-Process -Name ccmsetup -ErrorAction SilentlyContinue
    Start-Sleep 5
    }
    until (($procMsiExec -eq $null) -and ($procCCMExec -eq $null) -and ($procCCMSetup -eq $null))
    # This returns the message "Uninstaller has completed" to the log files once the above processes no longer exist on the target machine(s)
    "Uninstaller has completed..." | Out-File -FilePath $logPath\$logFileName.log -Append -Encoding ascii -Force
        }
    }
}

#
