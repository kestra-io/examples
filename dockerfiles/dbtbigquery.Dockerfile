FROM python:3.11-slim
LABEL org.opencontainers.image.source https://github.com/kestra-io/examples
RUN pip install --no-cache-dir dbt-bigquery
