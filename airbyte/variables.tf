variable "airbyte_api_key" {
  type = string
}

variable "airbyte_workspace_id" {
  type = string
}

variable "kestra_url" {
  type    = string
  default = "http://localhost:8080"
}

variable "namespace" {
  type    = string
  default = "prod"
}
