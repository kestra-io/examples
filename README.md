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
namespace: dev
tasks:
  - id: hello-world
    type: io.kestra.core.tasks.log.Log
    message: Hello world!
```

## Adding a schedule

Here is how you can add a schedule trigger to run the flow every minute: [helloParametrizedScheduled.yml](flows/helloParametrizedScheduled.yml)

To add multiple schedules, each running with different input parameter values, use [helloParametrizedMultipleSchedules.yml](flows/helloParametrizedMultipleSchedules.yml)

---

# How to integrate Kestra with other tools in the Modern Data Stack 

## Airbyte

Here is an example of using Kestra with Airbyte running in other Docker container: [airbyteSync.yml](flows/airbyteSync.yml)

And example running multiple Airbyte syncs in parallel: [airbyteSyncParallel.yml](flows/airbyteSyncParallel.yml) 

## Fivetran

Here is an example of a flow with a single task triggering a Fivetran sync: [fivetranSync.yml](flows/fivetranSync.yml)

---


# How to integrate Kestra with IaC: CI/CD with Terraform

To deploy your workflows to Kestra, you can use the Kestra Terraform provider. This allows you to follow Infrastructure as Code best practices in your data engineering lifecycle. 


## Deploying a single flow with Terraform

The `kestra_flow` Terraform resource type allows you to deploy a flow to Kestra. By default this resource will deploy only one specific flow:

```hcl
resource "kestra_flow" "firstFlow" {
  flow_id = "hello"
  namespace = "prod"
  content = <<EOF
id: hello  
namespace: prod
tasks:
  - id: hello
    type: io.kestra.core.tasks.log.Log
    message: Hello world!
EOF
}
```

A much friendlier alternative is to reference the [YAML file](flows/helloWorld.yml) directly using the `templatefile` function:

```hcl
resource "kestra_flow" "helloWorld" {
  flow_id = "helloWorld"
  namespace = "dev"
  content = templatefile("flows/helloWorld.yml", {})
}
```

One drawback of both of the above mentioned approaches is that flow ID and namespace are defined twice - once in the flow YAML definition, and once here in the terraform resource. You can leverage the `yamldecode` function to avoid this duplication:

```hcl
resource "kestra_flow" "helloWorld" {
  flow_id = yamldecode(templatefile("flows/helloWorld.yml", {}))["id"]
  namespace = yamldecode(templatefile("flows/helloWorld.yml", {}))["namespace"]
  content = templatefile("flows/helloWorld.yml", {})
}
```


## Deploying an entire [flows](flows) directory with Terraform

The above section showed how you can define a single flow. In reality, you would typically want to automatically discover and deploy all flows from a given directory. To accomplish that, you can combine `for_each` with the `fileset()` Terraform function to deploy an entire directory of flows:

```hcl
resource "kestra_flow" "com_flows" {
  for_each = fileset(path.module, "flows/*.yml")
  flow_id = yamldecode(templatefile(each.value, {}))["id"]
  namespace = yamldecode(templatefile(each.value, {}))["namespace"]
  content = templatefile(each.value, {})
}
```


## Deploying flows with Terraform using the default Open-Source installation


### Install Kestra
You can start Kestra using Docker-Compose:

```sh
curl -o docker-compose.yml https://raw.githubusercontent.com/kestra-io/kestra/develop/docker-compose.yml
docker-compose up
```

### Install Terraform

You can install Terraform on your local machine using `Homebrew` (for detailed instructions of your OS, check the [Terraform CLI install guide Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)):

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

Make sure to run both Terraform and Kestra on the same host when using the open-source version of Kestra. Alternatively, make sure that the Kestra URL is reachable from where you use Terraform CLI. 

Execute the Terraform CLI commands:

```sh
terraform init
terraform validate # optionally to cross-check the flow syntax works correctly
terraform apply # confirm with yes or add the -auto-approve flag
```

## Troubleshooting Terraform

Q: What if I get an error ``Error: status: 422, method: POST, body: {"message":"Invalid entity: flow.id: Flow id already exists"``? 
A: This means that somebody has already created a flow with the same name (ID) in this namespace. To reconcile that, ensure that you don't manually modify your flow definition from the UI in the production environment. Instead, use Terraform to deploy your flows to production.

To fix that error, delete the flow created from the UI and deploy it with Terraform: ``tf apply -auto-approve``. 

---

# Terraform Cloud & Kestra Enterprise Edition

For a reliable, secure and easiest to manage CI/CD and IaC setup, we recommend deploying all Kestra-related production resources using Terraform Cloud. 


## Kestra Enterprise
To deploy Kestra Enterprise Edition, contact us using [this form](https://kestra.io/contact-us) or [book a call](https://meetings-eu1.hubspot.com/quentin-sinig/meeting-link-demo).


---

# Custom Scripts

## How to run Bash and Python tasks

Here is an example of a Bash task: [pythonBashContainer](flows/pythonBashContainer.yml)


### Custom Docker image per task 

If you prefer to run the Python or Bash task in a (_potentially custom_) Docker container: [pythonScriptContainer](flows/pythonScriptContainer.yml)

Using `dockerOptions` with the `dockerConfig` attribute, you can also configure credentials to private Docker registries:

`auths: { "my.registry.com" : { auth: "token" } }`


### Docker image with `requirements.txt` installed at runtime 


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

## Keyboard shortcuts for the 

- Comment/uncomment Code Block Ctrl+K+C/Ctrl+K+U
- Comment/uncomment Code Block Cmd+K+C/Cmd+K+U
- Move Code Alt+Up/Down

## Turn GCP Credential file into a one liner

```sh
cat credentials.json | jq -r tostring 
```

# Credentials management

## Open-source Kestra

In the open-source version, you can leverage environment variables. 
Add this variable to your .env file (paste your service account JSON as the value): 

```
KESTRA_GCP_CREDS={"type":"service_account","project_id":"geller","private_key_id":"..."}
```

Then, you can reference that environment variable in your flow using ``{{envs.gcp_creds}}``. 

Note that the reference must be lowercase and without the ``KESTRA_`` prefix.

## Cloud & Eneterprise Edition

You can add a Secret in the relevant namespace. To reference that secret in your flow, use: ``{{secret('GITHUB_ACCESS_TOKEN')}}``.  

