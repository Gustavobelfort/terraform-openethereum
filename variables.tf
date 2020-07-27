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

variable "ssh_keypath" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDW8oQUXzzXbHwE24WnuOqiJAmSPHl/IGHpMaK1mdIyA8b7R1mGM8MAyTNO7oqmu6E9nygAFr6nZ+D1FO3eiX9uV2I3VnLOg9cdz+9TP90g3FqQQhLrpjxX3+zKLlWvMoS530EW0eIVcG7ZJ4BeuumaetVK+TZphcHx811QCsCAEmV7Fxatcant9ATWFSHC+pNybW/uemwxRNdR7nAG4R2/+jdqpTPnnCn0F9ENOml14N2y76LOO+BrVtrmtUFeYGH6u8NSN9wQJ55Q0Un/5oDf7CUvl+QxnEr5x5bfKi9goVYNbjow8QcBT4daEadBZ3pAyM33e8FYGa+IDFW23tpR gustavobelfort@byte"
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

