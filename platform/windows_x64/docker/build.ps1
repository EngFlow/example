$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"
if ($env:SCRIPT_DEBUG -ne "") {
  $VerbosePreference = "Continue"
}
$global:ProgressPreference = "SilentlyContinue"
Set-StrictMode -Version latest

# This script builds a Docker container image for EngFlow workers.
# It contains everything needed by remote actions in our repository.
# Nearly all of the logic is in either Dockerfile or a handful of
# scripts it calls that are shared with other image builds. This script
# just puts Dockerfile together with those scripts in a temporary directory,
# then invokes 'docker build'.

# Verify that this script was run from the repository root.
if (-not (Test-Path "platform/windows_x64/docker/build.ps1" -Type Leaf) -or -not (Test-Path "WORKSPACE" -Type Leaf)) {
  Write-Error "Run this script from the repository root directory."
}

# Create a temporary directory and copy files there.
$repoRootDir = Get-Location
Write-Verbose "repoRootDir $repoRootDir"
$buildDir = "${repoRootDir}/_build"
Write-Verbose "Copying files to ${buildDir}..."
New-Item -Type 'directory' -Path $buildDir
trap {
  Set-Location $repoRootDir
  Remove-Item -Recurse -Force $buildDir
}
Copy-Item 'platform/windows_x64/docker/normalize_os_windows.ps1' $buildDir
Copy-Item 'platform/windows_x64/docker/install_jre.ps1' $buildDir
Copy-Item 'platform/windows_x64/docker/install_msys2.ps1' $buildDir
Copy-Item 'platform/windows_x64/docker/install_python.ps1' $buildDir
Copy-Item 'platform/windows_x64/docker/install_vs_build_tools.ps1' $buildDir
Copy-Item 'platform/windows_x64/docker/Dockerfile' $buildDir

# Build the showincludes wrapper binary.
# TODO(CUS-81): Remove this after
# https://github.com/bazelbuild/bazel/issues/19733 is fixed, and we're upgraded
# to a version of Bazel that has the fix.
bazel build //infra/msvc_filter_showincludes
Copy-Item 'bazel-bin/infra/msvc_filter_showincludes/msvc_filter_showincludes_/msvc_filter_showincludes.exe' $buildDir

# Build the Docker image.
#
# Additional memory is needed to install VS build tools. The default 1GB
# is not enough.
#
# Additional storage space is needed, too: the default 20GB is not enough.
# Configure C:\ProgramData\docker\config\daemon.json with:
#
#     "storage-opts": [
#       "size=50G"
#     ]
Write-Verbose "Building docker image..."
Set-Location $buildDir
docker build `
  --tag engflow-container-image `
  --memory '4GB' `
  .
Set-Location $repoRootDir

# Remove the temporary directory on success.
Remove-Item -Recurse -Force $buildDir
