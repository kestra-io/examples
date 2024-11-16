FROM python:3.11-slim
LABEL org.opencontainers.image.source=https://github.com/kestra-io/examples
LABEL org.opencontainers.image.description="Image with the latest modal-client Python package"
RUN pip install --no-cache-dir uv kestra modal loguru amazon-ion
