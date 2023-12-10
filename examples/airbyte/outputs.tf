output "airbyte" {
  value = join("/", [var.kestra_url, "ui/flows/edit", kestra_flow.airbyte.id])
}
