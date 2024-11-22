# Data Orchestration with Kestra

This repository will:
1. Help you **get started** with Kestra
2. Provide examples of how to **use Kestra**
3. Provide examples of how to **integrate** Kestra with Infrastructure as Code tools (Terraform, GitHub Actions), Modern Data Stack products, and public cloud provider services
4. Share **best practices** for managing data workflows across environments so that moving from development to production is as easy as possible without sacrificing security or reliability

## Video tutorials

- Getting started video explaining key concepts: https://youtu.be/yuV_rgnpXU8
- Managing development and production environments in Kestra: https://youtu.be/tiHa3zucS_Q

---

# How to install Kestra

Download the Docker Compose file:

```sh
curl -o docker-compose.yml https://raw.githubusercontent.com/kestra-io/kestra/develop/docker-compose.yml
```

Start Kestra:

```sh
docker-compose up
```

![install.png](images/install.png)

---

# Hello-World example

Here is a simple example logging hello world message to the terminal:

```yaml
id: hello  
namespace: prod
tasks:
  - id: hello-world
    type: io.kestra.plugin.core.log.Log
    message: Hello world!
```

## Adding a schedule

Here is how you can add a schedule trigger to run the flow every minute: [helloParametrizedScheduled.yml](flows/getting_started/helloParametrizedScheduled.yml)

To add multiple schedules, each running with different input parameter values, use [helloParametrizedMultipleSchedules.yml](flows/getting_started/helloParametrizedSchedulesMultiple.yml)

---

# How to integrate Kestra with other tools in the Modern Data Stack 

## Airbyte

Here is an example of using Kestra with Airbyte running in other Docker container: [airbyteSync.yml](flows/airbyte/airbyteSync.yml)

And example running multiple Airbyte syncs in parallel: [airbyteSyncParallel.yml](flows/airbyte/airbyteSyncParallel.yml) 

## Fivetran

Here is an example of a flow with a single task triggering a Fivetran sync: [fivetranSync.yml](flows/fivetran/fivetranSync.yml)

---


# Custom Scripts

## How to run Bash and Python tasks

Here is an example of a Bash task: [csvKit](flows/python/csvKit.yml)


### Custom Docker image per task 

If you prefer to run the Python or Bash task in a (_potentially custom_) Docker container: [pythonScriptContainer](flows/python/pythonScriptContainer.yml)

Using `dockerOptions` with the `dockerConfig` attribute, you can also configure credentials to private Docker registries:

`auths: { "my.registry.com" : { auth: "token" } }`


### Docker image with `requirements.txt` built at runtime 


```yaml
id: hello_python_docker
namespace: company.team
tasks:
  - id: python_container
    type: io.kestra.plugin.scripts.python.Script
    beforeCommands:
      - pip install requests pandas
    taskRunner:
      type: io.kestra.plugin.scripts.runner.docker.Docker
    containerImage: python:3.11-slim
    script: |
      import pandas as pd
      import requests
      
      print(pd.__version__)
      print(requests.__version__)
```


## Keyboard shortcuts for the built-in editor in the UI

On Mac:
- fn + control + Space = Autocomplete
- command + K + C = Comment
- command + K + U = Uncomment
- opt + up/down = Move line up/down

On Windows:
- ctrl + space = Autocomplete
- ctrl + K + C = Comment
- ctrl + K + U = Uncomment
- alt + up/down = Move line up/down

---

# Credentials management

## Open-source Kestra

In the open-source version, you can leverage Secrets.

Create an `.env` file and add any environment variables there with the prefix `SECRET_`, as shown in the [.env_example](.env_example) file. The values are the passwords in the base64 encoded format.

Then, you can reference the secrets in your flow using `{{ secret('AIRBYTE_PASSWORD') }}`. Note that we drop the `SECRET_` prefix while referencing the secrets.

For security reasons, environment variables are fixed at the application startup (JVM startup).

Also, make sure that your Kestra container contains this configuration in your [docker-compose.yml](docker-compose.yml) file:

```yaml
  kestra:
    image: kestra/kestra:develop-full
    ...
    env_file:
      - .env
    environment:
      KESTRA_CONFIGURATION: |
        kestra:
          ...
```

## Cloud & Eneterprise Edition

Cloud & Enterprise Editions have a dedicated credentials managers with extra encryption, namespace-bound credential inheritance hierarchy and an RBAC-setting behind it.

You can add a Secret in the relevant namespace from the Namespace tab in the UI. You should not add the `SECRET_` prefix while setting up the secrets via the Namespace tab.

To reference that secret in your flow, use `{{ secret('AWS_ACCESS_KEY_ID') }}`.
