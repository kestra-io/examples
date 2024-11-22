In this hands-on demonstration, we're gonna build a CI/CD process for data pipelines with Kestra and Terraform. 

# What is Terraform

[Terraform](https://developer.hashicorp.com/terraform/intro) is an open-source infrastructure as code tool that allows developers to define and manage resources using a human-readable, cloud-agnostic,  **declarative configuration**. 

With Terraform, you can **automate** provisioning and managing changes to your infrastructure using declarative code defined in HCL (HashiCorp Configuration Language). 

Here is an example syntax.

The declarative "Infrastructure as Code" approach eliminates the need for the user to know whether a component needs to be provisioned, modified, or destroyed. What's declared in the configuration is what gets compared to the current state and applied.

In this example, we declare that an S3 bucket resource should exist. In square brackets we specify the criteria such as bucket name. 

When you run terraform apply, Terraform will compare the desired state with the current state and deploy changes if necessary. 
In this example, the S3 bucket had to be created.

---



# How to integrate Kestra with IaC: CI/CD with Terraform

To deploy your workflows to Kestra, you can use the Kestra Terraform provider. This allows you to follow Infrastructure as Code best practices in your data engineering lifecycle. 


## Deploying a single flow with Terraform

The `kestra_flow` Terraform resource type allows you to deploy a flow to Kestra. By default this resource will deploy only one specific flow:

```hcl
resource "kestra_flow" "firstFlow" {
  keep_original_source = true
  flow_id = "hello"
  namespace = "prod"
  content = <<EOF
id: hello  
namespace: prod
tasks:
  - id: hello
    type: io.kestra.plugin.core.log.Log
    message: Hello world!
EOF
}
```

A much friendlier alternative is to reference the [YAML file](flows/helloWorld.yml) directly using the `templatefile` function:

```hcl
resource "kestra_flow" "helloWorld" {
  keep_original_source = true
  flow_id = "helloWorld"
  namespace = "dev"
  content = templatefile("flows/helloWorld.yml", {})
}
```

One drawback of both of the above mentioned approaches is that flow ID and namespace are defined twice - once in the flow YAML definition, and once here in the terraform resource. To avoid this duplication, you can leverage the `yamldecode` function which parses a string as a subset of YAML, allowing to retrieve the flow id and namespace from YAML and use it in the Terraform definition.


```hcl
resource "kestra_flow" "helloWorld" {
  keep_original_source = true
  flow_id = yamldecode(templatefile("flows/helloWorld.yml", {}))["id"]
  namespace = yamldecode(templatefile("flows/helloWorld.yml", {}))["namespace"]
  content = templatefile("flows/helloWorld.yml", {})
}
```


## Deploying an entire [flows](flows) directory with Terraform

The above section showed how you can define a single flow. In reality, you would typically want to automatically discover and deploy all flows from a given directory. To accomplish that, you can combine `for_each` with the `fileset()` Terraform function to deploy an entire directory of flows:

```hcl
resource "kestra_flow" "com_flows" {
  keep_original_source = true
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

resource "kestra_flow" "flows" {
  keep_original_source = true
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

## Terraform Cloud setup

See the page [Terraform Cloud](terraform-cloud.md) for more details on how to implement Infrastructure as Code with Kestra and Terraform Cloud.

