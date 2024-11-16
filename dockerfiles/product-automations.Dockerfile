FROM python:3.11-slim
LABEL org.opencontainers.image.source=https://github.com/kestra-io/examples
LABEL org.opencontainers.image.description="Image for the Product Automations"
RUN pip install --no-cache-dir uv requests kestra markdown2 beautifulsoup4 ruamel.yaml --no-warn-script-location