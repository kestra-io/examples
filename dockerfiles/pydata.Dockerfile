FROM python:3.11-slim
LABEL org.opencontainers.image.source=https://github.com/kestra-io/examples
LABEL org.opencontainers.image.description="Image with the latest Python packages including pandas, requests, scikit-learn, faker, pyarrow, sqlalchemy, openai"
RUN pip install --no-cache-dir kestra pandas requests scikit-learn faker pyarrow sqlalchemy openai