$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"
if ($env:SCRIPT_DEBUG -ne "") {
  $VerbosePreference = "Continue"
}
# Don't show download progress because invoke-webrequest is slowed down by that. https://stackoverflow.com/a/43477248
$global:ProgressPreference = "SilentlyContinue"
Set-StrictMode -Version latest

# Create a directory to upload install artifacts.
# The file provisioner does not do this for us.
# This directory is removed below after reboot.
New-Item -Type Directory -Path "${env:EF_INSTALL_TEMP_DIR}"

# Enable developer mode. This is needed so that the worker service can create symbolic links.
# Adapted from https://learn.microsoft.com/en-us/windows/apps/get-started/developer-mode-features-and-debugging#use-powershell-to-enable-your-device
New-ItemProperty `
    -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" `
    -Name "AllowDevelopmentWithoutDevLicense" `
    -Value 1 `
    -PropertyType DWORD `
    -Force
