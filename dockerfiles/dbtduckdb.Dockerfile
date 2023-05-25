# docker build -f dockerfiles/dbtduckdb.Dockerfile -t dbtduckdb . --platform linux/amd64
FROM python:3.10-slim
RUN pip install --no-cache-dir dbt-duckdb==1.4.1
