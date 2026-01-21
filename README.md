# Kestra Examples

This repository will help you **get started** with Kestra

For example use-cases, check out [Blueprints](https://kestra.io/blueprints)

## How to install Kestra

Download the Docker Compose file:

```sh
curl -o docker-compose.yml https://raw.githubusercontent.com/kestra-io/kestra/develop/docker-compose.yml
```

Start Kestra:

```sh
docker compose up
```

![install.png](images/install.png)

---

## Hello World example

Here is a simple example logging hello world message to the terminal:

```yaml
id: myflow
namespace: company.team

tasks:
  - id: hello_world
    type: io.kestra.plugin.core.log.Log
    message: Hello, World!
```

---

## Cloud & Eneterprise Edition

Cloud & Enterprise Editions have a dedicated credentials managers with extra encryption, namespace-bound credential inheritance hierarchy and an RBAC-setting behind it.

You can add a Secret in the relevant namespace from the Namespace tab in the UI. You should not add the `SECRET_` prefix while setting up the secrets via the Namespace tab.

To reference that secret in your flow, use `{{ secret('AWS_ACCESS_KEY_ID') }}`.
