variable "application" {
  default = "openethereum"
}

variable "provisionersrc" {
  default = "gustavobelfort/openethereum-aws"
}

variable "vpc_cidr_block" {
  description = "The VPC CIDR address range"
  default     = "172.31.0.0/16"
}

variable "slack_webhook_url" {
  default = "xxxxx-x"
}

variable "eth_count" {
  description = "The amount of OpenEthereum instances to create"
  default     = 1
}

//variable "vpc_id" {}

variable "instance_type" {
  default = "t2.micro"
}

variable "ssh_pubkey_path" {
  default = "$HOME/secrets/pub"
}

variable "ssh_privkey_path" {
  default = "$HOME/secrets/priv"
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

