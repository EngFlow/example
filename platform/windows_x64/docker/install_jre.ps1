$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"
if ($env:SCRIPT_DEBUG -ne "") {
  $VerbosePreference = "Continue"
}
# Don't show download progress because invoke-webrequest is slowed down by that. https://stackoverflow.com/a/43477248
$global:ProgressPreference = "SilentlyContinue"
Set-StrictMode -Version latest

# Install JRE. Needed to run the EngFlow worker binary.
Write-Verbose "Installing JRE..."
Invoke-WebRequest `
  -Uri 'https://storage.googleapis.com/engflow-tools-public/cdn.azul.com/zulu/bin/zulu17.44.53-ca-jre17.0.8.1-win_x64.zip' `
  -OutFile "${env:EF_INSTALL_TEMP_DIR}\zulu17.44.53-ca-jre17.0.8.1-win_x64.zip"
Expand-Archive `
  -Path "${env:EF_INSTALL_TEMP_DIR}\zulu17.44.53-ca-jre17.0.8.1-win_x64.zip" `
  -DestinationPath ${env:EF_INSTALL_TEMP_DIR}
Move-Item `
  -Path "${env:EF_INSTALL_TEMP_DIR}\zulu17.44.53-ca-jre17.0.8.1-win_x64" `
  -Destination 'C:\Program Files\Java'
$env:PATH = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
$env:PATH = "$env:PATH;C:\Program Files\Java\bin"
[Environment]::SetEnvironmentVariable('PATH', $env:PATH, 'Machine')
