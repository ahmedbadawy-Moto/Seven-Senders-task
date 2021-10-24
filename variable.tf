
variable "region" { default = "us-east-1" }

variable "cidr_block" { default = "10.0.0.0/16" }

variable "Availability_zone" {
  type    = list(any)
  default = ["us-east-1a", "us-east-1b"]
}
variable "shared_cred_file" { default = "/home/centos/.aws/credentials" }

variable "ami" {
  type = map(any)

  default = {
    "us-east-1" = "ami-0b0af3577fe5e3532"
    #Z    "us-west-1" = "ami-006fce2a9625b177f"
  }
}

variable "my_count" {
  default = "2"
}

variable "instance_tags" {
  type    = list(any)
  default = ["Webserver-1", "Webserver-2"]
}

variable "instance_type" {
  default = "t2.micro"
}

variable "public_cidrs" {
  type    = list(any)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "my_public_key" {
  default = "/home/centos/.ssh/id_rsa.pub"
}