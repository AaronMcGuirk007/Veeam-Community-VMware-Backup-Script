# --- PowerCLI / VMware modules ------------------------------------------------
Import-Module VMware.VimAutomation.Core

$UserModules      = "C:\Users\{USER}\Documents\WindowsPowerShell\Modules" # Full path to your PowerShell Modules (recommended if there are 50+ VMs)
$env:PSModulePath  = "$UserModules;$env:PSModulePath"

Import-Module VMware.VimAutomation.Core   -Force
Import-Module VMware.VimAutomation.Common -Force
Import-Module VMware.VimAutomation.ViCore -Force

# --- Run VM listing script ----------------------------------------------------
& "C:\Path\To\Veeam-Get-vSphere-VMs.ps1" # Path to the script that pulls the VM names from your VMware ecosystem

# --- Connect to vCenter / ESXi -----------------------------------------------
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

$VIServer    = "SERVER IP ADDRESS HERE"
$VIUsername  = "veeam@yourdomain.com"    # Your local Veeam Community Edition Username
$VIPassword  = "yourveeampassword"      # Your local Veeam Community Edition Password

$SecurePassword = ConvertTo-SecureString $VIPassword -AsPlainText -Force
$Credential     = New-Object System.Management.Automation.PSCredential ($VIUsername, $SecurePassword)

Connect-VIServer -Server $VIServer -Credential $Credential

# --- Read VM names from output file ------------------------------------------
$OutputFilePath = "C:\Path\To\output.txt"

# Read the line as raw text
$VMNamesRaw = Get-Content -Path $OutputFilePath -Raw

# Convert to an array of strings
$VMNames = Invoke-Expression "@($VMNamesRaw)"

# --- Backup settings ----------------------------------------------------------
$HostName           = "ESXi or VCenter IP Address"       # Change to your ESXi or VCenter IP Address
$BaseDirectory      = "C:\Path\To\Your\Save_Directory"   # Change to where you want the VeeamZIP files saved
$Timestamp          = Get-Date -Format "yyyy-MM-dd_HHmmss"
$Directory          = Join-Path $BaseDirectory $Timestamp
$CompressionLevel   = "6"
$EnableQuiescence   = $true
$EnableNotification = $true

# --- Retention (delete folders older than N days, keep newest N) --------------
$RetentionDays = 2
$KeepCount     = 3
$Now           = Get-Date
$Cutoff        = $Now.AddDays(-$RetentionDays)

# Get directories sorted from newest → oldest
$Dirs = Get-ChildItem -Path $BaseDirectory -Directory |
  Sort-Object -Property LastWriteTime -Descending

# Always keep the newest N
$DirsToKeep = $Dirs | Select-Object -First $KeepCount

# Filter directories older than retention AND not in Keep list
$DirsToDelete = $Dirs | Where-Object {
  $_.LastWriteTime -lt $Cutoff -and
  ($DirsToKeep -notcontains $_)
}

foreach ($dir in $DirsToDelete) {
  try {
    Write-Host "Deleting old backup directory: $($dir.FullName)" -ForegroundColor Cyan
    Remove-Item -Path $dir.FullName -Recurse -Force
  }
  catch {
    Write-Host "Failed to delete directory $($dir.FullName): $($_.Exception.Message)" -ForegroundColor Red
  }
}

# --- Ensure output directory exists ------------------------------------------
if (-not (Test-Path -Path $Directory -PathType Container)) {
  try {
    Write-Host "Creating backup directory: $Directory" -ForegroundColor Yellow
    New-Item -Path $Directory -ItemType Directory -Force | Out-Null
  }
  catch {
    Write-Error "Failed to create backup directory: $($_.Exception.Message)"
    exit
  }
}

# --- Email settings -----------------------------------------------------------
$Timestamp     = Get-Date -Format "yyyyMMdd_HHmmss"
$SMTPServer    = "smtp.gmail.com"             # Google SMTP Server
$SMTPPort      = "587"                        # Google SMTP Port
$SMTPUser      = "yourgmailaddress@gmail.com" # Change to your Gmail Address
$SMTPPasswd    = "googleapppassword"          # Generate an App Password (2FA MUST be enabled)
$EmailFrom     = "noreply@yourdomain.com"     # Email FROM Address
$EmailTo       = "recipient@yourdomain.com"   # Email TO Address
$EmailSubject  = "VMware ALB Cluster VeeamZIP Backup Report" # Subject line of the Email Report

# --- Veeam / Timezone setup ---------------------------------------------------
$Server           = Get-VBRServer -Name $HostName
$TimeZone         = [System.TimeZoneInfo]::FindSystemTimeZoneById("Eastern Standard Time")
$OverallStartTime = [System.TimeZoneInfo]::ConvertTimeFromUtc((Get-Date).ToUniversalTime(), $TimeZone).ToString("MM/dd/yyyy hh:mm:ss tt")
$MessageBody      = @()

