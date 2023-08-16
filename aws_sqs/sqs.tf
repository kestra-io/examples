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
  keep_original_source = true
  flow_id    = "sqsPublishMessage"
  namespace = var.namespace
  content   = <<EOF
id: sqsPublishMessage
namespace: ${var.namespace}
inputs:
  - name: message
    type: STRING
    defaults: "Hi from SQS!"
tasks:
  - id: publishMessage
    type: io.kestra.plugin.aws.sqs.Publish
    accessKeyId: "{{ secret('AWS_ACCESS_KEY_ID') }}"
    secretKeyId: "{{ secret('AWS_SECRET_ACCESS_KEY') }}"
    region: ${var.region}
    queueUrl: ${aws_sqs_queue.queue.id}
    from:
      data: "{{inputs.message}}"
EOF
}

resource "kestra_flow" "sqsConsumeMessages" {
  keep_original_source = true
  flow_id    = "sqsConsumeMessages"
  namespace = var.namespace
  content   = <<EOF
id: sqsConsumeMessages
namespace: ${var.namespace}
tasks:
  - id: pollSqsForMessages
    type: io.kestra.plugin.aws.sqs.Consume
    accessKeyId: "{{ secret('AWS_ACCESS_KEY_ID') }}"
    secretKeyId: "{{ secret('AWS_SECRET_ACCESS_KEY') }}"
    region: ${var.region}
    queueUrl: ${aws_sqs_queue.queue.id}
    maxRecords: 1
  - id: print
    type: io.kestra.core.tasks.scripts.Bash
    inputFiles:
      messages.ion: "{{outputs.pollSqsForMessages.uri}}"
    commands:
      - cat messages.ion
EOF
}

resource "kestra_flow" "sqsReactToMessage" {
  keep_original_source = true
  flow_id    = "sqsReactToMessage"
  namespace = var.namespace
  content   = <<EOF
id: sqsReactToMessage
namespace: ${var.namespace}
tasks:
  - id: printMessage
    type: io.kestra.core.tasks.scripts.Bash
    inputFiles:
      message.ion: "{{trigger.uri}}"
    commands:
      - cat message.ion
triggers:
  - id: sqs
    type: io.kestra.plugin.aws.sqs.Trigger
    accessKeyId: "{{ secret('AWS_ACCESS_KEY_ID') }}"
    secretKeyId: "{{ secret('AWS_SECRET_ACCESS_KEY') }}"
    region: ${var.region}
    queueUrl: ${aws_sqs_queue.queue.id}
    maxRecords: 1
EOF
}
