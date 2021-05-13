  
<#
        .SYNOPSIS
        Windows Update Server Script
  
        .DESCRIPTION
        WSUS Statistic script in which it pulls the data and then t will then convert them into JSON, ready to add into InfluxDB and show it with Grafana
	
        .Notes
        NAME:  wsus-stats.ps1
        ORIGINAL NAME: wsus.ps1
        LASTEDIT: 19/01/2018
        VERSION: 0.3
        KEYWORDS: WSUS, Grafana 
   
        .Link
        https://docs.microsoft.com/en-us/powershell/module/wsus/?view=win10-ps
        https://devhub.io/repos/proxb-PoshWSUS
 
 #Requires PS -Version 3.0
 #Requires -Modules PoshWSUS
 #Requires -Modules WSUS    
 #>

Import-Module PoshWSUS
Connect-PSWSUSServer -WsusServer ieatwsus.rnd.ericsson.se -Port 8530 | Out-Null

#region: Data Collecting
# Collect Client Information
$client = Get-PSWSUSClient

# Collect Group Information
$wsusgroup = Get-PSWSUSGroup

# Collect Update Summary per Client
$updatesummary = Get-PSWSUSUpdateSummaryPerClient
$wsusupdates = Get-WsusUpdate

#endregion


#region: Preparing Client Information
$clienthostswinl = @($client | ?{$_.OSDescription -eq "Windows Server 2012 R2"})
$clienthostswinm = @($client | ?{$_.OSDescription -eq "Windows Server 2008 R2 Datacenter Edition"})
$clienthostswinn = @($client | ?{$_.OSDescription -eq "Windows Server 2008 R2 Standard Edition"})
$clienthostswino = @($client | ?{$_.OSDescription -eq "Windows Server 2012"})
$clienthostswinp = @($client | ?{$_.OSDescription -eq "Windows 7"}) 
$clienthostswinq = @($client | ?{$_.OSDescription -eq "Windows Server 2016 Standard"})
$clienthostswinr = @($client | ?{$_.OSDescription -eq "Windows Server 2016 Datacenter"})

#endregion

#region: Preparing Update Information
$wsusupdated = @($wsusupdates | ?{$_.Classification -eq "Critical Updates"})
$wsusupdatee = @($wsusupdates | ?{$_.Classification -eq "Updates"})
$wsusupdatef = @($wsusupdates | ?{$_.Classification -eq "Service Packs"})

#endregion

#region: Summary of Updates
$wsusneed = @($updatesummary | ?{$_.Needed -ge 1})
$wsusfailed = @($updatesummary | ?{$_.Failed -ge 1})
$wsusreboot = @($updatesummary | ?{$_.PendingReboot -ge 1})


#region: # InfluxDB Output for Telegraf
 
$Count = $clienthostswinl.Count
$body="wsus-stats windows2012r2=$Count"
Write-Host $body 
$Count = $clienthostswinm.Count
$body="wsus-stats windows2008r2dced=$Count"
Write-Host $body 
$Count = $clienthostswinn.Count
$body="wsus-stats windows2008stded=$Count"
Write-Host $body
$Count = $clienthostswino.Count
$body="wsus-stats windows2012=$Count"
Write-Host $body
$Count = $clienthostswinp.Count
$body="wsus-stats windows7=$Count"
Write-Host $body
$Count = $clienthostswinq.Count
$body="wsus-stats windows2016std=$Count"
Write-Host $body
$Count = $clienthostswinr.Count
$body="wsus-stats windows2016dc=$Count"
Write-Host $body
$Count = $wsusupdated.Count
$body="wsus-stats criticalupdates=$Count"
Write-Host $body
$Count = $wsusupdatee.Count
$body="wsus-stats updates=$Count"
Write-Host $body
$Count = $wsusupdatef.Count
$body="wsus-stats sp=$Count"
Write-Host $body
$Count = $client.Count
$body="wsus-stats numberofclients=$Count"
Write-Host $body
$Count = $wsusneed.Count
$body="wsus-stats requpdates=$Count"
Write-Host $body
$Count = $wsusfailed.Count
$body="wsus-stats failed=$Count"
Write-Host $body
$Count = $wsusreboot.Count
$body="wsus-stats reqreboot=$Count"
Write-Host $body


#endregion