# --- Backup loop --------------------------------------------------------------
foreach ($VMName in $VMNames) {
  $VM = Find-VBRViEntity -Name $VMName -Server $Server

  if ($VM -eq $null) {
    Write-Host "VM $VMName not found! Skipping..." -ForegroundColor Red
    $MessageBody += @"
<tr><td style='padding: 8px; text-align: center; font-size: 12px;'>$VMName</td><td style='padding: 8px; text-align: center; color: red; font-size: 12px;'>Not Found</td></tr>
"@
    continue
  }

  try {
    $BackupTimestamp = [System.TimeZoneInfo]::ConvertTimeFromUtc((Get-Date).ToUniversalTime(), $TimeZone).ToString("MM/dd/yyyy hh:mm:ss tt")

    $Session = Start-VBRZip `
      -Entity $VM `
      -Folder $Directory `
      -Compression $CompressionLevel `
      -DisableQuiesce:(!$EnableQuiescence)

    do {
      Start-Sleep -Seconds 5
      $LiveSession = Get-VBRBackupSession -Id $Session.Id
    } while ($LiveSession.State -eq "Working")

    switch ($LiveSession.Result) {
      "Success" {
        $StatusText = "<td style='padding: 8px; text-align: center; color: green; font-size: 12px;'>Success</td>"
        Write-Host "✅ $VMName backup completed successfully." -ForegroundColor Green
      }
      "Warning" {
        $StatusText = "<td style='padding: 8px; text-align: center; color: orange; font-size: 12px;'>Warning</td>"
        Write-Host "⚠️ $VMName backup completed with warnings." -ForegroundColor Yellow
      }
      "Failed" {
        $StatusText = "<td style='padding: 8px; text-align: center; color: red; font-size: 12px;'>Failed</td>"
        Write-Host "❌ $VMName backup failed." -ForegroundColor Red
      }
      default {
        $StatusText = "<td style='padding: 8px; text-align: center; color: gray; font-size: 12px;'>Unknown</td>"
        Write-Host "❓ $VMName backup result unknown." -ForegroundColor Gray
      }
    }

    $NewNotes = "Last Backup: [$BackupTimestamp] by [BNC-VMBK-PRD-01] saved to [BNC-NAS-PRD-02]"
    Set-VM -VM $VMName -Notes $NewNotes -Confirm:$false

    $MessageBody += @"
<tr><td style='padding: 8px; text-align: center; font-size: 12px;'>$VMName</td>$StatusText</tr>
"@
  }
  catch {
    $ErrorMessage = $_.Exception.Message.Replace('"', "'")
    Write-Host "Backup exception for VM: $VMName - Error: $ErrorMessage" -ForegroundColor Red
    $MessageBody += @"
<tr><td style='padding: 8px; text-align: center; font-size: 12px;'>$VMName</td><td style='padding: 8px; text-align: center; color: red; font-size: 12px;'>Failed ($ErrorMessage)</td></tr>
"@
  }
}

$OverallEndTime = [System.TimeZoneInfo]::ConvertTimeFromUtc((Get-Date).ToUniversalTime(), $TimeZone).ToString("MM/dd/yyyy hh:mm:ss tt")

# --- Send notification email --------------------------------------------------
if ($EnableNotification -and $MessageBody.Count -gt 0) {
  $HTMLTemplatePath = "C:\Users\administrator.AMDT\Desktop\Backup Powershell Scripts\PROD\BackupEmail.html"

  try {
    $HTMLBody = Get-Content -Path $HTMLTemplatePath -Raw
  }
  catch {
    Write-Error "Failed to read HTML template file: $($_.Exception.Message)"
    exit
  }

  $BackupStatusTableHTML = ""
  foreach ($Entry in $MessageBody) {
    $BackupStatusTableHTML += $Entry
  }

  $HTMLBody = $HTMLBody -replace "\[\[OverallStartTime\]\]",  "$OverallStartTime"
  $HTMLBody = $HTMLBody -replace "\[\[OverallEndTime\]\]",    "$OverallEndTime"
  $HTMLBody = $HTMLBody -replace "\[\[BackupStatusTable\]\]", "$BackupStatusTableHTML"

  $secpasswd = ConvertTo-SecureString $SMTPPasswd -AsPlainText -Force
  $mycreds   = New-Object System.Management.Automation.PSCredential ($SMTPUser, $secpasswd)

  $MailSplat = @{
    To         = $EmailTo
    From       = $EmailFrom
    Subject    = $EmailSubject
    Body       = $HTMLBody
    BodyAsHTML = $true
    SMTPServer = $SMTPServer
    Port       = $SMTPPort
    Credential = $mycreds
  }

  Send-MailMessage @MailSplat -UseSsl
}