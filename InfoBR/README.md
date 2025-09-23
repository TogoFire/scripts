# 🛠️ Scripts and Executables for InfoBR

Automating system configuration and updates.

---

## Overview

Ready-to-use scripts and executables that simplify setup and updates for InfoRetaguarda and InfoPDV systems.

---

## Main Content

* `InfoUp.bat`: A robust Batch script that automates the following tasks:
    * Checks for and installs **Chocolatey** (package manager) if necessary.
    * Installs essential tools like **7-Zip**, Curl, Notepad++, and Fastfetch via Chocolatey.
    * **Downloads and places** the `InfoUp.exe` executable (the main update tool) in `C:\Infobrasil`.
    * **Updates Info**, Downloads and installs updates for InfoRetaguarda and InfoPDV. It handles program shutdowns and extracts files, attempting a password (infobrasil) only when necessary.
    * **Schedules a Windows task** to execute `InfoUp.exe` periodically, ensuring systems remain updated.

* `InfoUp.exe`: The main update executable, referenced and used by the `InfoUp.bat` script.

---

## Integrity Verification (MD5SUM)

To ensure the integrity of the downloaded `InfoUp.exe`, you can verify its MD5SUM:

`9CC024BB141D35094A1926EB2440DC43 InfoUp.exe`

You can verify this using PowerShell:
```
$expectedHash = "9CC024BB141D35094A1926EB2440DC43"; $actualHash = (Get-FileHash -Path "C:\Infobrasil\InfoUp.exe" -Algorithm MD5).Hash; if ($actualHash -eq $expectedHash) { Write-Host "MD5 hash matches: File integrity verified. ✅" -ForegroundColor Green } else { Write-Host "MD5 hash DOES NOT match! File may be corrupted or tampered with. ⚠️ Expected: $expectedHash Actual: $actualHash" -ForegroundColor Red }
```

---

## How to Use (Recommended)

### For Windows PowerShell 5.1 or greater 💻

Use the command below to download and execute the `InfoUp.bat` script directly. This command will prompt for **administrator privileges**, which are **mandatory** for the script to function correctly.

```powershell
$url = "https://raw.githubusercontent.com/TogoFire/scripts/infobr/InfoBR/InfoUp.bat"; $outputPath = "$env:TEMP\InfoUp.bat"; Invoke-WebRequest -Uri $url -OutFile $outputPath; Start-Process -FilePath $outputPath -Verb RunAs
```

---

## Managing the Scheduled Task

After running `InfoUp.bat`, a scheduled task named **"InfoSystemsUpdater"** is created.
Note: By default, it updates on the first day of every month.

* **Verify Details:**
    ```cmd
    schtasks /query /tn "InfoSystemsUpdater" /v /fo LIST
    ```
* **Remove Task:**
    ```cmd
    schtasks /delete /tn "InfoSystemsUpdater" /f
    ```
