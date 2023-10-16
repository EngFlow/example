$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"
if ($env:SCRIPT_DEBUG -ne "") {
  $VerbosePreference = "Continue"
}
# Don't show download progress because invoke-webrequest is slowed down by that. https://stackoverflow.com/a/43477248
$global:ProgressPreference = "SilentlyContinue"
Set-StrictMode -Version latest

# Install Python, needed to run py_test.
# Watch https://www.python.org/downloads/windows/ for new releases.
# Installer command line reference: https://docs.python.org/3.11/using/windows.html
Write-Verbose "Installing Python..."
Invoke-WebRequest `
  -Uri "https://storage.googleapis.com/engflow-tools-public/python-3.11.4-amd64.exe" `
  -OutFile "${env:EF_INSTALL_TEMP_DIR}\python-3.11.4-amd64.exe"

$process = Start-Process `
  "${env:EF_INSTALL_TEMP_DIR}\python-3.11.4-amd64.exe" `
  -PassThru `
  -Wait `
  -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0"
$exitCode = $process.ExitCode
if ($exitCode -ne 0) {
  Write-Error "python-3.11.4-amd64.exe failed with exit code ${exitCode}"
}
$env:PATH = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
$env:PATH = "$env:PATH;C:\Program Files\Python311"
[Environment]::SetEnvironmentVariable('PATH', $env:PATH, 'Machine')
