terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    kestra = {
      source  = "kestra-io/kestra"
      version = "~> 0.7.0"
    }
  }
}

provider "kestra" {
  url = "http://localhost:8080"
}

provider "aws" {
  region  = var.region
  profile = "default"
}

resource "aws_iam_policy" "dynamodb" {
  name        = "dynamodb"
  description = "Policy to sync data to BigQuery from Fivetran"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:DescribeStream",
          "dynamodb:DescribeTable",
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:ListTables",
          "dynamodb:Scan"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

module "dynamodb_table" {
  source = "terraform-aws-modules/dynamodb-table/aws"

  name     = "demo"
  hash_key = "id"

  attributes = [
    {
      name = "id"
      type = "S" # N for number, S for string
    }
  ]
}


resource "kestra_flow" "addItemToDynamoDB" {
  keep_original_source = true
  flow_id              = "addItemToDynamoDB"
  namespace            = var.namespace
  content              = <<EOF
id: addItemToDynamoDB
namespace: ${var.namespace}
tasks:
  - id: firstItemAsMap
    type: io.kestra.plugin.aws.dynamodb.PutItem
    tableName: ${var.table_name}
    region: ${var.region}
    accessKeyId: "{{ secret('AWS_ACCESS_KEY_ID') }}"
    secretKeyId: "{{ secret('AWS_SECRET_ACCESS_KEY') }}"
    item:
      id: 1
      flow: "{{ flow.id }}"
      task: "{{ task.id }}"
      executionId: "{{ execution.id }}"

  - id: secondItemAsJSON
    type: io.kestra.plugin.aws.dynamodb.PutItem
    tableName: ${var.table_name}
    region: ${var.region}
    accessKeyId: "{{ secret('AWS_ACCESS_KEY_ID') }}"
    secretKeyId: "{{ secret('AWS_SECRET_ACCESS_KEY') }}"
    item: |
        {
            "id": 2,
            "flow": "{{ flow.id }}",
            "task": "{{ task.id }}",
            "executionId": "{{ execution.id }}"
        }

EOF
}

resource "kestra_flow" "scanDynamoDBTable" {
  keep_original_source = true
  flow_id              = "scan_dynamodb_table"
  namespace            = var.namespace
  content              = <<EOF
id: scan_dynamodb_table
namespace: ${var.namespace}
tasks:
  - id: extract_data
    type: io.kestra.plugin.aws.dynamodb.Scan
    tableName: ${var.table_name}
    region: ${var.region}
    fetchType: FETCH
    accessKeyId: "{{ secret('AWS_ACCESS_KEY_ID') }}"
    secretKeyId: "{{ secret('AWS_SECRET_ACCESS_KEY') }}"

  - id: processData
    type: io.kestra.plugin.scripts.shell.Commands
    commands:
      - echo {{ outputs.extract_data.rows }}

EOF
}
