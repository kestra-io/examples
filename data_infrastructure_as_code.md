# Data Infrastructure as Code

There are two important paradigms that significantly shaped the Data Infrastructure landscape: 
1. Infrastructure as Code
2. Workflow as Code

Combining the two helps implement a reliable data engineering lifecycle with:
- reliable infrastructure management
- data pipelines built as code
- version control of both, data workflows and the underlying infrastructure.

This repository includes examples helping you adopt both of these paradigms at the same time.

## Install Kestra
You can start Kestra using Docker-Compose:

```sh
curl -o docker-compose.yml https://raw.githubusercontent.com/kestra-io/kestra/develop/docker-compose.yml

docker-compose up
```

Before starting Kestra, make sure to create the `.env` file as shown in the [.env_example](.env_example) file. Add any secrets there as environment variables so that you can use them in your workflows in a secure way.


## Install Terraform

You can install Terraform on your local machine using `Homebrew` (for detailed instructions of your OS, check the [Terraform CLI install guide Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)):

```sh
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
``` 


![install.png](images/install.png)

# Write in code, deploy in one command

Navigate to the relevant project e.g. [aws_s3_tf](aws_s3) and initialize the relevant Terraform providers:

```bash
cd aws_s3/
terraform init
```

 Then, deploy the workflow and the underlying infrastructure using the command:

 ```bash
 terraform apply -auto-approve
 ```

