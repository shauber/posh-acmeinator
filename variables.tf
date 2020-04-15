variable "resource-group-location" {
  type = string
  default = "East US"
}

variable "env" {
  type = string
  default = "dev"
}

variable "run_as_account_sp_object_id" {
  type = string
  default = "deadbeef-8080-8080-dead-deadbeef8080"
}

