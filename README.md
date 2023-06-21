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
    type: io.kestra.core.tasks.log.Log
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
id: hello-python-docker
namespace: prod
tasks:
  - id: python-container
    type: io.kestra.core.tasks.scripts.Python
    inputFiles:
      main.py: |
        import pandas as pd
        import requests
        
        print(pd.__version__)
        print(requests.__version__)
    requirements:
      - requests
      - pandas
    runner: DOCKER
    dockerOptions:
      image: python:3.11-slim
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

In the open-source version, you can leverage environment variables. 
Create an `.env` file and add any environment variables there, as shown in the [.env_example](.env_example) file.

Then, you can reference that environment variable in your flow using ``{{envs.aws_access_key_id}}``. 

For security reasons, environment variables are fixed at the application startup (JVM startup).

Note that the reference must be **lowercase**:
- ``{{envs.aws_access_key_id}}`` is correct ✅ 
- ``{{envs.AWS_ACCESS_KEY_ID}}`` is NOT correct ❌ because it must be referenced in lowercase, even though the ``.env`` file contains the variable in uppercase ``AWS_ACCESS_KEY_ID=xxx``

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
          variables:
            env-vars-prefix: ""
```

Setting `env-vars-prefix` to an empty string will allow you to reference environment variables without a prefix.

Without this settings, your AWS_ACCESS_KEY_ID environment variable would need to be prefixed with `KESTRA_` in the `.env` file: ``KESTRA_AWS_ACCESS_KEY_ID``.

## Cloud & Eneterprise Edition

Cloud & Enterprise Editions have a dedicated credentials managers with extra encryption, namespace-bound credential inheritance hierarchy and an RBAC-setting behind it.

You can add a Secret in the relevant namespace from the namespace tab in the UI. To reference that secret in your flow, use ``{{secret('AWS_ACCESS_KEY_ID')}}`` instead of ``{{envs.aws_access_key_id}}``.  

