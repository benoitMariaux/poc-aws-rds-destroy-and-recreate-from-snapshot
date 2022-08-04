variable "db_password" {
  type = string
  default = "foobarbaz"
}

variable "db_username" {
  type = string
  default = "foo"
}

variable "db_name" {
  type = string
  default = "classicmodels"
}

variable "aws_ami_id" {
  type = string
  #default = "ami-0d75513e7706cf2d9" # Ubuntu
  default = "ami-089950bc622d39ed8" # Amz Linux
}

variable "db_snapshot_identifier" {
  type = string
}
