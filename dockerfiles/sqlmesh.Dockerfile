FROM python:3.11-slim
LABEL org.opencontainers.image.source=https://github.com/kestra-io/examples
LABEL org.opencontainers.image.description="Image with the latest SQLMesh package and related extensions"
RUN pip install --upgrade pip
RUN pip install --no-cache-dir uv kestra loguru amazon-ion sqlmesh
RUN pip install --no-cache-dir "sqlmesh[dbt,bigquery,snowflake]"
