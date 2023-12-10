provider "kestra" {
  url = "http://localhost:8080"
}


variable "namespace" {
  default = "prod"
}


resource "kestra_flow" "dbtGitDockerPostgresRDS" {
  keep_original_source = true
  flow_id    = "dbtGitDockerPostgresRDS"
  namespace = var.namespace
  content   = <<EOF
id: dbtGitDockerPostgresRDS
namespace: ${var.namespace}
tasks:
  - id: dbt
    type: io.kestra.core.tasks.flows.Worker
    tasks:
    - id: clone-repository
      type: io.kestra.plugin.git.Clone
      url: https://github.com/dbt-labs/jaffle_shop
      branch: main
    - id: dbt-setup
      type: io.kestra.plugin.dbt.cli.Setup
      profiles:
        jaffle_shop:
          target: dev
          outputs:
            dev:
              type: postgres
              host: ${aws_db_instance.kestra.address}
              user: ${var.db_username}
              password: ${var.db_password}
              port: ${aws_db_instance.kestra.port}
              dbname: postgres
              schema: jaffle_shop
              threads: 4
              connect_timeout: 10
      requirements:
        - dbt-postgres
      runner: DOCKER
      dockerOptions:
        image: python:3.10-slim
    - id: dbt-build
      type: io.kestra.plugin.dbt.cli.Build
      debug: false
      runner: DOCKER
      dockerOptions:
        image: python:3.10-slim
EOF
}
