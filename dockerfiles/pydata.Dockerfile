FROM python:3.11
LABEL org.opencontainers.image.source=https://github.com/kestra-io/examples
LABEL org.opencontainers.image.description="Image with the latest pandas, requests and scikit-learn Python packages"
RUN pip install --no-cache-dir kestra pandas requests scikit-learn faker pyarrow sqlalchemy