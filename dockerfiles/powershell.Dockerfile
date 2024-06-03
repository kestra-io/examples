FROM mcr.microsoft.com/powershell:7.2.0-ubuntu-20.04

RUN apt-get update && \
    apt-get install -y openssh-client

RUN pwsh -Command "Install-Module -Name PSWSMan -Force"
RUN pwsh -Command "Install-WSMan"
