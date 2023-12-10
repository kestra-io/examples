docker build -t rustetl .
docker run -it --rm --name my-rust-etl rustetl
docker tag rustetl:latest ghcr.io/kestra-io/rust:latest
docker push ghcr.io/kestra-io/rust:latest