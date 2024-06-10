FROM alpine:latest

# Install GitHub CLI
RUN apk update && \
    apk add --no-cache curl git less && \
    apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community github-cli

# Verify installation
RUN gh --version
CMD ["sh"]
