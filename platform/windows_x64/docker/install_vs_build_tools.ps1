$ErrorActionPreference = "Stop"
if ($env:SCRIPT_DEBUG -ne "") {
  $VerbosePreference = "continue"
}
$InformationPreference = "Continue"
# Don't show download progress because invoke-webrequest is slowed down by that. https://stackoverflow.com/a/43477248
$global:ProgressPreference = "SilentlyContinue"

Write-Verbose "Installing VS Buildtools (needed for Bazel)..."
Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vs_buildtools.exe" -OutFile "c:/vs_buildtools.exe"
$installArgs = @(
  '--quiet',
  '--wait',
  '--add',
  'Microsoft.VisualStudio.Workload.VCTools',
  '--add',
  'Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
  '--add',
  'Microsoft.VisualStudio.Component.Windows10SDK.19041',
  '--includeRecommended',
  '--remove',
  'Microsoft.VisualStudio.Component.Windows10SDK.10240',
  '--remove',
  'Microsoft.VisualStudio.Component.Windows10SDK.10586',
  '--remove',
  'Microsoft.VisualStudio.Component.Windows10SDK.14393',
  '--remove',
  'Microsoft.VisualStudio.Component.Windows81SDK'
)
Start-Process c:/vs_buildtools.exe -Wait -ArgumentList ($installArgs -join ' ')
Remove-Item "c:/vs_buildtools.exe" -Force