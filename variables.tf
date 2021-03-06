variable "application" {
  default = "openethereum"
}

variable "provisionersrc" {
  default = "gustavobelfort/terraform-openethereum"
}

variable "name" {
  default = "openethereum"
}

variable "vpc_cidr" {
  description = "CIDR for the whole VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for the Public Subnet"
  default     = "10.0.0.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR for the Private Subnet"
  default     = "10.0.1.0/24"
}

variable "eth_count" {
  description = "The amount of OpenEthereum instances to create"
  default     = 1
}

variable "ubuntu_account_number" {
  default = "099720109477"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "ssh_pubkey" {
  default = ""
}

variable "ssh_privkey" {
  default = ""
}

variable "region" {
  default = "us-east-1"
}

variable "aws_profile" {
  default = "default"
}

variable "alarms_email" {
  default = "gustavombelfort@gmail.com"
}

