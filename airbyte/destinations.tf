resource "airbyte_destination_dev_null" "null_destination" {
  configuration = {
    destination_type = "dev-null"
    test_destination = {
      destination_dev_null_test_destination_silent = {
        test_destination_type = "SILENT"
      }
    }
  }
  name         = "Null Destination"
  workspace_id = var.airbyte_workspace_id
}
