FROM mcr.microsoft.com/windows/servercore:ltsc2022 AS download
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ENV EF_INSTALL_TEMP_DIR="C:\\engflow_install_temp"
ENV SCRIPT_DEBUG="on"

COPY "normalize_os_windows.ps1" "C:/normalize_os_windows.ps1"
RUN "C:/normalize_os_windows.ps1"
RUN "Remove-Item C:/normalize_os_windows.ps1"

COPY "install_vs_build_tools.ps1" "${EF_INSTALL_TEMP_DIR}"
RUN "& \"${env:EF_INSTALL_TEMP_DIR}/install_vs_build_tools.ps1\""

COPY "install_msys2.ps1" "${EF_INSTALL_TEMP_DIR}"
RUN "& \"${env:EF_INSTALL_TEMP_DIR}/install_msys2.ps1\""

COPY "install_jre.ps1" "${EF_INSTALL_TEMP_DIR}"
RUN "& \"${env:EF_INSTALL_TEMP_DIR}/install_jre.ps1\""

COPY "install_python.ps1" "${EF_INSTALL_TEMP_DIR}"
RUN "& \"${env:EF_INSTALL_TEMP_DIR}/install_python.ps1\""

COPY ["msvc_filter_showincludes.exe", "C:/Program Files/engflow/bin/msvc_filter_showincludes.exe"]

RUN "Remove-Item -Recurse ${env:EF_INSTALL_TEMP_DIR}"
ENV EF_INSTALL_TEMP_DIR=

USER ContainerUser

CMD ["powershell"]
