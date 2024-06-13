FROM python:3.11-slim
LABEL org.opencontainers.image.source=https://github.com/kestra-io/plugin-dbt
LABEL org.opencontainers.image.description="Image with the latest dbt-core Python package including the DuckDB adapter."
RUN pip install --no-cache-dir kestra dbt-duckdb 
