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

variable "region" {
  default = "eu-central-1"
}

variable "namespace" {
  default = "prod"
}

provider "aws" {
    region = var.region
    profile = "default"
}

provider "kestra" {
  url = "http://localhost:8080"
}

resource "aws_sqs_queue" "queue" {
    name      = "kestra"
    fifo_queue = false
    tags = {
        project = "kestra"
    }
}

resource "kestra_flow" "sqsPublishMessage" {
  flow_id    = "sqsPublishMessage"
  namespace = var.namespace
  content   = <<EOF
id: sqsPublishMessage
namespace: ${var.namespace}
tasks:
  - id: publishMessage
    type: io.kestra.plugin.aws.sqs.Publish
    accessKeyId: "{{envs.aws_access_key_id}}"
    secretKeyId: "{{envs.aws_secret_access_key}}"
    region: ${var.region}
    queueUrl: ${aws_sqs_queue.queue.id}
    from:
      data: "Hello World from Kestra and SQS"
EOF
}

resource "kestra_flow" "sqsReactToMessage" {
  flow_id    = "sqsReactToMessage"
  namespace = var.namespace
  content   = <<EOF
id: sqsReactToMessage
namespace: ${var.namespace}
tasks:
  - id: consumeMessage
    type: io.kestra.plugin.aws.sqs.Consume
    accessKeyId: "{{envs.aws_access_key_id}}"
    secretKeyId: "{{envs.aws_secret_access_key}}"
    region: ${var.region}
    queueUrl: ${aws_sqs_queue.queue.id}
    maxRecords: 1
  - id: print
    type: io.kestra.core.tasks.scripts.Bash
    description: |
    commands:
      - echo received message stored in {{outputs.consumeMessage.uri}}
triggers:
  - id: sqs
    type: io.kestra.plugin.aws.sqs.Trigger
    description: to activate it, set disabled to false
    disabled: true
    accessKeyId: "{{envs.aws_access_key_id}}"
    secretKeyId: "{{envs.aws_secret_access_key}}"
    region: ${var.region}
    queueUrl: ${aws_sqs_queue.queue.id}
    maxRecords: 1
EOF
}
