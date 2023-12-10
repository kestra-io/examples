FROM rust:1.67 as builder
LABEL org.opencontainers.image.source=https://github.com/kestra-io/examples
LABEL org.opencontainers.image.description="Image with a toy example running ETL process in Rust"
WORKDIR /usr/src/etl
COPY . .
RUN cargo install --path .
CMD ["etl"]