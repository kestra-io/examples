FROM python:3.11-slim
LABEL org.opencontainers.image.source=https://github.com/kestra-io/examples
LABEL org.opencontainers.image.description="Image with the latest dbt-core Python package including all officially supported adapters."
RUN pip install --no-cache-dir kestra dbt-bigquery 
RUN pip install --no-cache-dir dbt-snowflake 
RUN pip install --no-cache-dir dbt-redshift
RUN pip install --no-cache-dir dbt-postgres
RUN pip install --no-cache-dir dbt-spark
RUN pip install --no-cache-dir dbt-databricks
RUN pip install --no-cache-dir dbt-dremio
RUN pip install --no-cache-dir dbt-trino
RUN pip install --no-cache-dir dbt-duckdb
RUN pip install --no-cache-dir dbt-fabric
RUN pip install --no-cache-dir dbt-synapse
RUN pip install --no-cache-dir dbt-teradata