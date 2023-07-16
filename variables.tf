variable "hostname" {
  description = "Host name URL of the Kestra instance"
  type        = string
  default     = "http://localhost:8080"
}

variable "username" {
  description = "User name of the Kestra instance"
  type        = string
  default     = ""
}

variable "password" {
  description = "Password of the Kestra instance"
  type        = string
  default     = ""
}

variable "slack_webhook" {
  description = "Slack Incoming Webhook"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "geller"
}


variable "env" {
  description = "Environment - some resources only need to exist in prod"
  type        = string
  default     = "dev"
}
