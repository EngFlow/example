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

