variable "region" {
  default = "us-east-2"
}

variable "my_ip" {
  default = "177.170.240.204/32"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "ami_id" {
  default = "ami-00eb69d236edcfaf8"
}

variable "key_name" {
  default = "dev-keypair"
}

variable "private_key_path" {
  default = "dev-keypair.pem"
}