FROM hashicorp/terraform:light

RUN apk add --no-cache \
    curl \
    bash \
    git

# Install Terragrunt
RUN curl -L -o /usr/local/bin/terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/v0.59.2/terragrunt_linux_amd64 && \
    chmod +x /usr/local/bin/terragrunt

ENTRYPOINT ["/bin/bash"]
