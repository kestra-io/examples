provider "kestra" {
  url = "http://localhost:8080"
}


variable "namespace" {
  default = "company.team"
}


resource "kestra_flow" "dbtGitDockerPostgresRDS" {
  keep_original_source = true
  flow_id    = "dbt_git_docker_postgres_rds"
  namespace = var.namespace
  content   = <<EOF
id: dbt_git_docker_postgres_rds
namespace: ${var.namespace}

tasks:
  - id: dbt
    type: io.kestra.plugin.core.flow.WorkingDirectory
    tasks:
      - id: clone_repository
        type: io.kestra.plugin.git.Clone
        url: https://github.com/dbt-labs/jaffle_shop
        branch: main

      - id: dbt_setup
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
        taskRunner:
          type: io.kestra.plugin.scripts.runner.docker.Docker
        containerImage: python:3.10-slim

      - id: dbt_build
        type: io.kestra.plugin.dbt.cli.Build
        debug: false
        taskRunner:
          type: io.kestra.plugin.scripts.runner.docker.Docker
        containerImage: python:3.10-slim
EOF
}
