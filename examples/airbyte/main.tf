terraform {
  required_providers {
    airbyte = {
      source  = "airbytehq/airbyte"
      version = "0.1.1"
    }
    kestra = {
      source  = "kestra-io/kestra"
      version = "~> 0.7.0"
    }
  }
}

provider "airbyte" {
  bearer_auth = var.airbyte_api_key
}

provider "kestra" {
  url = var.kestra_url
}


resource "airbyte_connection" "pokeapi_devnull" {
  name           = "PokeAPI → Null Destination"
  source_id      = airbyte_source_pokeapi.pokeapi.source_id
  destination_id = airbyte_destination_dev_null.null_destination.destination_id
}

resource "airbyte_connection" "sample_devnull" {
  name           = "Sample Data → Null Destination"
  source_id      = airbyte_source_faker.sample.source_id
  destination_id = airbyte_destination_dev_null.null_destination.destination_id
}

resource "airbyte_connection" "dockerhub_devnull" {
  name           = "DockerHub → Null Destination"
  source_id      = airbyte_source_dockerhub.dockerhub.source_id
  destination_id = airbyte_destination_dev_null.null_destination.destination_id
}


resource "kestra_flow" "airbyte" {
  keep_original_source = true
  flow_id              = "airbyte"
  namespace            = var.namespace
  content              = <<EOF
id: airbyte
namespace: ${var.namespace}
tasks:
  - id: airbyte
    type: io.kestra.core.tasks.flows.Parallel
    tasks:
      - id: pokeApi
        type: io.kestra.plugin.airbyte.cloud.jobs.Sync
        connectionId: ${airbyte_connection.pokeapi_devnull.connection_id}
        token: "{{envs.airbyte_cloud_api_token}}"

      - id: sampleData
        type: io.kestra.plugin.airbyte.cloud.jobs.Sync
        connectionId: ${airbyte_connection.sample_devnull.connection_id}
        token: "{{envs.airbyte_cloud_api_token}}"

      - id: dockerhub
        type: io.kestra.plugin.airbyte.cloud.jobs.Sync
        connectionId: ${airbyte_connection.dockerhub_devnull.connection_id}
        token: "{{envs.airbyte_cloud_api_token}}"

  - id: transformations
    type: io.kestra.core.tasks.flows.Parallel
    tasks:
      - id: dbt
        type: io.kestra.core.tasks.flows.WorkingDirectory
        tasks:
          - id: cloneRepository
            type: io.kestra.plugin.git.Clone
            url: https://github.com/jwills/jaffle_shop_duckdb
            branch: duckdb

          - id: pandas
            type: io.kestra.core.tasks.scripts.Python
            inputFiles:
              main.py: |
                import pandas as pd
                df = pd.read_csv("seeds/raw_customers.csv")
                df.info()
            runner: DOCKER
            dockerOptions:
              image: ghcr.io/kestra-io/pydata:latest

          - id: dbt-build
            type: io.kestra.plugin.dbt.cli.Build
            debug: true
            runner: DOCKER
            dockerOptions:
              image: ghcr.io/kestra-io/dbt-duckdb:latest
            dbtPath: /usr/local/bin/dbt
            inputFiles:
              .profile/profiles.yml: |
                jaffle_shop:
                  outputs:
                    dev:
                      type: duckdb
                      path: ':memory:'
                      extensions:
                        - parquet
                  target: dev
triggers:
  - id: every-minute
    type: io.kestra.core.models.triggers.types.Schedule
    cron: "*/1 * * * *"
    disabled: true
EOF
}
