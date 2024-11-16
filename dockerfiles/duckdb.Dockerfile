FROM python:3.11-slim
LABEL org.opencontainers.image.source=https://github.com/kestra-io/examples
LABEL org.opencontainers.image.description="Image with DuckDB, requests, PyArrow and Pandas Python packages"
RUN pip install --no-cache-dir uv kestra requests faker pyarrow pandas duckdb loguru amazon-ion
RUN pip install --no-cache-dir faker
