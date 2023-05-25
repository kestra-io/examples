# docker build -f dockerfiles/modal.Dockerfile -t modal .
FROM python:3.11-slim
RUN pip install --no-cache-dir modal-client
