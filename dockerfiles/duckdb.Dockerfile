FROM python:3.11-slim
LABEL org.opencontainers.image.source=https://github.com/kestra-io/examples
LABEL org.opencontainers.image.description="Image with DuckDB 0.8.1, requests, PyArrow and Pandas Python packages"
RUN pip install --no-cache-dir kestra requests faker pyarrow pandas duckdb==0.8.1