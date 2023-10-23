#Initialize server port for sake of DRY
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type = number
  default = 8080
}

variable "cluster_name" {
  description = "Name used for all cluster resources"
  type = string
}

variable "db_remote_state_bucket" {
  description = "S3 bucket name for remote state of DB"
  type = string
}

variable "db_remote_state_key" {
  description = "S3 path for DB remote state"
  type = string
}

variable "instance_type" {
  description = "EC2 instance classes to run"
  type = string
}

variable "min_size" {
  description = "Minimum EC2 node count in ASG"
  type = number
}

variable "max_size" {
  description = "Maximum EC2 node count in ASG"
  type = number
}