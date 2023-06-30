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
    accessKeyId: "{{envs.aws_access_key_id}}"
    secretKeyId: "{{envs.aws_secret_access_key}}"
    item:
      id: 1
      flow: "{{ flow.id }}"
      task: "{{ task.id }}"
      executionId: "{{ execution.id }}"

  - id: secondItemAsJSON
    type: io.kestra.plugin.aws.dynamodb.PutItem
    tableName: ${var.table_name}
    region: ${var.region}
    accessKeyId: "{{envs.aws_access_key_id}}"
    secretKeyId: "{{envs.aws_secret_access_key}}"
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
  flow_id              = "scanDynamoDBTable"
  namespace            = var.namespace
  content              = <<EOF
id: scanDynamoDBTable
namespace: ${var.namespace}
tasks:
  - id: extractData
    type: io.kestra.plugin.aws.dynamodb.Scan
    tableName: ${var.table_name}
    region: ${var.region}
    fetchType: FETCH
    accessKeyId: "{{envs.aws_access_key_id}}"
    secretKeyId: "{{envs.aws_secret_access_key}}"

  - id: processData
    type: io.kestra.core.tasks.scripts.Bash
    commands:
      - echo {{outputs.scanTable.rows}}

EOF
}
