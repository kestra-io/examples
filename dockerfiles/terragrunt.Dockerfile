FROM hashicorp/terraform:light

RUN apk add --no-cache \
    curl \
    bash \
    jq \
    git

RUN LATEST_VERSION=$(curl --silent "https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest" | jq -r '.tag_name') && \
    curl -L -o /usr/local/bin/terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/${LATEST_VERSION}/terragrunt_linux_amd64 && \
    chmod +x /usr/local/bin/terragrunt

ENTRYPOINT ["/bin/bash"]
