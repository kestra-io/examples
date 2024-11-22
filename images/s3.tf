terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }

    kestra = {
      source = "kestra-io/kestra" # namespace of Kestra provider
      version = "~> 0.7.0" # don't worry about 0.7.0 being displayed here - the provider works across the latest version as well
    }

  }
}

provider "aws" {
    region = var.region
    profile = "default"
}

provider "kestra" {
  url = "http://localhost:8080"
}

variable "region" {
  default = "eu-central-1"
}

variable "namespace" {
  default = "prod"
}


resource "aws_s3_bucket" "s3_bucket" {
  bucket = "declarative-orchestration"
  force_destroy = true # delete bucket when needed even if it's not empty
  tags = {
    project = "kestra"
  }
}


resource "kestra_flow" "uploadToS3" {
  flow_id    = "uploadToS3"
  namespace = var.namespace
  content   = <<EOF
id: uploadToS3
namespace: ${var.namespace}
inputs:
  - name: bucket
    type: STRING
    defaults: ${aws_s3_bucket.s3_bucket.bucket}
    required: true
tasks:
  - id: getZipFile
    type: io.kestra.plugin.fs.http.Download
    uri: "https://wri-dataportal-prod.s3.amazonaws.com/manual/global_power_plant_database_v_1_3.zip"
  - id: unzip
    type: io.kestra.plugin.compress.ArchiveDecompress
    from: "{{ outputs.getZipFile.uri }}"
    algorithm: ZIP
  - id: parallelUploadToS3
    type: io.kestra.plugin.core.flow.Parallel
    tasks:
      - id: csv
        type: io.kestra.plugin.aws.s3.Upload
        from: "{{outputs.unzip.files['global_power_plant_database.csv']}}"
        key: powerplant/global_power_plant_database.csv
      - id: pdf
        type: io.kestra.plugin.aws.s3.Upload
        from: "{{outputs.unzip.files['Estimating_Power_Plant_Generation_in_the_Global_Power_Plant_Database.pdf']}}"
        key: powerplant/Estimating_Power_Plant_Generation_in_the_Global_Power_Plant_Database.pdf
      - id: txt
        type: io.kestra.plugin.aws.s3.Upload
        from: "{{outputs.unzip.files['RELEASE_NOTES.txt']}}"
        key: powerplant/RELEASE_NOTES.txt
  - id: listObjects
    type: io.kestra.plugin.aws.s3.List
    bucket: "{{inputs.bucket}}"
    prefix: powerplant/
  - id: printObjects
    type: io.kestra.plugin.core.log.Log
    message: "found objects {{outputs.listObjects.objects}}"
  - id: mapOverS3Objects
    type: io.kestra.core.tasks.flows.EachParallel
    value: "{{outputs.listObjects.objects}}"
    tasks: # all tasks listed here will run in parallel
      - id: validateObjectMetadata
        type: io.kestra.plugin.core.log.Log
        message: "filename {{json(taskrun.value).key}} with size {{json(taskrun.value).size}}"
pluginDefaults:
  - type: io.kestra.plugin.aws.s3.Upload
    values:
      accessKeyId: "{{secret('AWS_ACCESS_KEY_ID')}}"
      secretKeyId: "{{secret('AWS_SECRET_ACCESS_KEY')}}"
      region: ${var.region}
      bucket: "{{inputs.bucket}}"
  - type: io.kestra.plugin.aws.s3.List
    values:
      accessKeyId: "{{secret('AWS_ACCESS_KEY_ID')}}"
      secretKeyId: "{{secret('AWS_SECRET_ACCESS_KEY')}}"
      region: ${var.region}
EOF
}
