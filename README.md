#🛡️ VMware VeeamZIP Automation Script

This PowerShell script automates VeeamZIP backups for VMware vSphere virtual machines, including retention cleanup and HTML email reporting.
It is designed for Veeam Backup & Replication (Community / Enterprise) environments using VMware PowerCLI.

✨ Features

🔌 Connects to vCenter or standalone ESXi

📋 Dynamically pulls VM names from vSphere

🚫 Excludes system VMs (e.g. vCLS-*)

💾 Creates VeeamZIP backups for each VM

🗂️ Timestamped backup directories

♻️ Automatic retention cleanup (age-based + keep newest)

📝 Updates VM Notes with last backup info

📧 Sends a styled HTML email report

🧠 Timezone-aware logging and reporting

🧩 How It Works

Loads VMware PowerCLI modules

Runs a helper script to export VM names

Connects to vCenter or ESXi

Reads VM names from the output file

Creates a timestamped backup directory

Deletes old backup folders based on retention rules

Runs VeeamZIP backups for each VM

Tracks success / warning / failure status

Updates VM notes with backup metadata

Builds and sends an HTML email report

📂 Output Structure
C:\Backups\
 ├─ 2025-01-10_143012\
 │   ├─ VM01.vbk
 │   ├─ VM02.vbk
 ├─ 2025-01-09_140955\
 └─ 2025-01-08_135201\


Old folders are automatically deleted based on retention settings.

⚙️ Requirements

Windows PowerShell 5.1+

VMware PowerCLI

Veeam Backup & Replication installed

vCenter or ESXi access

SMTP access (Gmail supported via App Password)

📦 Installation
Install-Module VMware.PowerCLI -Scope CurrentUser


Ensure Veeam PowerShell components are installed and accessible.

🔧 Configuration

Update the following variables before running:

VMware / Veeam
$VIServer   = "vcenter.domain.local"
$VIUsername = "veeam@yourdomain.com"
$VIPassword = "yourpassword"

Backup Location
$BaseDirectory = "C:\Path\To\Your\Save_Directory"

Retention Policy
$RetentionDays = 2
$KeepCount     = 3

Email Settings
$SMTPServer = "smtp.gmail.com"
$SMTPPort   = 587
$SMTPUser   = "yourgmail@gmail.com"
$SMTPPasswd = "gmail_app_password"

📧 Email Report

The email report includes:

Backup start and end time

Per-VM backup status:

✅ Success

⚠️ Warning

❌ Failed

🚫 Not Found

Styled HTML table (template-driven)

You can customize the appearance using the BackupEmail.html template.

📝 VM Notes Example

Each VM is updated with notes similar to:

Last Backup: [01/10/2025 02:43:12 PM]
by [BNC-VMBK-PRD-01]
saved to [BNC-NAS-PRD-02]

🔐 Security Notes

⚠️ Do not hardcode passwords in production environments.

Recommended alternatives:

Get-Credential

Windows Credential Manager

Secure vault solutions

🚀 Use Cases

Small environments using Veeam Community Edition

Supplemental or on-demand backups

Lightweight disaster recovery

Lab, MSP, or edge environments

Audit or compliance backups

📜 License

Use freely. Modify responsibly.
No warranties — test before production use.
