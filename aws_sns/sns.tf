terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }

    kestra = {
      source  = "kestra-io/kestra" # namespace of Kestra provider
      version = "~> 0.7.0"         # don't worry about 0.7.0 being displayed here - the provider works across the latest version as well
    }

  }
}

variable "region" {
  default = "eu-central-1"
}

variable "namespace" {
  default = "prod"
}

variable "phone_number" {
  type = string
}

provider "aws" {
  region  = var.region
  profile = "default"
}

provider "kestra" {
  url = "http://localhost:8080"
}

resource "aws_sns_topic" "topic" {
  name = "kestra"
  tags = {
    project = "kestra"
  }
}

resource "aws_sns_topic_subscription" "sms" {
  endpoint  = var.phone_number
  protocol  = "sms"
  topic_arn = aws_sns_topic.topic.arn
}

resource "kestra_flow" "snsSendSMS" {
  keep_original_source = true
  flow_id              = "snsSendSMS"
  namespace            = var.namespace
  content              = <<EOF
id: snsSendSMS
namespace: ${var.namespace}
tasks:
  - id: sendSMS
    type: io.kestra.plugin.aws.sns.Publish
    accessKeyId: "{{envs.aws_access_key_id}}"
    secretKeyId: "{{envs.aws_secret_access_key}}"
    region: ${var.region}
    topicArn: "${aws_sns_topic.topic.arn}"
    from:
      data: Hello from Kestra and SNS
EOF
}
