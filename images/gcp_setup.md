# Google Cloud and BigQuery setup

## GCP account

Sign up for a Google Cloud Platform account if you don't have one already. There is a generous free tier trial but we'll demonstrate costs of each service in the demos.

### Download `gcloud` CLI

Download the [[CLI]] for GCP for your operating system, as described in [GCP docs here](https://cloud.google.com/sdk/docs/install). Then authenticate using `gcloud auth login`.

Alternatively, you can activate Google Cloud Shell session and launch a terminal (or VSCode-like **Editor**) directly in your GCP console in your browser. 

### Create GCP project

GCP projects (and if you're a company, also organization and folders) serve organizational purposes. Follow [this guide on GCP](https://cloud.google.com/resource-manager/docs/creating-managing-projects) to create a new project.

Set the project as default in your terminal to make your work easier:

```bash
# Set your project name
gcloud config set project YOUR_PROJECT_ID
```


### Create a service account

Create a default [[GCP Service Account]] for use with Terraform. It needs a basic **Editor** role, and in order to create other service accounts, it also needs an IAM **security Admin** role.

You can do that from the GCP console, or using those commands:

```bash
# Create the service account
gcloud iam service-accounts create terraform \
  --description="Service Account to use with Terraform"

# Create a JSON key file and put it into your Terraform directory. Add this file to .gitignore if you commit the code to Git
gcloud iam service-accounts keys create credentials.json \
  --iam-account=terraform@YOUR_PROJECT_ID.iam.gserviceaccount.com

# Grant the basic Editor role
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member=serviceAccount:terraform@YOUR_PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/editor

# Grant the Security Admin role
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member=serviceAccount:terraform@YOUR_PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/iam.securityAdmin
```

> Note: in all those commands, replace YOUR_PROJECT_ID with your GCP project ID. You need the project ID, not the project name. Usually, you can see the project ID in the URL, e.g.: `https://console.cloud.google.com/welcome?project=geller` - here, the project ID is `geller`. 
---

## Setup with [[Terraform]]
  
### Install Terraform

Install the latest Terraform version for your system. 

Terraform is a single binary, so you can also download, unzip and move it to the `bin` folder:

```bash
cd Downloads
unzip terraform_downloaded_filename.zip
mv terraform /usr/local/bin
```

Once installed, validate the version:

```bash
terraform -v
```

### Clone the tutorial repository

Clone the tutorial repository which includes all files for this tutorial.


### Provision GCP resources with Terraform

To provision GCP resources , run:  
  
```bash  
terraform apply
```  
  
This will:

- enable GCP APIs that you'll need
- create a BigQuery dataset and a GCS bucket 
- create a new service account with the least required permissions to write, read and modify data from the BigQuery cloud data warehouse in your flows.  
  
The `terraform apply` command will provision all resources and once ready, it ill generate a service account email address as **output**. Below is example output for GCP project named `geller`:

```bash
dwh-bq-gcs@geller.iam.gserviceaccount.com  
```

Use that email address to create a key and download it as a JSON file:  
  
```bash  
gcloud iam service-accounts keys create flows.json --iam-account=dwh-bq-gcs@geller.iam.gserviceaccount.com  
```  
  

You can now use that JSON file in your Kestra flows. 

### Kestra OSS

Turn the long JSON file into a one-liner (for use in the `.env` file):
```bash
cat flows.json | jq -r tostring
```

Copy that one-liner's contents of the JSON key-file as [[envs|environment variable]] in your `.env` file, as follows:

```env
KESTRA_GCP_CREDS={"type":"service_account","project_id":"geller","private_key_id":"xxx","private_key":"-----BEGIN PRIVATE KEY-----\nxxx\n-----END PRIVATE KEY-----\n","client_email":"dwh-bq-gcs@geller.iam.gserviceaccount.com  ","client_id":"xxx","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"https://www.googleapis.com/robot/v1/metadata/x509/dwh-bq-gcs@geller.iam.gserviceaccount.com"}
```

The above block 👆 is a trimmed version of the [[GCP Service Account]] key to show the syntax. 

Add the `.env` file to your Kestra Server container in the [[Docker Compose]] file:

```yaml
  kestra:
    image: kestra/kestra:develop-full
    entrypoint: /bin/bash
    env_file:
      - .env
```


Once you run `docker compose up -d`, the GCP credentials will be available in your flows using `{{envs.gcp_creds}}`. 

> Note: By default, Kestra reads all environment variables that start with `KESTRA_` prefix. Even though you define those in uppercase `KESTRA_GCP_CREDS`, in your flows, use lowercase syntax `{{envs.gcp_creds}}`. 

### Kestra Enterprise Edition 

If you are on [[Enterprise Edition|EE]], you can just add that as a [[Secret]] in the relevant namespace. 

## Setup entirely from the [[Google Cloud Platform|GCP]] console

TODO video showing how to manually:
- create a GCP project
- add a SA+ create a keyfile
- create a BQ dataset
- create a GCS bucket

Note that this process is not repeatable. E.g., if you want to set up a new [[Data Engineering]] project, you would need to again create those resources manually, and at scale (i.e. with lots of projects, tables, file-based datasets), you would lose sight of your projects.

Therefore, the section below explains how you can leverage the benefits of [[Infrastructure as Code]] and [[Declarative|Declarative workflows]]. 