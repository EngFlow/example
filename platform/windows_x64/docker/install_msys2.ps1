$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"
if ($env:SCRIPT_DEBUG -ne "") {
  $VerbosePreference = "Continue"
}
# Don't show download progress because invoke-webrequest is slowed down by that. https://stackoverflow.com/a/43477248
$global:ProgressPreference = "SilentlyContinue"
Set-StrictMode -Version latest

# This script downloads and installs msys2, along with a number of C/C++
# toolchains it provides. We need it for:
# - Actions that use bash via ctx.actions.run_shell.
# - Bazel's test wrapper bash script (when run from non-Windows host).
# - genrules (when run from non-Windows host or without cmd_ps).
# - Builds where we want an open source C/C++ toolchain.

# Download the installer.
# We use the nightly self-extracting installer instead of the regularly released
# graphical installer.
#
# - The graphical installer depends on DLLs that are not in the servercore
#   base container image, so it won't start.
# - The official release self-extracting installer seems to trigger a
#   Docker / Go bug on Windows: docker hangs after executing the last
#   instruction in the Dockerfile.
#   https://github.com/microsoft/hcsshim/issues/696
#
# We don't bother mirroring this installer because the .sfx.exe file at the URL
# changes every couple days. We're about to install the latest version of
# a bunch of packages with pacman anyway, so we've already lost. pacman provides
# little control for installing specific package versions.
Write-Verbose "Download msys2"
Invoke-WebRequest `
  -Uri 'https://github.com/msys2/msys2-installer/releases/download/nightly-x86_64/msys2-base-x86_64-latest.sfx.exe' `
  -OutFile "${env:EF_INSTALL_TEMP_DIR}/msys2-base-x86_64-latest.sfx.exe"

# Run the installer. It's a self-extracting archive. It extracts to .\msys64.
#   -y     skip prompts
#   -oC:\  write to C:\ instead of working directory
Write-Verbose "Extract msys2"
& "${env:EF_INSTALL_TEMP_DIR}/msys2-base-x86_64-latest.sfx.exe" -y -oC:\

# Add msys2 to PATH.
$env:PATH = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
$env:PATH = "$env:PATH;C:\msys64\usr\bin"
[Environment]::SetEnvironmentVariable('PATH', $env:PATH, 'Machine')

# Install C/C++ toolchains.
# See https://www.msys2.org/docs/environments/.
#
# - gcc: Bazel auto-configures this as msys-gcc.
#   Installed in C:\msys64\usr\bin. Uses the cygwin C runtime.
#   Useful for GNU compatibility and simple configuration.
# - mingw-w64-x86_64-gcc: Bazel auto-configures this as mingw-gcc.
#   Installed in C:\msys64\mingw64\usr\bin. Uses the MSVCRT runtime.
#   rules_foreign_cc needs this in some cases for GNU compatibility.
# - mingw-w64-ucrt-x86_64-gcc: A GCC toolchain.
#   Installed in C:\msys64\ucrt64\usr\bin, uses UCRT64.
#   Should be compatible with libraries built with MSVC linked against UCRT64.
#   We need to configure our own toolchains for this.
# - mingw-w64-ucrt-x86_64-clang: A clang toolchain.
#   Installed in C:\msys64\ucrt64\usr\bin, uses UCRT64.
#   Should be compatible with libraries built with MSVC linked against UCRT64.
#   We need to configure our own toolchains for this.
#
# NOTE: we invoke pacman via bash. It seems to depend on the environment
# to initialize gnupg correctly and to not trigger the Docker bug
# https://github.com/microsoft/hcsshim/issues/696.
#
# bash -l: run a login shell, evaluting startup files.
# bash -c: run a command.
#
# pacman --sync: install packages, analogous to apt-get.
# pacman --refresh: download latest package metadata.
# pacman --sysupgrade: upgrade installed packages.
# pacman --needed: do not reinstall up-to-date packages.
Write-Verbose "Install msys2 C/C++ toolchains"
bash -l -c "pacman --sync --refresh --sysupgrade --needed --noconfirm --noprogressbar"
bash -l -c "pacman --sync --needed --noconfirm --noprogressbar gcc mingw-w64-x86_64-gcc mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-clang"

# Clean up temporary files created by pacman.
# This may be needed to avoid triggering the Docker bug 
# https://github.com/microsoft/hcsshim/issues/696.
# We don't want these files in the image anyway.
bash -l -c "rm -rf /C/Users/ContainerUser/* /var/cache/pacman/pkg/*"
