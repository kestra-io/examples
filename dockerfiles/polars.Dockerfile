FROM python:3.10
LABEL org.opencontainers.image.source=https://github.com/kestra-io/examples
LABEL org.opencontainers.image.description="Image with the latest Polars package and all its extensions"
RUN pip install --upgrade pip
RUN pip install --no-cache-dir uv kestra requests "polars[sqlalchemy,adbc]" loguru amazon-ion faker
