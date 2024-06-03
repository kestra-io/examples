FROM mcr.microsoft.com/powershell:7.2.0-ubuntu-20.04

RUN apt-get update && \
    apt-get install -y openssh-client

pwsh -Command "Install-Module -Name PSWSMan -Force"
pwsh -Command "Install-WSMan"
