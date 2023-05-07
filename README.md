# Data Orchestration with Kestra

This repository will:
1. Help you **get started** with Kestra
2. Provide examples of how to **use Kestra**
3. Provide examples of how to **integrate** Kestra with Infrastructure as Code tools (Terraform, GitHub Actions), Modern Data Stack products, and public cloud provider services
4. Share **best practices** for managing data workflows across environments so that moving from development to production is as easy as possible without sacrificing security or reliability

## Getting started video explaining key concepts

Link to the video: https://youtu.be/yuV_rgnpXU8

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

Here is a Hello-World example:

```yaml
id: hello  
namespace: dev
tasks:
  - id: hello-world
    type: io.kestra.core.tasks.log.Log
    message: Hello world!
```

## Adding a schedule

Here is an example of adding a schedule to the Hello-World example:

```yaml
id: hello-cron  
namespace: dev
tasks:
  - id: hello-world
    type: io.kestra.core.tasks.log.Log
    message: Hello world!
triggers:
  - id: every-minute
    type: io.kestra.core.models.triggers.types.Schedule
    cron: "*/1 * * * *"
```


---

# How to integrate Kestra with other tools in the Modern Data Stack 

## Airbyte

Here is an example of using Kestra with Airbyte running in other Docker container:

```yaml
id: airbyteSync
namespace: dev
tasks:
  - id: dataIngestionSyncAirbyte
    type: io.kestra.plugin.airbyte.connections.Sync
    connectionId: e3b1ce92-547c-436f-b1e8-23b6936c12ab
    url: http://host.docker.internal:8000/
    username: airbyte
    password: password
```

## Fivetran

Here is an example of a flow with a single task triggering a Fivetran sync:

```yaml
id: fivetranSync
namespace: dev
tasks:
  - id: dataIngestionSyncFivetran
    type: io.kestra.plugin.fivetran.connectors.Sync
    apiKey: "{{ envs.fivetran_api_key }}"
    apiSecret: "{{ envs.fivetran_api_secret }}"
    connectorId: vesicle_movement
```

---


# How to integrate Kestra with IaC: CI/CD with Terraform

To deploy your workflows to Kestra, you can use the Kestra Terraform provider. This allows you to follow Infrastructure as Code best practices in your data engineering lifecycle. 


## Deploying a single flow with Terraform

The `kestra_flow` Terraform resource type allows you to deploy a flow to Kestra. By default this resource will deploy only one specific flow:

```hcl
resource "kestra_flow" "com_flows" {
  flow_id = "com_flows"
  namespace = "dev"
  content = <<EOF
id: com_flows
namespace: dev
tasks:
  - id: hello-world
    type: io.kestra.core.tasks.log.Log
    message: Hello world!
EOF
}
```

or using a [YAML file](flows/01_helloWorld.yml) directly:

```hcl
resource "kestra_flow" "HelloWorldFlow" {
  flow_id = "helloWorld"
  namespace = "dev"
  content = templatefile("flows/01_helloWorld.yml", {})
}
```

## Deploying an entire [flows](flows) directory with Terraform

You can combine `for_each` with the `fileset()` Terraform function to deploy an entire directory of flows:

```hcl
resource "kestra_flow" "com_flows" {
  for_each = fileset(path.module, "flows/*.yml")
  flow_id = yamldecode(templatefile(each.value, {}))["id"]
  namespace = yamldecode(templatefile(each.value, {}))["namespace"]
  content = templatefile(each.value, {})
}
```


## Deploying flows with Terraform using the default Open-Source installation

Follow the above mentioned instructions to start Kestra in Docker. Then install Terraform as shown below. 

### Install Terraform

First, make sure to [install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) on your local machine. For instance, using `brew`:

```sh
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
``` 

## Deploy flows to your local Kestra instance with Terraform

For open-source installation of Kestra, there are no other resources you would need to provision other than the `kestra_flow` resource. 

Create a file called `main.tf` with the following content:


```hcl
terraform {
  required_providers {
    kestra = {
      source = "kestra-io/kestra" # namespace of Kestra provider
      version = "~> 0.7.0" # don't worry about 0.7.0 being displayed here - the provider works across the latest version as well
    }
  }
}

provider "kestra" {
  url = "http://localhost:8080"
}

resource "kestra_flow" "com_flows" {
  for_each = fileset(path.module, "flows/*.yml")
  flow_id = yamldecode(templatefile(each.value, {}))["id"]
  namespace = yamldecode(templatefile(each.value, {}))["namespace"]
  content = templatefile(each.value, {})
}
```

Make sure to run both Terraform and Kestra on the same host when using the open-source version of Kestra.

Now run:

```sh
terraform init
terraform validate # optionally to cross-check the flow syntax works correctly
terraform apply # confirm with yes or add the -auto-approve flag
```

## Troubleshooting Terraform

Q: What if I get an error ``Error: status: 422, method: POST, body: {"message":"Invalid entity: flow.id: Flow id already exists"``? 
A: This means that somebody has already created a flow with the same name (ID) in this namespace. To reconcile that, ensure that you don't manually modify your flow definition from the UI in the production environment. Instead, use Terraform to deploy your flows to production.

To fix that error, delete the flow created from the UI and reapply Terraform: ``tf apply -auto-approve``. 

---

# Terraform Cloud & Kestra Enterprise Edition

For a reliable, secure and easiest to manage CI/CD and IaC setup, we recommend deploying all Kestra-related production resources using Terraform Cloud. 

## Kestra Enterprise
To deploy Kestra Enterprise Edition, contact us using [this form](https://kestra.io/contact-us) or [book a call](https://meetings-eu1.hubspot.com/quentin-sinig/meeting-link-demo).


---

# Custom Scripts

## How to run Bash and Python tasks

Here is an example of a Bash task:

```yaml
id: hello-bash-python  
namespace: dev
tasks:  
  - id: bash-task
    type: io.kestra.core.tasks.scripts.Bash
    description: create a CSV file
    commands:
      - echo "order_id,total_amount" > output.csv
      - echo "1,100" >> output.csv
      - echo "2,200" >> output.csv
      - echo "3,300" >> output.csv
  
  - id: python-task
    type: io.kestra.core.tasks.scripts.Python
    description: Get the current Bitcoin price
    inputFiles:
      main.py: |
        import requests
        
        url = "https://api.coindesk.com/v1/bpi/currentprice/BTC.json"
        response = requests.get(url)
        data = response.json()
        price = data['bpi']['USD']['rate']
        print(price)
    requirements:
      - requests
    runner: DOCKER
    dockerOptions:
      image: python:3.11-slim
      pullImage: true # set to false if you have it already
```        

### Custom Docker image per task 

If you prefer to run the Python or Bash task in a (_potentially custom_) Docker container:

```yaml
id: hello-docker
namespace: dev
tasks: 
  - id: python-container-cli
    type: io.kestra.core.tasks.scripts.Bash
    commands:
      - python main.py
    runner: DOCKER
    dockerOptions:
      image: your_custom_pulled_image:latest
      pullImage: false
```

Using `dockerOptions` you can also configure credentials to remote Docker registries.


### Docker image with `requirements.txt` installed at runtime 


```yaml
id: hello-python-docker
namespace: dev
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


