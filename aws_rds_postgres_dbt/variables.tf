variable "region" {
  default     = "eu-central-1"
  description = "AWS region"
}

variable "db_password" {
  description = "RDS root user password"
  sensitive   = true
}

variable "db_username" {
    description = "RDS root user name"
    default     = "kestra"
}

variable "db_instance" {
  description = "RDS DB instance type"
  default     = "db.t4g.micro"
}