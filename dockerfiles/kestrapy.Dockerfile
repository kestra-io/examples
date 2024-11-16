FROM python:3.11-alpine
LABEL org.opencontainers.image.source=https://github.com/kestra-io/examples
LABEL org.opencontainers.image.description="Image with the latest Kestra Python package and loguru logger"
RUN pip install --no-cache-dir uv kestra loguru amazon-ion
