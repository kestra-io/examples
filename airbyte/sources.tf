resource "airbyte_source_pokeapi" "pokeapi" {
  configuration = {
    pokemon_name = "psyduck"
    source_type  = "pokeapi"
  }
  name         = "PokeAPI"
  workspace_id = var.airbyte_workspace_id
}

resource "airbyte_source_faker" "sample" {
  configuration = {
    count       = 10
    seed        = 42
    source_type = "faker"
  }
  name         = "Sample Data"
  workspace_id = var.airbyte_workspace_id
}

resource "airbyte_source_dockerhub" "dockerhub" {
  configuration = {
    docker_username = "kestra"
    source_type     = "dockerhub"
  }
  name         = "DockerHub"
  workspace_id = var.airbyte_workspace_id
}
