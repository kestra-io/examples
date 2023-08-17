FROM python:3.11
LABEL org.opencontainers.image.source=https://github.com/kestra-io/plugin-dbt	
LABEL org.opencontainers.image.description="Image with the latest dbt-terradata Python package"	
RUN pip install --upgrade pip
RUN pip install --no-cache-dir kestra dbt-terradata