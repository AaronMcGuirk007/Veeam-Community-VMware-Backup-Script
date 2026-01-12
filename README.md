# 🛡️ VMware VeeamZIP Automation Script

This PowerShell script automates **VeeamZIP backups** for VMware vSphere virtual machines, including **retention cleanup** and **HTML email reporting**, and **adding notes timestamps** to VMs for improved logging.

Designed for **Veeam Backup & Replication (Community Edition)** environments using **VMware PowerCLI**.

---

## ✨ Features

- 🔌 Connects to **vCenter** or **standalone ESXi**
- 📋 Dynamically pulls VM names from your VMware server
- 🚫 Excludes system VMs (e.g. `vCLS-*`)
- 💾 Creates **VeeamZIP backups** for each VM
- 🗂️ Timestamped backup directories
- ♻️ Automatic retention cleanup  
  - Age-based deletion  
  - Keep newest backups
- 📝 Updates **VM Notes** with last backup info
- 📧 Sends a styled **HTML email report**
- 🧠 Timezone-aware logging and reporting

---

## 🧩 How It Works

Before the script executes, it is triggered automatically by **Windows Task Scheduler**, allowing fully unattended operation.

### 🕒 Scheduled Execution

- The script is configured as a **Scheduled Task** on a Windows Server
- Runs automatically every **12 or 24 hours**
- Executes under a service or backup account with:
  - VMware access
  - Veeam permissions
  - Network access to the backup target
- No user interaction required once configured

### ▶️ Script Execution Flow

1. Loads VMware PowerCLI modules  
2. Runs a helper script to export VM names  
3. Connects to vCenter or ESXi  
4. Reads VM names from the output file  
5. Creates a timestamped backup directory  
6. Deletes old backup folders based on retention rules  
7. Runs VeeamZIP backups for each VM  
8. Tracks per-VM status:
   - ✅ Success  
   - ⚠️ Warning  
   - ❌ Failure  
9. Updates VM notes with backup metadata  
10. Builds and sends an HTML email report  
---

## 📂 Output Structure

```text
C:\Backups
├─ 2025-01-10_143012
│  ├─ VM01.vbk
│  ├─ VM02.vbk
├─ 2025-01-09_140955
└─ 2025-01-08_135201
```

Old folders are automatically deleted based on retention settings.

## ⚙️ Requirements

- Windows Server 2019 or newer

- Veeam Community Edition or Enterprise

- Windows PowerShell 5.1+

- VMware PowerCLI

- Veeam Backup & Replication installed

- vCenter or ESXi access

- Google SMTP access

- Gmail supported via App Password

## 📦 Installation

## Install VMware PowerCLI:

```text
Install-Module VMware.PowerCLI -Scope CurrentUser
```


Ensure Veeam PowerShell components are installed and accessible on the system.

## 🔧 Configuration
- ⚠️ Update the following variables before running the script
- 🖥️ VMware / Veeam Connection
```text
$VIServer   = "vcenter.domain.local"
$VIUsername = "veeam@yourdomain.com"
$VIPassword = "yourpassword"
```

## 💾 Backup Location
```text
$BaseDirectory = "C:\Path\To\Your\Save_Directory"
```

## ♻️ Retention Policy
```text
$RetentionDays = 2
$KeepCount     = 3
```

## 📧 Email Settings
```text
$SMTPServer = "smtp.gmail.com"
$SMTPPort   = 587
$SMTPUser   = "yourgmail@gmail.com"
$SMTPPasswd = "gmail_app_password"
```

## 📧 Email Report

The email report includes:

- Backup start and end time

- Per-VM backup status:
  - ✅ Success

  - ⚠️ Warning

  - ❌ Failed

  - 🚫 Not Found

Styled HTML table (template-driven)

🎨 You can customize the appearance using the BackupEmail.html template.

## 📝 VM Notes Example

Each VM is updated with notes similar to:

```text
Last Backup: [01/10/2025 02:43:12 PM] 
by [BNC-VMBK-PRD-01] 
saved to [BNC-NAS-PRD-02]
```

## 🔐 Security Notes

## ⚠️ Do NOT hardcode passwords in production environments.

Recommended alternatives:

```text
Get-Credential

Windows Credential Manager

Secure vault solutions (CyberArk, Azure Key Vault, etc.)
```

## 🚀 Use Cases

- Small environments using Veeam Community Edition

- Supplemental or on-demand backups

- Lightweight disaster recovery

- Lab, MSP, or edge environments

- Audit or compliance backups

## 📜 License

Use freely.
Modify responsibly.
No warranties — test before production use.
